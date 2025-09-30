import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/reel/view/shorts/short_player_item.dart';
import 'package:BlueEra/widgets/intertitial_ad_service.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
  final ShortsController shortsFeedController = Get.put(ShortsController());
  late final PageController _pageController;
  int currentIndex = 0;

  /* ------------- NEW: zero-lag cache ------------- */
  final _videoCache = <int, _VideoCacheEntry>{};
  static const int _maxCachedVideos = 3;
  static const double _swipeThreshold = 0.5;
  int _lastRoundedPage = 0;
  /* ----------------------------------------------- */

  final InterstitialAdService _interstitialService = InterstitialAdService();
  String? adUnitId;
  bool _isAdShowing = false;

  @override
  void initState() {
    super.initState();
    print('🚀 INIT: ShortsPlayerScreen initializing...');
    WidgetsBinding.instance.addObserver(this);
    currentIndex = widget.initialIndex;
    _lastRoundedPage = currentIndex;
    _pageController = PageController(initialPage: currentIndex);
    print('📍 INIT: Starting at index $currentIndex');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeedData();
      _warmUpRange(currentIndex);
      print('✅ INIT: Initialization complete');
    });

    adUnitId = getInterstitialAdUnitId();
    if (Platform.isAndroid && adUnitId != null) {
      _interstitialService.loadInterstitialAd(adUnitId: adUnitId!);
    }
  }

  @override
  void dispose() {
    print('🔴 DISPOSE: Starting disposal process...');
    WidgetsBinding.instance.removeObserver(this);

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
    _interstitialService.dispose();
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
        print('🔇 LIFECYCLE: Paused video at index $currentIndex (was playing: $wasPlaying)');
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isAdShowing) {
        final controller = _videoCache[currentIndex]?.controller;
        if (controller != null) {
          controller.play();
          print('▶️ LIFECYCLE: Resumed video at index $currentIndex');
        }
      }
    }
  }

  /* --------------  NEW : half-page swipe  -------------- */
  void _onScroll() {
    if (!_pageController.hasClients) return;
    final double page = _pageController.page!;
    final int round = page.round();
    if (round != _lastRoundedPage && (page - round).abs() < _swipeThreshold) {
      // _copyStateToNeighbour(_lastRoundedPage, round);
      print('📜 SCROLL: Half-page swipe detected from $_lastRoundedPage to $round');
      _lastRoundedPage = round;
      _warmUpRange(round);
      setState(() {});
    }
  }

  void _copyStateToNeighbour(int from, int to) {
    final list = _getCurrentFeedList(shortsFeedController);
    if (list == null) return;
    final fromItem = list.elementAtOrNull(from);
    final toItem = list.elementAtOrNull(to);
    if (fromItem == null || toItem == null) return;
    toItem.video?.stats?.likes = fromItem.video?.stats?.likes;
    toItem.video?.stats?.comments = fromItem.video?.stats?.comments;
    toItem.interactions?.isLiked = fromItem.interactions?.isLiked;
  }
  /* ------------------------------------------------------ */

  /* --------------  NEW : OOM-safe cache  -------------- */
  void _warmUpRange(int centre) {
    final list = _getCurrentFeedList(shortsFeedController);
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

    /* create missing */
    final toCreate = <int>[];
    for (int i = left; i <= right; i++) {
      if (_videoCache.containsKey(i)) continue;
      if (_videoCache.length >= _maxCachedVideos) continue;
      final item = list.elementAtOrNull(i);
      if (item == null) continue;

      toCreate.add(i);
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(item.video?.transcodedUrls?.master ??
            item.video?.videoUrl ??
            ''),
      );
      _videoCache[i] = _VideoCacheEntry(
        controller: controller,
        initializeFuture: controller.initialize(),
        coverUrl: item.video?.coverUrl,
      );
    }

    if (toCreate.isNotEmpty) {
      print('🆕 WARMUP: Created new controllers for indices: $toCreate');
    }
  }
  /* ----------------------------------------------------- */

  void _initializeFeedData() {
    print('📋 FEED: Initializing feed data for ${widget.shorts}');
    switch (widget.shorts) {
      case Shorts.trending:
        shortsFeedController.trendingVideoFeedPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.nearBy:
        shortsFeedController.nearByVideoFeedPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.personalized:
        shortsFeedController.personalizedVideoFeedPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.latest:
        shortsFeedController.latestShortsPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.popular:
        shortsFeedController.popularShortsPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.oldest:
        shortsFeedController.oldestShortsPosts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.saved:
        shortsFeedController.savedShorts.value = [...widget.initialShorts];
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
      default:
        break;
    }
  }

  Future<void> _blockUserAndAdvance(
      {required ShortFeedItem videoItem,
        required String otherUserId}) async {
    print('🚫 BLOCK: Blocking user and advancing...');
    final list = _getCurrentFeedList(shortsFeedController);
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
    }

    /* play current */
    final currentController = _videoCache[index]?.controller;
    if (currentController != null) {
      currentController.play();
      print('▶️ PAGE_CHANGE: Started playing controller at index $index (${currentController.hashCode})');
    } else {
      print('⚠️ PAGE_CHANGE: No controller found for index $index');
    }

    /* preload */
    _warmUpRange(index);

    /* load more */
    final list = _getCurrentFeedList(shortsFeedController);
    if (index >= (list?.length ?? 0) - 3) {
      _onScrollToEnd(shortsFeedController);
    }

    /* ads each 6th video */
    if (adUnitId != null && index != 0 && index % 6 == 0) {
      _isAdShowing = true;
      _videoCache[index]?.controller?.pause();
      print('📺 AD: Paused video at index $index for ad');
      _interstitialService.showInterstitialAd(onAdClosed: () {
        _isAdShowing = false;
        _videoCache[index]?.controller?.play();
        print('📺 AD: Resumed video at index $index after ad');
        setState(() {});
      });
      if (Platform.isAndroid) {
        _interstitialService.loadInterstitialAd(adUnitId: adUnitId!);
      }
    }
  }

  Future<bool> _onPop() async {
    print('🔙 BACK_PRESSED: Starting pop handling...');

    // Pause the currently playing video specifically
    final currentController = _videoCache[currentIndex]?.controller;
    if (currentController != null) {
      final wasPlaying = currentController.value.isPlaying;
      currentController.pause();
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
        onPopInvoked: (_) => _onPop(),
        child: Scaffold(
          backgroundColor: AppColors.black,
          body: Stack(
            children: [
              Obx(() {
                final list = _getCurrentFeedList(shortsFeedController);
                return NotificationListener<ScrollNotification>(
                  onNotification: (_) {
                    _onScroll(); // half-page swipe
                    return false;
                  },
                  child: PageView.builder(
                    scrollDirection: Axis.vertical,
                    controller: _pageController,
                    itemCount: list?.length ?? 0,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, index) {
                      final item = list![index];
                      return ShortPlayerItem(
                        key: ValueKey(item.video?.id ?? index),
                        videoItem: item,
                        autoPlay: !_isAdShowing && index == currentIndex,
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
                        preloadedController: _videoCache[index]?.controller,
                        initializeFuture: _videoCache[index]?.initializeFuture,
                        coverUrl: _videoCache[index]?.coverUrl,
                        /* ---------------------------------------- */
                      );
                    },
                  ),
                );
              }),

              // DEBUG: Floating button for manual cache inspection (remove in production)
              // Positioned(
              //   top: 100,
              //   right: 20,
              //   child: FloatingActionButton(
              //     mini: true,
              //     backgroundColor: Colors.red.withOpacity(0.7),
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

// import 'dart:io';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_enum.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
// import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
// import 'package:BlueEra/features/common/reel/view/shorts/short_player_item.dart';
// import 'package:BlueEra/widgets/intertitial_ad_service.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class ShortsPlayerScreen extends StatefulWidget {
//   final Shorts shorts;
//   final List<ShortFeedItem> initialShorts;
//   final int initialIndex;
//
//   const ShortsPlayerScreen(
//       {super.key,
//         required this.shorts,
//         required this.initialShorts,
//         required this.initialIndex});
//
//   @override
//   State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
// }
//
// class _ShortsPlayerScreenState extends State<ShortsPlayerScreen>
//     with WidgetsBindingObserver {
//   final ShortsController shortsFeedController = Get.put(ShortsController());
//   late final PageController _pageController;
//   int currentIndex = 0;
//
//   // Video preloading management
//   final Map<int, bool> _preloadedVideos = {};
//   final Set<int> _currentlyPreloading = {};
//   static const int _preloadDistance = 2; // Preload 2 videos ahead and behind
//   static const int _maxCachedVideos = 5; // Maximum videos to keep in memory
//
//   // Keys for managing video players
//   final Map<int, GlobalKey<ShortPlayerItemState>> _playerKeys = {};
//
//   final InterstitialAdService _interstitialService = InterstitialAdService();
//   String? adUnitId;
//   bool _isAdShowing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     currentIndex = widget.initialIndex;
//     _pageController = PageController(initialPage: currentIndex);
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeFeedData();
//       _preloadVideosAroundIndex(currentIndex);
//     });
//
//
//     adUnitId = getInterstitialAdUnitId();
//     if(Platform.isAndroid && adUnitId!=null) {
//       _interstitialService.loadInterstitialAd(adUnitId: adUnitId!);
//     }
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _disposeAllPlayers();
//     _pageController.dispose();
//     _interstitialService.dispose();
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     switch (state) {
//       case AppLifecycleState.paused:
//       case AppLifecycleState.inactive:
//         _pauseCurrentVideo();
//         break;
//       case AppLifecycleState.resumed:
//         _resumeCurrentVideo();
//         break;
//       case AppLifecycleState.detached:
//         _disposeAllPlayers();
//         break;
//       default:
//         break;
//     }
//   }
//
//   void _initializeFeedData() {
//     switch (widget.shorts) {
//       case Shorts.trending:
//         shortsFeedController.trendingVideoFeedPosts.value = [
//           ...widget.initialShorts
//         ];
//         break;
//       case Shorts.nearBy:
//         shortsFeedController.nearByVideoFeedPosts.value = [
//           ...widget.initialShorts
//         ];
//         break;
//       case Shorts.personalized:
//         shortsFeedController.personalizedVideoFeedPosts.value = [
//           ...widget.initialShorts
//         ];
//         break;
//       case Shorts.latest:
//         shortsFeedController.latestShortsPosts.value = [
//           ...widget.initialShorts
//         ];
//         break;
//       case Shorts.popular:
//         shortsFeedController.popularShortsPosts.value = [
//           ...widget.initialShorts
//         ];
//         break;
//       case Shorts.oldest:
//         shortsFeedController.oldestShortsPosts.value = [
//           ...widget.initialShorts
//         ];
//         break;
//       case Shorts.saved:
//         shortsFeedController.savedShorts.value = [
//           ...widget.initialShorts
//         ];
//         break;
//       case Shorts.underProgress:
//         break;
//       default:
//         break;
//     }
//   }
//
//   void _onScrollToEnd(ShortsController controller) {
//     switch (widget.shorts) {
//       case Shorts.trending:
//         controller.getAllFeedTrending();
//         break;
//       case Shorts.nearBy:
//         controller.getAllFeedNearBy();
//         break;
//       case Shorts.personalized:
//         controller.getAllFeedPersonalized();
//         break;
//       case Shorts.latest:
//       // controller.getShortsByType(
//       //     widget.sortBy,
//       //     widget.channelId,
//       //     widget.authorId,
//       //     widget.isOwnChannel,
//       //     isInitialLoad: isInitialLoad,
//       //     refresh: refresh
//       // );
//         break;
//       case Shorts.popular:
//       // shortsFeedController.popularShortsPosts.value = [
//       //   ...widget.initialShorts
//       // ];
//         break;
//       case Shorts.oldest:
//       // shortsFeedController.oldestShortsPosts.value = [
//       //   ...widget.initialShorts
//       // ];
//         break;
//       case Shorts.saved:
//         break;
//       case Shorts.underProgress:
//         break;
//       default:
//         break;
//     }
//   }
//
//   List<ShortFeedItem>? _getCurrentFeedList(ShortsController controller) {
//     switch (widget.shorts) {
//       case Shorts.trending:
//         return controller.trendingVideoFeedPosts;
//       case Shorts.nearBy:
//         return controller.nearByVideoFeedPosts;
//       case Shorts.personalized:
//         return controller.personalizedVideoFeedPosts;
//       case Shorts.latest:
//         return controller.latestShortsPosts;
//       case Shorts.popular:
//         return controller.popularShortsPosts;
//       case Shorts.oldest:
//         return controller.oldestShortsPosts;
//       case Shorts.saved:
//         return controller.savedShorts;
//       default:
//         return null;
//     }
//   }
//
//   void _preloadVideosAroundIndex(int index) {
//     final currentFeedList = _getCurrentFeedList(shortsFeedController);
//     if (currentFeedList?.isEmpty??false) return;
//
//     // Calculate range for preloading
//     final start =
//     (index - _preloadDistance).clamp(0, (currentFeedList?.length??0) - 1);
//     final end = (index + _preloadDistance).clamp(0, (currentFeedList?.length??0) - 1);
//
//     // Dispose videos outside the range to free memory
//     _disposeVideosOutsideRange(start, end);
//
//     // Preload videos in range
//     for (int i = start; i <= end; i++) {
//       if (!_preloadedVideos.containsKey(i) &&
//           !_currentlyPreloading.contains(i)) {
//         _preloadVideo(i);
//       }
//     }
//   }
//
//   void _preloadVideo(int index) {
//     if (_currentlyPreloading.contains(index)) return;
//
//     _currentlyPreloading.add(index);
//
//     // Create a key for the video player if it doesn't exist
//     if (!_playerKeys.containsKey(index)) {
//       _playerKeys[index] = GlobalKey<ShortPlayerItemState>();
//     }
//
//     // Mark as preloaded (will be handled by ShortPlayerItem)
//     _preloadedVideos[index] = true;
//     _currentlyPreloading.remove(index);
//   }
//
//   void _disposeVideosOutsideRange(int start, int end) {
//     final keysToRemove = <int>[];
//
//     for (final key in _playerKeys.keys) {
//       if (key < start || key > end) {
//         // Dispose the video player
//         _playerKeys[key]?.currentState?.disposePlayer();
//         keysToRemove.add(key);
//       }
//     }
//
//     // Clean up maps
//     for (final key in keysToRemove) {
//       _playerKeys.remove(key);
//       _preloadedVideos.remove(key);
//       _currentlyPreloading.remove(key);
//     }
//   }
//
//   void _disposeAllPlayers() {
//     for (final key in _playerKeys.keys) {
//       _playerKeys[key]?.currentState?.disposePlayer();
//     }
//     _playerKeys.clear();
//     _preloadedVideos.clear();
//     _currentlyPreloading.clear();
//   }
//
//   void _pauseCurrentVideo() {
//     _playerKeys[currentIndex]?.currentState?.pauseVideo();
//   }
//
//   void _resumeCurrentVideo() {
//     _playerKeys[currentIndex]?.currentState?.playVideo();
//   }
//
//   Future<void> _blockUserAndAdvance({required ShortFeedItem videoItem, required String otherUserId}) async {
//     final controller = shortsFeedController;
//     final currentFeedList = _getCurrentFeedList(controller);
//     final String? currentId = videoItem.video?.id;
//
//     if(currentFeedList!=null) return;
//     int index = currentFeedList!.indexWhere((v) => v.video?.id == currentId);
//
//     if (index == -1) {
//       // Fallback to current index
//       index = currentIndex;
//     }
//
//     _playerKeys[index]?.currentState?.pauseVideo();
//
//     final bool hasNext = index < currentFeedList.length - 1;
//     final bool hasPrev = index > 0;
//
//     if (hasNext) {
//       await _pageController.animateToPage(
//         index + 1,
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeInOut,
//       );
//     } else if (hasPrev) {
//       await _pageController.animateToPage(
//         index - 1,
//         duration: const Duration(milliseconds: 200),
//         curve: Curves.easeInOut,
//       );
//     }
//
//     await Get.find<ShortsController>().userBlocked(
//       shortsType: widget.shorts,
//       otherUserId: otherUserId,
//     );
//   }
//
//   void _onPageChanged(int index) {
//     setState(() => currentIndex = index);
//
//     // Pause previous video
//     for (int i = 0; i < _playerKeys.length; i++) {
//       if (i != index) {
//         _playerKeys[i]?.currentState?.pauseVideo();
//       }
//     }
//
//     // Play current video
//     _playerKeys[index]?.currentState?.playVideo();
//
//     // Preload videos around new index
//     _preloadVideosAroundIndex(index);
//
//     // Load more content if near the end
//     final currentFeedList = _getCurrentFeedList(shortsFeedController);
//     if (index >= (currentFeedList?.length??0) - 3) {
//       _onScrollToEnd(shortsFeedController);
//     }
//
//     if (adUnitId != null && index != 0 && index % 6 == 0) {
//       _isAdShowing = true;
//
//       // Pause current video
//       _playerKeys[index]?.currentState?.pauseVideo();
//
//       // Pause any other video just in case
//       _playerKeys.forEach((key, playerKey) {
//         playerKey.currentState?.pauseVideo();
//       });
//
//       _interstitialService.showInterstitialAd(
//         onAdClosed: () {
//           _isAdShowing = false;
//           // Resume the current video
//           _playerKeys[index]?.currentState?.playVideo();
//           setState(() {}); // rebuild to re-enable autoPlay
//         },
//       );
//
//       // Preload next ad for future
//       if(Platform.isAndroid) {
//         _interstitialService.loadInterstitialAd(adUnitId: adUnitId!);
//       }
//     }
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.black,
//       body: Obx(() {
//         final currentFeedList = _getCurrentFeedList(shortsFeedController);
//
//         return Stack(
//           children: [
//             PageView.builder(
//               scrollDirection: Axis.vertical,
//               controller: _pageController,
//               itemCount: currentFeedList?.length,
//               onPageChanged: _onPageChanged,
//               itemBuilder: (context, index) {
//                 final videoItem = currentFeedList?[index];
//
//                 // Create key if it doesn't exist
//                 if (!_playerKeys.containsKey(index)) {
//                   _playerKeys[index] = GlobalKey<ShortPlayerItemState>();
//                 }
//
//                 return ShortPlayerItem(
//                   key: _playerKeys[index],
//                   videoItem: videoItem!,
//                   autoPlay: !_isAdShowing && currentIndex == index,
//                   shorts: widget.shorts,
//                   shouldPreload: _preloadedVideos.containsKey(index),
//                   onTapOption: () {
//                     openBlockSelectionDialog(
//                         context: context,
//                         reportType: 'VIDEO_POST',
//                         userId: videoItem.video?.userId??'',
//                         contentId: videoItem.video?.id??'',
//                         userBlockVoidCallback: () async {
//                           await _blockUserAndAdvance(
//                             videoItem: videoItem,
//                             otherUserId: videoItem.video?.userId ?? '',
//                           );
//                         },
//                         reportCallback: (params){
//                           Get.find<ShortsController>().shortPostReport(
//                               videoId: videoItem.video?.id??'',
//                               shorts: widget.shorts,
//                               params: params
//                           );
//                         }
//                     );
//                   },
//                 );
//               },
//             ),
//             Positioned(
//               top: SizeConfig.size40,
//               left: SizeConfig.size15,
//               right: SizeConfig.size15,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.only(top: SizeConfig.size6),
//                     child: IconButton(
//                       padding: EdgeInsets.zero,
//                       onPressed: () {
//                         _disposeAllPlayers();
//                         Navigator.of(context).pop();
//                       },
//                       icon: LocalAssets(
//                         imagePath: AppIconAssets.back_arrow,
//                         height: SizeConfig.paddingM,
//                         width: SizeConfig.paddingM,
//                         imgColor: Colors.white,
//                       ),
//                     ),
//                   ),
//                   // IconButton(
//                   //   onPressed: () {},
//                   //   icon: Icon(
//                   //     Icons.more_vert,
//                   //     color: Colors.white,
//                   //     size: SizeConfig.paddingL,
//                   //   ),
//                   // )
//                 ],
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }
// }
