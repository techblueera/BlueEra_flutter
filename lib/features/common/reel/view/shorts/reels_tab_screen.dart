import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Reels **discovery grid** shown in the "Reels" tab — a YouTube-Shorts-style
/// 2-column grid of reel covers with the caption overlaid at the bottom of each
/// tile.
///
/// **Auto-play (YouTube behaviour):** at any moment only the single most-visible
/// tile plays (muted, looping) as a preview. A dedicated, screen-scoped
/// [_ReelGridPlaybackManager] owns one [VideoPlayerController] and:
///   * stays idle while the user is actively scrolling,
///   * waits a short settle window after scrolling stops, then plays the tile
///     that ended up most-visible (so a fast flick never spins up videos for
///     everything it flew past). "Most-visible" is resolved the way a YouTube /
///     Toro-style grid does it: **vertical focus first** (the row crossing the
///     viewport's focal band has the largest visible area), then a **reading-
///     order tie-break** (top-to-bottom, then left-to-right) so two equally-
///     visible tiles in the same row resolve to the LEFT one instead of the
///     pick flickering between columns,
///   * always disposes the old controller *before* creating the new one, with a
///     token guard so a stale init that finishes late never overwrites a newer
///     selection.
///
/// Tapping any tile pushes the existing full-screen vertical [ShortsPlayerScreen]
/// at that index. Both screens read the same
/// [ShortsController.trendingVideoFeedPosts] list, so pagination is shared.
class ReelsTabScreen extends StatefulWidget {
  const ReelsTabScreen({super.key});

  @override
  State<ReelsTabScreen> createState() => _ReelsTabScreenState();
}

class _ReelsTabScreenState extends State<ReelsTabScreen> {
  late final ShortsController _controller;
  final ScrollController _scrollController = ScrollController();
  final _ReelGridPlaybackManager _playback = _ReelGridPlaybackManager();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ShortsController>()
        ? Get.find<ShortsController>()
        : Get.put(ShortsController());
    _scrollController.addListener(_onScroll);
    // Defer the first fetch past the first frame so the cache-first path
    // (which reassigns observable lists synchronously) never notifies an
    // Obx mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.trendingVideoFeedPosts.isEmpty) {
        _controller.getAllFeedTrending(isInitialLoad: true, refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _playback.dispose();
    super.dispose();
  }

