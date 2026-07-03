import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/model/referral_testimonial_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A 2-column grid of testimonial **videos**, mirroring the social/reels
/// "bites" grid: at any moment only the single most-visible tile plays (muted,
/// looping) as a preview, driven by a screen-scoped [_GridVideoPlaybackManager]
/// that owns exactly one [VideoPlayerController]. Tapping a tile opens the
/// full-screen player (with sound).
class TestimonialVideoGrid extends StatefulWidget {
  final List<ReferralTestimonial> videos;
  const TestimonialVideoGrid({super.key, required this.videos});

  @override
  State<TestimonialVideoGrid> createState() => _TestimonialVideoGridState();
}

class _TestimonialVideoGridState extends State<TestimonialVideoGrid> {
  final _GridVideoPlaybackManager _playback = _GridVideoPlaybackManager();

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      itemCount: widget.videos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (_, i) => _buildTile(i),
    );
  }

  Widget _buildTile(int i) {
    final t = widget.videos[i];
    return _TestimonialVideoTile(
      key: ValueKey(t.id.isEmpty ? '$i' : t.id),
      item: t,
      order: i,
      playback: _playback,
      onTap: () => Get.to(() => _TestimonialShortsPlayer(videoUrl: t.video!)),
    );
  }
}

class _TestimonialVideoTile extends StatefulWidget {
  final ReferralTestimonial item;
  final int order;
  final _GridVideoPlaybackManager playback;
  final VoidCallback onTap;

  const _TestimonialVideoTile({
    super.key,
    required this.item,
    required this.order,
    required this.playback,
    required this.onTap,
  });

  @override
  State<_TestimonialVideoTile> createState() => _TestimonialVideoTileState();
}

class _TestimonialVideoTileState extends State<_TestimonialVideoTile> {
  String get _id => widget.item.id.isEmpty
      ? (widget.item.video ?? '${widget.order}')
      : widget.item.id;

