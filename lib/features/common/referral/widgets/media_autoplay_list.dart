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

/// A YouTube-style vertical feed of media posts. Video posts render as a
/// full-width **16:9** tile that autoplays (muted, looping) when it's the
/// most-visible one and opens full-screen on tap; image posts show a 16:9
/// image; both get the title + description below, inside a white card.
class MediaAutoplayList extends StatefulWidget {
  final List<ReferralTestimonial> items;
  const MediaAutoplayList({super.key, required this.items});

  @override
  State<MediaAutoplayList> createState() => _MediaAutoplayListState();
}

class _MediaAutoplayListState extends State<MediaAutoplayList> {
  final _GridVideoPlaybackManager _playback = _GridVideoPlaybackManager();

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => SizedBox(height: SizeConfig.paddingXSL),
      itemBuilder: (_, i) => _card(widget.items[i], i),
    );
  }

  Widget _card(ReferralTestimonial t, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF1F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.hasVideo)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _YtVideoTile(
                item: t,
                order: index,
                playback: _playback,
                onTap: () => Get.to(() => MediaShortsPlayer(videoUrl: t.video!)),
              ),
            )
          else if (t.hasImages)
            GestureDetector(
              onTap: () => _openImage(context, t.images.first),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: t.images.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => ColoredBox(color: AppColors.whiteE5),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: AppColors.whiteE5,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: AppColors.secondaryTextColor),
                  ),
                ),
              ),
            ),
          if (t.title.trim().isNotEmpty || t.description.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (t.title.trim().isNotEmpty)
                    CustomText(
                      t.title,
                      fontSize: SizeConfig.medium15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (t.description.trim().isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      t.description,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      height: 1.4,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    ));
  }
}

/// A single 16:9 video tile: poster (first image if any) behind the live
/// preview that shows only when this is the most-visible tile.
class _YtVideoTile extends StatefulWidget {
  final ReferralTestimonial item;
  final int order;
  final _GridVideoPlaybackManager playback;
  final VoidCallback onTap;

  const _YtVideoTile({
    required this.item,
    required this.order,
    required this.playback,
    required this.onTap,
  });

  @override
  State<_YtVideoTile> createState() => _YtVideoTileState();
}

class _YtVideoTileState extends State<_YtVideoTile> {
  String get _id =>
      widget.item.id.isEmpty ? (widget.item.video ?? '${widget.order}') : widget.item.id;

  @override
  void dispose() {
    widget.playback.removeVideo(_id);
    super.dispose();
  }

  void _onVisibility(VisibilityInfo info) {
    if (!mounted) return;
    widget.playback.reportVisibility(
        _id, widget.item.video ?? '', info.visibleFraction, widget.order);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.item;
    return VisibilityDetector(
      key: ValueKey('yt_vis_$_id'),
      onVisibilityChanged: _onVisibility,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ColoredBox(
          color: AppColors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (t.poster != null)
                CachedNetworkImage(
                  imageUrl: t.poster!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _videoBg(),
                  errorWidget: (_, __, ___) => _videoBg(),
                )
              else
                _videoBg(),
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
            ],
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

/// Simple full-screen player: fills the screen (BoxFit.cover), autoplays with
/// sound, loops, tap toggles play/pause; scrubbable progress bar + time labels.
class MediaShortsPlayer extends StatefulWidget {
  final String videoUrl;
  const MediaShortsPlayer({super.key, required this.videoUrl});

  @override
  State<MediaShortsPlayer> createState() => _MediaShortsPlayerState();
}

class _MediaShortsPlayerState extends State<MediaShortsPlayer> {
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
                    child: CircularProgressIndicator(color: Colors.white)),
          ),
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
          if (_ready && c != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(SizeConfig.size12,
                    SizeConfig.size20, SizeConfig.size12, bottomInset + SizeConfig.size12),
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

/// Owns exactly one [VideoPlayerController]; the most-visible tile plays muted
/// + looping. Same engine used by the testimonial grid.
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

  void reportVisibility(String id, String url, double fraction, int order) {
    if (_disposed || id.isEmpty || url.isEmpty) return;
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
    await next.setVolume(0);
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