  /// Pre-fetch the next page well before the user hits the bottom so the grid
  /// keeps filling without a visible stall. The controller's own guards
  /// (`hasMore` / `isLoadingMore`) make repeated calls cheap no-ops.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      _controller.getAllFeedTrending();
    }
  }

  /// Drive the playback manager from the scroll lifecycle so it can hold off
  /// while the list is moving and only commit to a video once it settles.
  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollStartNotification) {
      _playback.onScrollStart();
    } else if (n is ScrollEndNotification) {
      _playback.onScrollEnd();
    } else if (n is UserScrollNotification &&
        n.direction == ScrollDirection.idle) {
      _playback.onScrollEnd();
    }
    // Bubble up so the parent screen's collapsing-header listener still works.
    return false;
  }

  Future<void> _refresh() =>
      _controller.getAllFeedTrending(isInitialLoad: true, refresh: true);

  /// Open the full-screen vertical player at [index], handing it the live
  /// list so the user can keep scrolling reels from there.
  void _openPlayer(int index) {
    Navigator.pushNamed(
      context,
      RouteHelper.getShortsPlayerScreenRoute(),
      arguments: {
        ApiKeys.shorts: Shorts.trending,
        ApiKeys.videoItem: _controller.trendingVideoFeedPosts.toList(),
        ApiKeys.initialIndex: index,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Transparent so the app-wide [AppHomeBackground] (banner / colour chosen
    // in App Background settings) shows through, matching the Social/Community
    // tabs instead of a hardcoded black fill.
    return Obx(() {
      final list = _controller.trendingVideoFeedPosts;

      if (list.isEmpty) {
        if (_controller.isFirstLoadTrending.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        return _ReelsEmptyState(onRetry: _refresh);
      }

      final loadingMore = _controller.trendingVideoFeedIsLoadingMore.value;

      return RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryColor,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(SizeConfig.size4),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    // YouTube-Shorts-style 2-up grid of portrait covers.
                    crossAxisCount: 2,
                    // Higher ratio = shorter cards (cover fills the cell, title
                    // overlays the bottom, so nothing clips).
                    childAspectRatio: 0.72,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ReelGridTile(
                      key: ValueKey(list[index].videoId ?? index),
                      item: list[index],
                      // Grid index = reading order. With crossAxisCount 2,
                      // column = index % 2 (0 = left, 1 = right) and a lower
                      // index always means "earlier in reading order", which is
                      // exactly the tie-break the manager uses.
                      order: index,
                      playback: _playback,
                      onTap: () => _openPlayer(index),
                    ),
                    childCount: list.length,
                  ),
                ),
              ),
              if (loadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// One reel cover in the grid: thumbnail (or the live preview video when this
/// tile is the active one) + a bottom scrim with the caption and view count.
class _ReelGridTile extends StatefulWidget {
  final ShortFeedItem item;

  /// Position in the grid (= reading order). Used by the manager to break
  /// visibility ties between tiles in the same row (lower wins → left first).
  final int order;
  final _ReelGridPlaybackManager playback;
  final VoidCallback onTap;

  const _ReelGridTile({
    super.key,
    required this.item,
    required this.order,
    required this.playback,
    required this.onTap,
  });

  @override
  State<_ReelGridTile> createState() => _ReelGridTileState();
}

class _ReelGridTileState extends State<_ReelGridTile> {
  String get _videoId => widget.item.videoId ?? '';

  /// Prefer the caption, fall back to the title — the trending feed fills one
  /// or the other depending on the source.
  String get _caption {
    final caption = widget.item.video?.caption ?? '';
    if (caption.trim().isNotEmpty) return caption;
    return widget.item.video?.title ?? '';
  }

  @override
  void dispose() {
    // Make sure a tile that scrolls off (or is rebuilt) releases its claim so
    // the manager never tries to play a video whose tile is gone.
    widget.playback.removeVideo(_videoId);
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    widget.playback.reportVisibility(
      _videoId,
      widget.item.video?.videoUrl ?? '',
      info.visibleFraction,
      widget.order,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.item.video?.coverUrl ?? '';
    final views = widget.item.video?.stats?.views ?? 0;
    final caption = _caption;

    return VisibilityDetector(
      key: ValueKey('reel_vis_$_videoId'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: AppColors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // --- Cover thumbnail (always present as the background).
                if (cover.isNotEmpty && isNetworkImage(cover))
                  CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: AppColors.black30),
                    errorWidget: (_, __, ___) => LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  )
                else
                  LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),

                // --- Live preview video, shown only while this is the active
                // tile and its controller is initialised. Sits above the
                // thumbnail so there's no flash when it appears/disappears.
                AnimatedBuilder(
                  animation: widget.playback,
                  builder: (context, _) {
                    final controller = widget.playback.controller;
                    final isActive = widget.playback.activeId == _videoId;
                    final ready = isActive &&
                        controller != null &&
                        controller.value.isInitialized &&
                        controller.value.size.width > 0 &&
                        controller.value.size.height > 0;
                    if (!ready) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    );
                  },
                ),

                // --- Bottom scrim for caption / view-count legibility.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size8,
                      SizeConfig.size20,
                      SizeConfig.size8,
                      SizeConfig.size8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (caption.trim().isNotEmpty) ...[
                          CustomText(
                            caption,
                            color: AppColors.white,
                            fontSize: SizeConfig.size13,
                            fontWeight: FontWeight.w600,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: SizeConfig.size4),
                        ],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.white,
                              size: 18,
                            ),
                            SizedBox(width: SizeConfig.size2),
                            CustomText(
                              formatNumberLikePost(views),
                              color: AppColors.white,
                              fontSize: SizeConfig.size12,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ],
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
}

/// Screen-scoped single-video playback engine for the reels grid.
///
/// Owns exactly one [VideoPlayerController]. Tiles report their on-screen
/// visibility; the manager picks the most-visible tile and plays it muted +
/// looping once the list has settled. Lifecycle (init/dispose) is tied to the
/// owning [State], so leaving the tab tears the controller down.
class _ReelGridPlaybackManager extends ChangeNotifier {
  VideoPlayerController? _controller;
  String? _activeId;

  VideoPlayerController? get controller => _controller;
  String? get activeId => _activeId;

  /// videoId -> visible fraction (only tiles at/above [_visibilityThreshold]).
  final Map<String, double> _visible = {};

  /// videoId -> video url, for whatever is currently visible.
  final Map<String, String> _urls = {};

  /// videoId -> grid index (reading order), the horizontal/row tie-breaker.
  final Map<String, int> _order = {};

  bool _isScrolling = false;
  bool _disposed = false;

  Timer? _settleTimer;
  Timer? _playDelayTimer;

  /// Token = videoId of the most recent [_play] call. After every await we
  /// re-check it; if it changed, a newer selection won → abort the stale init.
  String? _playToken;

  /// A tile must be at least this visible to be eligible to play.
  static const double _visibilityThreshold = 0.6;

  /// How long the list must be still after a scroll ends before we evaluate.
  /// Short enough that the focused reel starts almost immediately on stop, but
  /// long enough to swallow the tiny scroll jitter at the tail of a fling so we
  /// don't evaluate mid-settle.
  static const Duration _settleDelay = Duration(milliseconds: 90);

  /// Extra grace after settling before the chosen video actually spins up. This
  /// is the real guard against init/dispose churn (and the main-thread cost of
  /// ExoPlayer init that can lead to jank/ANR): a brief pause between flicks
  /// won't kick off a doomed init that the next flick immediately tears down.
  static const Duration _playDelay = Duration(milliseconds: 140);

  void reportVisibility(
      String videoId, String videoUrl, double fraction, int order) {
    if (_disposed || videoId.isEmpty) return;
    if (fraction >= _visibilityThreshold) {
      _visible[videoId] = fraction;
      _urls[videoId] = videoUrl;
      _order[videoId] = order;
    } else {
      _visible.remove(videoId);
      _urls.remove(videoId);
      _order.remove(videoId);
      // The active video scrolled out of focus — stop it immediately.
      if (_activeId == videoId) {
        _stop();
        return;
      }
    }
    if (!_isScrolling) _evaluate();
  }

  void onScrollStart() {
    _isScrolling = true;
    _settleTimer?.cancel();
    _playDelayTimer?.cancel();
  }

  void onScrollEnd() {
    // Debounce: a fresh scroll before this fires cancels it, so only a genuine
    // stop schedules an evaluation.
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleDelay, () {
      _isScrolling = false;
      _evaluate();
    });
  }

  /// Pick the focused tile the way a YouTube / Toro-style grid does:
  ///   1. **Vertical focus first** — rank by how much of the tile is on screen.
  ///      The row crossing the viewport's focal band has the largest visible
  ///      area, so this naturally selects the right *row* as the user scrolls.
  ///   2. **Reading-order tie-break** — fractions are quantised to 1% buckets,
  ///      so the two columns of a row (which are vertically identical and differ
  ///      only by sub-pixel rounding) land in the same bucket; the lower grid
  ///      index then wins, i.e. **left before right** (and, across fully-visible
  ///      rows, top before bottom). This stops the pick from flickering between
  ///      columns and matches the left-first behaviour of the YouTube grid.
  void _evaluate() {
    if (_disposed || _isScrolling) return;
    if (_visible.isEmpty) {
      _stop();
      return;
    }

    String? bestId;
    int bestBucket = -1; // quantised visible fraction (vertical focus)
    int bestOrder = 1 << 30; // reading order (lower = earlier = left/top)
    _visible.forEach((id, fraction) {
      final bucket = (fraction * 100).round();
      final order = _order[id] ?? (1 << 30);
      final isBetter =
          bucket > bestBucket || (bucket == bestBucket && order < bestOrder);
      if (isBetter) {
        bestBucket = bucket;
        bestOrder = order;
        bestId = id;
      }
    });

    if (bestId == null) {
      _stop();
      return;
    }
    // Already playing the right one — nothing to do.
    if (bestId == _activeId) return;

    final target = bestId!;
    _playDelayTimer?.cancel();
    _playDelayTimer = Timer(_playDelay, () {
      if (!_isScrolling && !_disposed) _play(target);
    });
  }

  Future<void> _play(String videoId) async {
    final url = _urls[videoId];
    if (url == null || url.isEmpty || _disposed) return;

    final token = videoId;
    _playToken = token;

    // Grab and clear the shared controller first so a concurrent call can't
    // dispose the same instance twice.
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

    // A newer selection came in while we were initialising — drop this one.
    if (_playToken != token || _disposed) {
      await next.dispose();
      return;
    }

    await next.setLooping(true);
    await next.setVolume(0); // muted preview, like the YouTube Shorts grid
    _controller = next;
    _activeId = videoId;
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

  /// A tile is leaving the tree — drop its visibility claim and stop it if it
  /// happened to be the one playing.
  void removeVideo(String videoId) {
    _visible.remove(videoId);
    _urls.remove(videoId);
    _order.remove(videoId);
    if (_activeId == videoId) {
      _stop();
    } else if (!_isScrolling) {
      _evaluate();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _playToken = null;
    _settleTimer?.cancel();
    _playDelayTimer?.cancel();
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

class _ReelsEmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ReelsEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.video_collection_outlined,
              color: AppColors.secondaryTextColor, size: 56),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            'No reels to show right now',
            color: AppColors.mainTextColor,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: SizeConfig.size12),
          TextButton(
            onPressed: onRetry,
            child: CustomText(
              'Retry',
              color: AppColors.primaryColor,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
