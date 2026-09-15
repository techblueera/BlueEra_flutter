import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The Discover intro clip, drawn as a banner slide.
///
/// Sized by the carousel, not by itself: it fills whatever box the banner hands
/// it (see [DiscoverProfileBanner._aspect]) so the header measures the same
/// whether the clip is present or not, and nothing shifts when it arrives.
///
/// ## The two signals, and why they are separate
///
/// [hasFocus] — is this the slide currently showing in the carousel? It
/// controls SOUND ONLY. Scrolling the banner left or right silences the clip
/// and leaves everything else running, so swiping away and back returns the
/// viewer to the clip mid-flight rather than to a fresh download. Tearing the
/// player down on a horizontal swipe is exactly what made the video appear to
/// vanish: the carousel disposes off-screen slides, so the swipe back landed
/// on the fallback artwork while a new controller buffered from zero.
/// [AutomaticKeepAliveClientMixin] is what stops that.
///
/// [alive] — is the banner in front of the user at all? It controls the
/// PLAYER'S EXISTENCE. False disposes the controller outright and false→true
/// builds a new one. The banner raises it for page scroll, a route pushed on
/// top, and the app going to background, none of which unmount this widget —
/// so without it the clip keeps decoding, and keeps talking once unmuted,
/// behind whatever the user moved on to.
///
/// **Starts muted** whenever it is (re)created. The banner is the first thing
/// on Discover and it plays without being asked to, so sound would otherwise
/// reach whoever is in earshot of a stranger opening the app. A tap unmutes;
/// that is the viewer opting in, and the choice is remembered across focus
/// changes but not across a teardown.
///
/// Collapses to [fallback] if the clip fails to load, so a bad URL costs the
/// slot's existing artwork rather than a black box.
class DiscoverVideoSlide extends StatefulWidget {
  final String url;

  /// Drawn instead of the player when the clip cannot load, and underneath it
  /// while it buffers — so the slot never flashes empty.
  final Widget fallback;

  /// Whether the player should exist. See the class doc.
  final bool alive;

  /// Whether this is the slide on screen. Governs sound only.
  final bool hasFocus;

  /// Fired once per player when the clip reaches its end, and on a load
  /// failure (there is nothing left to wait for in that case either).
  final VoidCallback? onFinished;

  const DiscoverVideoSlide({
    super.key,
    required this.url,
    required this.fallback,
    this.alive = true,
    this.hasFocus = true,
    this.onFinished,
  });

  @override
  State<DiscoverVideoSlide> createState() => _DiscoverVideoSlideState();
}

class _DiscoverVideoSlideState extends State<DiscoverVideoSlide>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  /// The viewer's own sound choice, NOT the current volume — the clip is
  /// silenced whenever it loses focus regardless, and this is what decides
  /// whether it comes back with sound when focus returns.
  bool _soundOn = false;

  /// [DiscoverVideoSlide.onFinished] fires once per player. The position
  /// listener reports the end on several consecutive frames, and letting each
  /// through would release the carousel's hold repeatedly.
  bool _finishedReported = false;

  /// Guards against two [_create] calls overlapping — `alive` can flip back and
  /// forth faster than `initialize()` completes (a route pushed and popped
  /// quickly), which would otherwise leak the first controller.
  int _generation = 0;

  /// Holds the player through a horizontal carousel swipe. Not wanted once the
  /// clip has failed, or while it is deliberately torn down.
  @override
  bool get wantKeepAlive => widget.alive && !_failed;

  @override
  void initState() {
    super.initState();
    if (widget.alive) _create();
  }

  @override
  void didUpdateWidget(DiscoverVideoSlide oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A different clip is a different player, whatever else changed.
    if (oldWidget.url != widget.url) {
      _destroy();
      _failed = false;
      _finishedReported = false;
      _soundOn = false;
      if (widget.alive) _create();
      return;
    }

    if (oldWidget.alive != widget.alive) {
      if (widget.alive) {
        _create();
      } else {
        // Left the screen: release the decoder and the socket rather than
        // pausing. A paused player still holds both.
        setState(_destroy);
      }
      return;
    }

    if (oldWidget.hasFocus != widget.hasFocus) _applyVolume();
  }

  Future<void> _create() async {
    if (_controller != null) return;
    final generation = ++_generation;

    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      // Torn down (or replaced) while initialize() was in flight — release this
      // controller here, because the teardown that raced it saw `_controller`
      // before this assignment took effect, or the widget is already gone and
      // `dispose` will not run again.
      if (!mounted || generation != _generation) {
        await controller.dispose();
        if (identical(_controller, controller)) _controller = null;
        return;
      }
      await controller.setLooping(false);
      await controller.setVolume(0); // silent until focus + opt-in say otherwise
      controller.addListener(_onValueChanged);
      if (!mounted) return;
      setState(() => _ready = true);
      await _applyVolume();
      await controller.play();
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _failed = true);
      _reportFinished();
    }
  }

  /// Sound plays only when this slide is the one showing AND the viewer asked
  /// for it. Any other combination is silent.
  Future<void> _applyVolume() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    await c.setVolume(widget.hasFocus && _soundOn ? 1 : 0);
  }

  void _destroy() {
    _generation++;
    _controller?.removeListener(_onValueChanged);
    _controller?.dispose();
    _controller = null;
    _ready = false;
    _finishedReported = false;
    // The opt-in does not survive a teardown: a clip that comes back after the
    // app was backgrounded starts silent again, like a fresh one.
    _soundOn = false;
  }

  bool get _isEnded {
    final v = _controller?.value;
    if (v == null || !v.isInitialized) return false;
    return v.duration > Duration.zero && v.position >= v.duration;
  }

  void _onValueChanged() {
    if (!mounted) return;
    if (_isEnded) _reportFinished();
    setState(() {});
  }

  void _reportFinished() {
    if (_finishedReported) return;
    _finishedReported = true;
    widget.onFinished?.call();
  }

  /// Tapping the clip toggles the viewer's sound opt-in.
  ///
  /// Replays from the top when the clip has already run out: toggling sound on
  /// a finished video would otherwise do nothing visible and leave the slide
  /// parked on a frozen last frame, which reads as broken. The carousel is not
  /// re-held for the replay — the banner's watched flag stays set — so nobody
  /// gets trapped on this slide.
  Future<void> _toggleSound() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() => _soundOn = !_soundOn);
    await _applyVolume();
    if (_isEnded) {
      await c.seekTo(Duration.zero);
      await c.play();
    }
  }

  @override
  void dispose() {
    _destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Required by AutomaticKeepAliveClientMixin.
    super.build(context);

    // Failed, or deliberately torn down: the slot shows the artwork the clip
    // replaced, so it is never blank, black or frozen.
    if (_failed || !widget.alive) return widget.fallback;

    final c = _controller;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleSound,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Underneath the player, so the slot shows the bundled artwork while
          // the clip buffers instead of a black rectangle.
          widget.fallback,
          if (_ready && c != null)
            // `cover`, matching the image slides either side of it: the banner
            // is a full-bleed strip, and `contain` would letterbox the clip
            // against black and make this one slide read as a different shape.
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          if (_ready && c != null)
            Positioned(bottom: 8, right: 8, child: _soundBadge()),
        ],
      ),
    );
  }

  /// Dark glass, like the banner's share button — this sits on a full-bleed
  /// video of unknown brightness, where a light chip can vanish entirely.
  ///
  /// Bottom-RIGHT: the share button owns the top-right corner and the page dots
  /// run along the bottom centre.
  Widget _soundBadge() {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.42),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Icon(
        _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: Colors.white,
        size: 15,
      ),
    );
  }
}
