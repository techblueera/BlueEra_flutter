import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/services/screen_service.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/view/shorts/short_player_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class ShortsPlayerScreen extends StatefulWidget {
  final Shorts shorts;
  final List<ShortFeedItem> initialShorts;
  final int initialIndex;

  const ShortsPlayerScreen({
    super.key,
    required this.shorts,
    required this.initialShorts,
    required this.initialIndex,
  });

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen>
    with WidgetsBindingObserver {
  late ShortsController? shortsFeedController;

  late final PageController _pageController;
  int currentIndex = 0;

  // Single owner of all video controllers. We keep only the current page ± 1
  // alive (a 3-entry sliding window) so memory stays flat while the neighbours
  // are preloaded for instant, stutter-free swipes.
  final _videoCache = <int, _VideoCacheEntry>{};

  /// Video ids whose HLS master stream errored (e.g. an HEVC/H.265 variant the
  /// device's decoder can't handle) and were transparently rebuilt on the
  /// progressive mp4. Sticky for the session so a recovered page never flips
  /// back to the broken master and loops.
  final Set<String> _mp4FallbackIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ShortsController>()) {
      shortsFeedController = Get.find<ShortsController>();
    } else {
      shortsFeedController = Get.put(ShortsController());
    }
    print('🚀 INIT: ShortsPlayerScreen initializing...');
    WidgetsBinding.instance.addObserver(this);
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    print('📍 INIT: Starting at index $currentIndex');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeedData();

      // When the feed is seeded with only the tapped video (home-feed short/long
      // tap), the PageView has a single page so _onPageChanged never fires and
      // pagination would never start. Kick off the first page here whenever the
      // current index is already within the load-more threshold of the end.
      final seeded = _getCurrentFeedList(shortsFeedController!);
      if (currentIndex >= (seeded?.length ?? 0) - 3) {
        _onScrollToEnd(shortsFeedController!);
      }

      _warmUpRange(currentIndex);
      // Hand the freshly-created controller to the first page and start it
      // (the page was built before this callback ran, so it currently has no
      // controller — this setState delivers it).
      _playWhenReady(currentIndex);
      if (mounted) setState(() {});
      print('✅ INIT: Initialization complete');
    });

  }

  @override
  void dispose() {
    print('🔴 DISPOSE: Starting disposal process...');
    WidgetsBinding.instance.removeObserver(this);
    _releaseWakeLock();

    /* 1. Pause every cached controller first */
    print('🔇 DISPOSE: Pausing all cached controllers...');
    _videoCache.forEach((i, e) {
      if (e.controller != null) {
        final wasPlaying = e.controller!.value.isPlaying;
        e.controller?.pause();
        print('   - Cache[$i]: Was playing: $wasPlaying, Now paused: ${!e.controller!.value.isPlaying}');
      }
    });

    /* 2. Dispose all controllers */
    print('🗑️ DISPOSE: Disposing all cached controllers...');
    _videoCache.values.forEach((e) {
      if (e.controller != null) {
        print('   - Disposing controller: ${e.controller.hashCode}');
        e.controller?.dispose();
        e.controller = null;
      }
    });
    _videoCache.clear();
    print('✅ DISPOSE: All controllers disposed and cache cleared');

    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('📱 LIFECYCLE: App state changed to $state');
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final controller = _videoCache[currentIndex]?.controller;
      if (controller != null) {
        final wasPlaying = controller.value.isPlaying;
        controller.pause();
        _releaseWakeLock();
        print('🔇 LIFECYCLE: Paused video at index $currentIndex (was playing: $wasPlaying)');
      }
    }
    // else if (state == AppLifecycleState.resumed) {
      // if (!_isAdShowing) {
      //   final controller = _videoCache[currentIndex]?.controller;
      //   if (controller != null) {
      //     controller.play();
      //     _acquireWakeLock();
      //     print('▶️ LIFECYCLE: Resumed video at index $currentIndex');
      //   }
      // }
     // }
  }

  Future<void> _acquireWakeLock() async {
    if (!mounted) return;
    await ScreenService.keepOn();
    print('🔒 WAKE-LOCK acquired');
  }

  Future<void> _releaseWakeLock() async {
    if (!mounted) return;
    await ScreenService.keepOff();
    print('🔓 WAKE-LOCK released');
  }

  //
  // void _copyStateToNeighbour(int from, int to) {
  //   final list = _getCurrentFeedList(shortsFeedController);
  //   if (list == null) return;
  //   final fromItem = list.elementAtOrNull(from);
  //   final toItem = list.elementAtOrNull(to);
  //   if (fromItem == null || toItem == null) return;
  //   toItem.video?.stats?.likes = fromItem.video?.stats?.likes;
  //   toItem.video?.stats?.comments = fromItem.video?.stats?.comments;
  //   toItem.interactions?.isLiked = fromItem.interactions?.isLiked;
  // }
  /* ------------------------------------------------------ */

  /* --------------  NEW : OOM-safe cache  -------------- */
  void _warmUpRange(int centre) {
    final list = _getCurrentFeedList(shortsFeedController!);
    if (list == null) return;
    final int len = list.length;
    final int left = (centre - 1).clamp(0, len - 1);
    final int right = (centre + 1).clamp(0, len - 1);

    /* dispose far away */
    final toRemove = <int>{};
    _videoCache.keys.forEach((i) {
      if (i < left || i > right) toRemove.add(i);
    });

    if (toRemove.isNotEmpty) {
      print('🗑️ WARMUP: Disposing controllers outside range [$left-$right]: $toRemove');
    }

    toRemove.forEach((i) {
      final controller = _videoCache[i]?.controller;
      if (controller != null) {
        final wasPlaying = controller.value.isPlaying;
        print('   - Disposing cache[$i]: was playing: $wasPlaying, controller: ${controller.hashCode}');
        controller.dispose();
      }
      _videoCache.remove(i);
    });

    /* create missing — always cover the whole [left..right] window so the
       current page and its immediate neighbours are ready to play. The
       dispose-far pass above already capped the map, so no extra guard. */
    final toCreate = <int>[];
    for (int i = left; i <= right; i++) {
      if (_videoCache.containsKey(i)) continue;
      final item = list.elementAtOrNull(i);
      if (item == null) continue;

      toCreate.add(i);
      _videoCache[i] = _createEntry(item, i);
    }

    if (toCreate.isNotEmpty) {
      print('🆕 WARMUP: Created new controllers for indices: $toCreate');
    }
  }

  /// Picks the playback url: the HLS/adaptive master stream on Android (far
  /// smoother and lighter than the raw mp4), falling back to the progressive
  /// url. Once a video's master has errored (see [_onControllerError]) we pin
  /// it to the mp4. Must match [ShortPlayerItem] so we never download two
  /// variants.
  String _resolveUrl(ShortFeedItem item) {
    final master = item.video?.transcodedUrls?.master;
    final mp4 = item.video?.videoUrl;
    final id = item.video?.id;
    final useFallback = id != null && _mp4FallbackIds.contains(id);
    if (GetPlatform.isAndroid &&
        !useFallback &&
        master != null &&
        master.isNotEmpty) {
      return master;
    }
    return mp4 ?? master ?? '';
  }

  /// Builds a ready-to-initialize cache entry for [item] at [index]. Attaches
  /// an error watcher so a mid-stream decode/load failure on the HLS master
  /// (common with some HEVC variants) transparently rebuilds the slot on the
  /// progressive mp4 instead of dead-ending on a Retry button.
  _VideoCacheEntry _createEntry(ShortFeedItem item, int index) {
    final url = _resolveUrl(item);
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
      httpHeaders: isHlsUrl(url)
          ? const {'User-Agent': 'Flutter Video Player'}
          : const {},
    );
    controller.setLooping(true);

    void onError() {
      if (!mounted) return;
      if (controller.value.hasError) {
        controller.removeListener(onError);
        _onControllerError(index, item);
      }
    }

    controller.addListener(onError);
    return _VideoCacheEntry(
      controller: controller,
      initializeFuture: controller.initialize(),
      coverUrl: item.video?.coverUrl,
    );
  }

  /// First error on a video's HLS master → pin it to the progressive mp4 and
  /// rebuild this slot. If we're already on mp4 (or there's no mp4 to fall back
  /// to) we leave the controller errored so [ShortPlayerItem] shows its Retry —
  /// that's a genuine failure, not the HEVC-HLS quirk.
  void _onControllerError(int index, ShortFeedItem item) {
    final id = item.video?.id;
    final mp4 = item.video?.videoUrl;
    if (id == null ||
        _mp4FallbackIds.contains(id) ||
        mp4 == null ||
        mp4.isEmpty) {
      return;
    }
    _mp4FallbackIds.add(id);
    _videoCache[index]?.controller?.dispose();
    _videoCache[index] = _createEntry(item, index); // now resolves to mp4
    if (index == currentIndex) _playWhenReady(index);
    if (mounted) setState(() {});
  }

  /// Dispose + rebuild a single controller. Used by the per-item Retry so a
  /// failed page can recover without tearing down the whole feed.
  void _reloadIndex(int index) {
    final list = _getCurrentFeedList(shortsFeedController!);
    final item = list?.elementAtOrNull(index);
    if (item == null) return;
    print('🔁 RELOAD: Rebuilding controller for index $index');
    _videoCache[index]?.controller?.dispose();
    _videoCache[index] = _createEntry(item, index);
    if (index == currentIndex) _playWhenReady(index);
    if (mounted) setState(() {});
  }

  /// Play [index] as soon as its controller is initialized, but only if it is
  /// still the visible page by then (guards against fast scrolling).
  void _playWhenReady(int index) {
    final entry = _videoCache[index];
    if (entry == null) return;
    entry.initializeFuture?.then((_) {
      if (!mounted || currentIndex != index) return;
      entry.controller?.play();
      _acquireWakeLock();
      setState(() {});
    }).catchError((_) {});
  }

  void _initializeFeedData() {
    print('📋 FEED: Initializing feed data for ${widget.shorts}');
    switch (widget.shorts) {
      case Shorts.trending:
        shortsFeedController?.trendingVideoFeedPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.nearBy:
        shortsFeedController?.nearByVideoFeedPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.personalized:
        shortsFeedController?.personalizedVideoFeedPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.latest:
        shortsFeedController?.latestShortsPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.popular:
        shortsFeedController?.popularShortsPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.oldest:
        shortsFeedController?.oldestShortsPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.saved:
        shortsFeedController?.savedShorts.value = [...widget.initialShorts];
        break;
      case Shorts.homeShort:
        shortsFeedController?.homeShortPosts.value = [...widget.initialShorts];
        break;
      case Shorts.homeLong:
        shortsFeedController?.homeLongPosts.value = [...widget.initialShorts];
        break;
      default:
        break;
    }
    print('📋 FEED: Feed initialized with ${widget.initialShorts.length} items');
  }

  List<ShortFeedItem>? _getCurrentFeedList(ShortsController controller) {
    switch (widget.shorts) {
      case Shorts.trending:
        return controller.trendingVideoFeedPosts;
      case Shorts.nearBy:
        return controller.nearByVideoFeedPosts;
      case Shorts.personalized:
        return controller.personalizedVideoFeedPosts;
      case Shorts.latest:
        return controller.latestShortsPosts;
      case Shorts.popular:
        return controller.popularShortsPosts;
      case Shorts.oldest:
        return controller.oldestShortsPosts;
      case Shorts.saved:
        return controller.savedShorts;
      case Shorts.homeShort:
        return controller.homeShortPosts;
      case Shorts.homeLong:
        return controller.homeLongPosts;
      default:
        return null;
    }
  }

  void _onScrollToEnd(ShortsController controller) {
    print('🔄 LOAD_MORE: Loading more content for ${widget.shorts}');
    switch (widget.shorts) {
      case Shorts.trending:
        controller.getAllFeedTrending();
        break;
      case Shorts.nearBy:
        controller.getAllFeedNearBy();
        break;
      case Shorts.personalized:
        controller.getAllFeedPersonalized();
        break;
      case Shorts.homeShort:
        controller.getHomeShortFeed();
        break;
      case Shorts.homeLong:
        controller.getHomeLongFeed();
        break;
      default:
        break;
    }
  }

  Future<void> _blockUserAndAdvance(
      {required ShortFeedItem videoItem,
        required String otherUserId}) async {
    print('🚫 BLOCK: Blocking user and advancing...');
    final list = _getCurrentFeedList(shortsFeedController!);
    if (list == null) return;
    final id = videoItem.video?.id;
    int index = list.indexWhere((v) => v.video?.id == id);
    if (index == -1) index = currentIndex;

    final controller = _videoCache[index]?.controller;
    if (controller != null) {
      final wasPlaying = controller.value.isPlaying;
      controller.pause();
      print('🔇 BLOCK: Paused video at index $index (was playing: $wasPlaying)');
    }

    final hasNext = index < list.length - 1;
    final hasPrev = index > 0;
    if (hasNext) {
      print('➡️ BLOCK: Moving to next video (index ${index + 1})');
      await _pageController.animateToPage(index + 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut);
    } else if (hasPrev) {
      print('⬅️ BLOCK: Moving to previous video (index ${index - 1})');
      await _pageController.animateToPage(index - 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut);
    }

    await Get.find<ShortsController>()
        .userBlocked(shortsType: widget.shorts, otherUserId: otherUserId);
    print('✅ BLOCK: User blocked successfully');
  }

  void _onPageChanged(int index) {
    print('📄 PAGE_CHANGE: From $currentIndex to $index');
    setState(() => currentIndex = index);

    /* pause others */
    final pausedIndices = <int>[];
    _videoCache.forEach((i, e) {
      if (i != index && e.controller != null) {
        final wasPlaying = e.controller!.value.isPlaying;
        if (wasPlaying) {
          e.controller!.pause();
          pausedIndices.add(i);
        }
      }
    });

    if (pausedIndices.isNotEmpty) {
      print('🔇 PAGE_CHANGE: Paused controllers at indices: $pausedIndices');
      _releaseWakeLock();
    }

    /* preload neighbours first so the current page has a controller */
    _warmUpRange(index);

    /* play current as soon as it is initialized */
    _playWhenReady(index);

    /* load more */
    final list = _getCurrentFeedList(shortsFeedController!);
    if (index >= (list?.length ?? 0) - 3) {
      _onScrollToEnd(shortsFeedController!);
    }

  }

  Future<bool> _onPop() async {
    print('🔙 BACK_PRESSED: Starting pop handling...');

    // Pause the currently playing video specifically
    final currentController = _videoCache[currentIndex]?.controller;
    if (currentController != null) {
      final wasPlaying = currentController.value.isPlaying;
      currentController.pause();
      _releaseWakeLock();
      print('🔇 BACK_PRESSED: Paused current video at index $currentIndex (was playing: $wasPlaying)');
    } else {
      print('⚠️ BACK_PRESSED: No controller found for current index $currentIndex');
    }

    // Also pause all other cached controllers as a safety measure
    final pausedIndices = <int>[];
    _videoCache.forEach((index, entry) {
      if (entry.controller != null && entry.controller!.value.isPlaying) {
        entry.controller!.pause();
        pausedIndices.add(index);
      }
    });

    if (pausedIndices.isNotEmpty) {
      print('🔇 BACK_PRESSED: Also paused controllers at indices: $pausedIndices');
    }

    // Print final cache state
    _printCache();
    print('✅ BACK_PRESSED: All audio should now be stopped');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: PopScope(
        onPopInvokedWithResult: (_, __) => _onPop(),
        child: Scaffold(
          backgroundColor: AppColors.black,
          body: Stack(
            children: [
              Obx(() {
                final list = _getCurrentFeedList(shortsFeedController!);
                return PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  itemCount: list?.length ?? 0,
                  onPageChanged: _onPageChanged,
                    itemBuilder: (_, index) {
                      final item = list![index];
                      return ShortPlayerItem(
                        key: ValueKey(item.video?.id ?? index),
                        videoItem: item,
                        autoPlay: index == currentIndex,
                        // autoPlay: !_isAdShowing && index == currentIndex,
                        shorts: widget.shorts,
                        onTapOption: () => openBlockSelectionDialog(
                          context: context,
                          reportType: 'VIDEO_POST',
                          userId: item.video?.userId ?? '',
                          contentId: item.video?.id ?? '',
                          userBlockVoidCallback: () async =>
                              _blockUserAndAdvance(
                                  videoItem: item,
                                  otherUserId: item.video?.userId ?? ''
                              ),
                          reportCallback: (params) =>
                              Get.find<ShortsController>().shortPostReport(
                                  videoId: item.video?.id ?? '',
                                  shorts: widget.shorts,
                                  params: params),
                        ),
                        /* ---- NEW: pass pre-built controller ---- */
                        onReload: () => _reloadIndex(index),
                        preloadedController: _videoCache[index]?.controller,
                        initializeFuture: _videoCache[index]?.initializeFuture,
                        coverUrl: _videoCache[index]?.coverUrl,
                        /* ---------------------------------------- */
                      );
                    },
                );
              }),

              // Instagram-style seekable scrubber, lifted off the bottom edge
              // and inset so it's easy to grab and drag.
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: _buildProgressBar(),
              ),

              // DEBUG: Floating button for manual cache inspection (remove in production)
              // Positioned(
              //   top: 100,
              //   right: 20,
              //   child: FloatingActionButton(
              //     mini: true,
              //     backgroundColor: Colors.red.withValues(alpha: 0.7),
              //     onPressed: debugCacheStatus,
              //     child: Icon(Icons.bug_report, color: Colors.white, size: 16),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  /// Instagram-style seekable scrubber for the *current* reel. Keyed by the
  /// controller so its scrub state resets when the page (or the mp4-fallback
  /// swap) hands us a different controller.
  Widget _buildProgressBar() {
    final controller = _videoCache[currentIndex]?.controller;
    if (controller == null) return const SizedBox.shrink();
    return _ReelScrubBar(key: ValueKey(controller), controller: controller);
  }

  // Enhanced cache printing method
  void _printCache() {
    print('📊 CACHE_STATUS: Current cache state:');
    if (_videoCache.isEmpty) {
      print('   - Cache is empty');
      return;
    }

    _videoCache.forEach((idx, e) {
      final c = e.controller;
      if (c != null) {
        final isInit = c.value.isInitialized;
        final isPlaying = c.value.isPlaying;
        final isLooping = c.value.isLooping;
        final duration = c.value.duration;
        final position = c.value.position;
        final hasError = c.value.hasError;
        final volume = c.value.volume;

        print('   - Cache[$idx]: '
            'controller=${c.hashCode}, '
            'initialized=$isInit, '
            'playing=$isPlaying, '
            'looping=$isLooping, '
            'volume=$volume, '
            'duration=$duration, '
            'position=$position, '
            'hasError=$hasError');
      } else {
        print('   - Cache[$idx]: controller=NULL');
      }
    });
  }

  // Call this method whenever you want to check cache status
  void debugCacheStatus() {
    print('🔍 MANUAL_DEBUG: Cache status requested');
    _printCache();
  }
}

/* helper class to keep controller + first frame + cover */
class _VideoCacheEntry {
  VideoPlayerController? controller;
  Future<void>? initializeFuture;
  String? coverUrl;

  _VideoCacheEntry({this.controller, this.initializeFuture, this.coverUrl});
}

/// Instagram-style seekable scrubber. Thin while playing; on touch it thickens,
/// grows a draggable knob, and reveals the current / total time. Dragging seeks
/// the underlying controller live, so the full-screen video frame itself
/// previews the scrubbed moment (video_player has no sprite thumbnails — the
/// real frame is the preview). Playback resumes on release if it was playing.
class _ReelScrubBar extends StatefulWidget {
  final VideoPlayerController controller;
  const _ReelScrubBar({super.key, required this.controller});

  @override
  State<_ReelScrubBar> createState() => _ReelScrubBarState();
}

class _ReelScrubBarState extends State<_ReelScrubBar> {
  bool _scrubbing = false;
  double _scrubFraction = 0; // 0..1 while scrubbing
  bool _wasPlaying = false;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startScrub(double dx, double width) {
    final value = widget.controller.value;
    if (!value.isInitialized || value.duration.inMilliseconds <= 0) return;
    // A drag fires both onTapDown and onHorizontalDragStart → don't re-capture
    // _wasPlaying (we've already paused, so it'd read false and never resume).
    if (_scrubbing) {
      _updateScrub(dx, width);
      return;
    }
    _wasPlaying = value.isPlaying;
    widget.controller.pause();
    setState(() {
      _scrubbing = true;
      _scrubFraction = (dx / width).clamp(0.0, 1.0);
    });
    _seekToFraction(_scrubFraction);
  }

  void _updateScrub(double dx, double width) {
    if (!_scrubbing) return;
    setState(() => _scrubFraction = (dx / width).clamp(0.0, 1.0));
    _seekToFraction(_scrubFraction);
  }

  void _endScrub() {
    if (!_scrubbing) return;
    setState(() => _scrubbing = false);
    if (_wasPlaying) widget.controller.play();
  }

  void _seekToFraction(double f) =>
      widget.controller.seekTo(widget.controller.value.duration * f);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (_, value, __) {
        if (!value.isInitialized || value.duration.inMilliseconds <= 0) {
          return const SizedBox.shrink();
        }
        final fraction = _scrubbing
            ? _scrubFraction
            : (value.position.inMilliseconds / value.duration.inMilliseconds)
                .clamp(0.0, 1.0);
        final current = value.duration * fraction;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current / total time — fades in only while scrubbing (IG-style).
            AnimatedOpacity(
              opacity: _scrubbing ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(current),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    Text(_fmt(value.duration),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            LayoutBuilder(builder: (ctx, c) {
              final width = c.maxWidth;
              final barHeight = _scrubbing ? 5.0 : 2.5;
              final playedWidth = (width * fraction).clamp(0.0, width);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) =>
                    _startScrub(d.localPosition.dx, width),
                onHorizontalDragUpdate: (d) =>
                    _updateScrub(d.localPosition.dx, width),
                onHorizontalDragEnd: (_) => _endScrub(),
                onHorizontalDragCancel: _endScrub,
                onTapDown: (d) => _startScrub(d.localPosition.dx, width),
                onTapUp: (_) => _endScrub(),
                // Tall transparent hit area so the thin line is easy to grab.
                child: SizedBox(
                  height: 22,
                  width: double.infinity,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: width,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: playedWidth,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (_scrubbing)
                          Positioned(
                            left: playedWidth - 7,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