  @override
  void dispose() {
    widget.playback.removeVideo(_id);
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    widget.playback.reportVisibility(
      _id,
      widget.item.video ?? '',
      info.visibleFraction,
      widget.order,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.item;
    return VisibilityDetector(
      key: ValueKey('tst_vis_$_id'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: AppColors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Poster (first image if any) else a dark gradient.
                if (t.poster != null)
                  CachedNetworkImage(
                    imageUrl: t.poster!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _videoBg(),
                    errorWidget: (_, __, ___) => _videoBg(),
                  )
                else
                  _videoBg(),

                // Live preview — only for the active tile, above the poster.
                AnimatedBuilder(
                  animation: widget.playback,
                  builder: (context, _) {
                    final c = widget.playback.controller;
                    final active = widget.playback.activeId == _id;
                    final ready = active &&
                        c != null &&
                        c.value.isInitialized &&
                        c.value.size.width > 0 &&
                        c.value.size.height > 0;
                    if (!ready) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: c.value.size.width,
                          height: c.value.size.height,
                          child: VideoPlayer(c),
                        ),
                      ),
                    );
                  },
                ),

                // Bottom scrim + title.
                if (t.title.trim().isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(SizeConfig.size8,
                          SizeConfig.size20, SizeConfig.size8, SizeConfig.size8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                      child: CustomText(
                        t.title,
                        color: AppColors.white,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoBg() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2F3A), Color(0xFF11151C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

/// Owns exactly one [VideoPlayerController]. Tiles report their visibility; the
/// most-visible tile (vertical focus first, then reading-order tie-break) plays
/// muted + looping. Mirrors the reels grid engine, minus the scroll hooks (this
/// grid is small and lives inside another scroll view, so it evaluates purely
/// on visibility with a short play-delay to coalesce rapid changes).
class _GridVideoPlaybackManager extends ChangeNotifier {
  VideoPlayerController? _controller;
  String? _activeId;

  VideoPlayerController? get controller => _controller;
  String? get activeId => _activeId;

  final Map<String, double> _visible = {};
  final Map<String, String> _urls = {};
  final Map<String, int> _order = {};

  bool _disposed = false;
  Timer? _playDelayTimer;
  String? _playToken;

  static const double _visibilityThreshold = 0.6;
  static const Duration _playDelay = Duration(milliseconds: 150);

  void reportVisibility(
      String id, String url, double fraction, int order) {
    if (_disposed || id.isEmpty) return;
    if (url.isEmpty) return;
    if (fraction >= _visibilityThreshold) {
      _visible[id] = fraction;
      _urls[id] = url;
      _order[id] = order;
    } else {
      _visible.remove(id);
      _urls.remove(id);
      _order.remove(id);
      if (_activeId == id) {
        _stop();
        return;
      }
    }
    _evaluate();
  }

  void _evaluate() {
    if (_disposed) return;
    if (_visible.isEmpty) {
      _stop();
      return;
    }
    String? bestId;
    int bestBucket = -1;
    int bestOrder = 1 << 30;
    _visible.forEach((id, fraction) {
      final bucket = (fraction * 100).round();
      final order = _order[id] ?? (1 << 30);
      final better =
          bucket > bestBucket || (bucket == bestBucket && order < bestOrder);
      if (better) {
        bestBucket = bucket;
        bestOrder = order;
        bestId = id;
      }
    });
    if (bestId == null) {
      _stop();
      return;
    }
    if (bestId == _activeId) return;

    final target = bestId!;
    _playDelayTimer?.cancel();
    _playDelayTimer = Timer(_playDelay, () {
      if (!_disposed) _play(target);
    });
  }

  Future<void> _play(String id) async {
    final url = _urls[id];
    if (url == null || url.isEmpty || _disposed) return;

    final token = id;
    _playToken = token;

    final old = _controller;
    _controller = null;
    _activeId = null;
    notifyListeners();

    if (old != null) {
      await old.pause();
      await old.dispose();
    }
    if (_playToken != token || _disposed) return;

    final next = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await next.initialize().timeout(const Duration(seconds: 10));
    } catch (_) {
      await next.dispose();
      return;
    }
    if (_playToken != token || _disposed) {
      await next.dispose();
      return;
    }
    await next.setLooping(true);
    await next.setVolume(0); // preview is always muted; sound is full-screen only
    _controller = next;
    _activeId = id;
    await next.play();
    notifyListeners();
  }

  Future<void> _stop() async {
    _playToken = null;
    _playDelayTimer?.cancel();
    final old = _controller;
    _controller = null;
    _activeId = null;
    notifyListeners();
    if (old != null) {
      await old.pause();
      await old.dispose();
    }
  }

  void removeVideo(String id) {
    _visible.remove(id);
    _urls.remove(id);
    _order.remove(id);
    if (_activeId == id) {
      _stop();
    } else {
      _evaluate();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _playToken = null;
    _playDelayTimer?.cancel();
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

/// Simple full-screen, shorts-style player: the video fills the screen
/// (BoxFit.cover), autoplays with sound, loops, and tapping toggles
/// play/pause. Opened when a testimonial video tile is tapped.
class _TestimonialShortsPlayer extends StatefulWidget {
  final String videoUrl;
  const _TestimonialShortsPlayer({required this.videoUrl});

  @override
  State<_TestimonialShortsPlayer> createState() =>
      _TestimonialShortsPlayerState();
}

class _TestimonialShortsPlayerState extends State<_TestimonialShortsPlayer> {
  VideoPlayerController? _c;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _c = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setLooping(true);
      c.play();
      setState(() => _ready = true);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    // Pause first so audio stops immediately on back — dispose alone can let
    // the last bit of sound linger on some platforms ("old sound").
    _c?.pause();
    _c?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video — tap to toggle play/pause.
          GestureDetector(
            onTap: _toggle,
            child: (_ready && c != null)
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),

          // Center play icon while paused.
          if (_ready && c != null)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: c,
              builder: (_, v, __) => v.isPlaying
                  ? const SizedBox.shrink()
                  : IgnorePointer(
                      child: Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 76),
                      ),
                    ),
            ),

          // Back button.
          Positioned(
            top: topInset + 8,
            left: SizeConfig.size8,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),

          // Bottom scrubbable progress bar + time labels.
          if (_ready && c != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    SizeConfig.size12, SizeConfig.size20, SizeConfig.size12,
                    bottomInset + SizeConfig.size12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      padding: EdgeInsets.zero,
                      colors: VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white.withValues(alpha: 0.4),
                        backgroundColor: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    SizedBox(height: SizeConfig.size8),
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: c,
                      builder: (_, v, __) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(_fmt(v.position),
                              fontSize: SizeConfig.small, color: Colors.white),
                          CustomText(_fmt(v.duration),
                              fontSize: SizeConfig.small,
                              color: Colors.white.withValues(alpha: 0.8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
