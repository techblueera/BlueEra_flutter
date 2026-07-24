import 'dart:async';
import 'dart:io';

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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
  final _ReelPrefetcher _prefetcher = _ReelPrefetcher();
  late final _ReelGridPlaybackManager _playback =
      _ReelGridPlaybackManager(prefetcher: _prefetcher);

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ShortsController>()
        ? Get.find<ShortsController>()
        : Get.put(ShortsController());
    _prefetcher.init();
    // When the grid settles on a preview, warm the next reels (N+1..N+2 in
    // reading order) so tapping in / scrolling on starts instantly. See
    // docs/backend/PREFETCH_INTEGRATION.md.
    _playback.onActivated = (order) => _prefetcher.prefetchAround(
          _controller.trendingVideoFeedPosts,
          order,
        );
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
    _prefetcher.dispose();
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
      widget.item,
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
  _ReelGridPlaybackManager({_ReelPrefetcher? prefetcher})
      : _prefetcher = prefetcher;

  /// Shared prefetcher — used to prefer prefetched URLs and to play already
  /// cached MP4s straight from disk (instant / offline).
  final _ReelPrefetcher? _prefetcher;

  /// Fired with the reading-order index of a tile the moment it starts playing,
  /// so the screen can warm the reels just after it.
  void Function(int order)? onActivated;

  VideoPlayerController? _controller;
  String? _activeId;

  VideoPlayerController? get controller => _controller;
  String? get activeId => _activeId;

  /// videoId -> visible fraction (only tiles at/above [_visibilityThreshold]).
  final Map<String, double> _visible = {};

  /// videoId -> video url, for whatever is currently visible.
  final Map<String, String> _urls = {};

  /// videoId -> prefetch hint, for whatever is currently visible (nullable per
  /// item — old items or still-transcoding uploads carry none).
  final Map<String, Prefetch?> _prefetch = {};

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
      String videoId, ShortFeedItem item, double fraction, int order) {
    if (_disposed || videoId.isEmpty) return;
    if (fraction >= _visibilityThreshold) {
      // Prefer the prefetch's playback URL (HLS master / low ladder), falling
      // back to the legacy videoUrl when the item carries no prefetch block.
      final url = item.prefetch?.playbackUrl() ?? item.video?.videoUrl ?? '';
      _visible[videoId] = fraction;
      _urls[videoId] = url;
      _prefetch[videoId] = item.prefetch;
      _order[videoId] = order;
    } else {
      _visible.remove(videoId);
      _urls.remove(videoId);
      _prefetch.remove(videoId);
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

    // If this is a progressive MP4 we already prefetched, play the on-disk copy
    // — instant start, and it keeps playing if the network drops. HLS keeps
    // streaming from the network (the player caches segments itself).
    final prefetch = _prefetch[videoId];
    final isHls = prefetch?.isHls ?? url.contains('.m3u8');
    File? localFile;
    final prefetcher = _prefetcher;
    if (!isHls && prefetcher != null) {
      localFile = await prefetcher.cachedFile(url);
      if (_playToken != token || _disposed) return;
    }

    final next = localFile != null
        ? VideoPlayerController.file(
            localFile,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
        : VideoPlayerController.networkUrl(
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

    // Now that this tile is live, warm the reels just after it.
    final order = _order[videoId];
    if (order != null) onActivated?.call(order);
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
    _prefetch.remove(videoId);
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

/// Warms upcoming reels into the on-disk cache so playback starts instantly and
/// keeps working when the network drops — the strategy from
/// docs/backend/PREFETCH_INTEGRATION.md, adapted to the discovery grid's
/// reading order.
///
/// * Progressive **MP4** items are downloaded to the cache dir; the playback
///   manager then plays them straight from that file (offline-capable).
/// * **HLS** items are left to the player to stream/cache segment-by-segment —
///   pre-downloading a whole master playlist would be wrong — but we still warm
///   the poster so the first frame paints immediately.
/// * On **cellular / data-saver** we prefetch only 1 ahead and prefer the low
///   ladder; on Wi‑Fi we prefetch 2 ahead.
class _ReelPrefetcher {
  final BaseCacheManager _cache = DefaultCacheManager();

  /// videoIds we've already kicked a prefetch off for, so a second pass over
  /// the same window doesn't re-download.
  final Set<String> _requested = {};

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _cellular = false;
  bool _disposed = false;

  void init() {
    // Seed the current network state, then track changes so the ahead-count and
    // variant choice follow the user onto / off Wi‑Fi mid-session.
    Connectivity().checkConnectivity().then(_applyConnectivity).catchError(
          (_) {},
        );
    _connSub =
        Connectivity().onConnectivityChanged.listen(_applyConnectivity);
  }

  void _applyConnectivity(List<ConnectivityResult> result) {
    if (_disposed) return;
    // Treat "on mobile data with no Wi‑Fi/ethernet" as cellular; anything else
    // (Wi‑Fi, ethernet, unknown) gets the generous Wi‑Fi budget.
    _cellular = result.contains(ConnectivityResult.mobile) &&
        !result.contains(ConnectivityResult.wifi) &&
        !result.contains(ConnectivityResult.ethernet);
  }

  /// Prefetch the reels just after [fromIndex] in reading order.
  void prefetchAround(List<ShortFeedItem> items, int fromIndex) {
    if (_disposed) return;
    final ahead = _cellular ? 1 : 2;
    for (var i = fromIndex + 1;
        i <= fromIndex + ahead && i < items.length;
        i++) {
      _prefetchItem(items[i]);
    }
  }

  void _prefetchItem(ShortFeedItem item) {
    final id = item.videoId ?? '';
    if (id.isEmpty || _requested.contains(id)) return;
    _requested.add(id);

    final p = item.prefetch;

    // Warm the poster (or cover) so the first frame is instant.
    final poster = p?.poster ?? item.video?.coverUrl;
    if (poster != null && poster.isNotEmpty && isNetworkImage(poster)) {
      unawaited(_safeDownload(poster));
    }

    // Cheapest playable URL; fall back to the legacy videoUrl for items the
    // backend hasn't attached a prefetch block to yet.
    final url = p?.prefetchUrl(dataSaver: _cellular) ?? item.video?.videoUrl;
    if (url == null || url.isEmpty) return;

    // Only pre-download progressive MP4s. HLS master playlists are adaptive and
    // tiny — the player streams and caches their segments on demand; grabbing
    // the whole file here would defeat that.
    final isHls = p?.isHls ?? url.contains('.m3u8');
    if (isHls) return;

    unawaited(_safeDownload(url));
  }

  Future<void> _safeDownload(String url) async {
    try {
      final existing = await _cache.getFileFromCache(url);
      if (existing != null) return; // already on disk
      await _cache.downloadFile(url);
    } catch (_) {
      // Best-effort: a failed prefetch just means we play from the network.
    }
  }

  /// Return a cached on-disk copy of [url] (progressive MP4 only) if we already
  /// prefetched it, else null → the caller streams from the network.
  Future<File?> cachedFile(String url) async {
    if (_disposed) return null;
    try {
      final info = await _cache.getFileFromCache(url);
      if (info == null) return null;
      return File(info.file.path);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _disposed = true;
    _connSub?.cancel();
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
