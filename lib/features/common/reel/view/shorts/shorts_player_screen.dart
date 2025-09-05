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

class ShortsPlayerScreen extends StatefulWidget {
  final Shorts shorts;
  final List<ShortFeedItem> initialShorts;
  final int initialIndex;

  const ShortsPlayerScreen(
      {super.key,
      required this.shorts,
      required this.initialShorts,
      required this.initialIndex});

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen>
    with WidgetsBindingObserver {
  final ShortsController shortsFeedController = Get.put(ShortsController());
  late final PageController _pageController;
  int currentIndex = 0;

  // Video preloading management
  final Map<int, bool> _preloadedVideos = {};
  final Set<int> _currentlyPreloading = {};
  static const int _preloadDistance = 2; // Preload 2 videos ahead and behind
  static const int _maxCachedVideos = 5; // Maximum videos to keep in memory

  // Keys for managing video players
  final Map<int, GlobalKey<ShortPlayerItemState>> _playerKeys = {};

  final InterstitialAdService _interstitialService = InterstitialAdService();
  String? adUnitId;
  bool _isAdShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeedData();
      _preloadVideosAroundIndex(currentIndex);
    });


    adUnitId = getInterstitialAdUnitId();
    if(Platform.isAndroid && adUnitId!=null) {
      _interstitialService.loadInterstitialAd(adUnitId: adUnitId!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeAllPlayers();
    _pageController.dispose();
    _interstitialService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _pauseCurrentVideo();
        break;
      case AppLifecycleState.resumed:
        _resumeCurrentVideo();
        break;
      case AppLifecycleState.detached:
        _disposeAllPlayers();
        break;
      default:
        break;
    }
  }

  void _initializeFeedData() {
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
        shortsFeedController.savedShorts.value = [
          ...widget.initialShorts
        ];
        break;
      case Shorts.underProgress:
        break;
      default:
        break;
    }
  }

  void _onScrollToEnd(ShortsController controller) {
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
      case Shorts.latest:
        // controller.getShortsByType(
        //     widget.sortBy,
        //     widget.channelId,
        //     widget.authorId,
        //     widget.isOwnChannel,
        //     isInitialLoad: isInitialLoad,
        //     refresh: refresh
        // );
        break;
      case Shorts.popular:
        // shortsFeedController.popularShortsPosts.value = [
        //   ...widget.initialShorts
        // ];
        break;
      case Shorts.oldest:
        // shortsFeedController.oldestShortsPosts.value = [
        //   ...widget.initialShorts
        // ];
        break;
      case Shorts.saved:
        break;
      case Shorts.underProgress:
        break;
      default:
        break;
    }
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

  void _preloadVideosAroundIndex(int index) {
    final currentFeedList = _getCurrentFeedList(shortsFeedController);
    if (currentFeedList?.isEmpty??false) return;

    // Calculate range for preloading
    final start =
        (index - _preloadDistance).clamp(0, (currentFeedList?.length??0) - 1);
    final end = (index + _preloadDistance).clamp(0, (currentFeedList?.length??0) - 1);

    // Dispose videos outside the range to free memory
    _disposeVideosOutsideRange(start, end);

    // Preload videos in range
    for (int i = start; i <= end; i++) {
      if (!_preloadedVideos.containsKey(i) &&
          !_currentlyPreloading.contains(i)) {
        _preloadVideo(i);
      }
    }
  }

  void _preloadVideo(int index) {
    if (_currentlyPreloading.contains(index)) return;

    _currentlyPreloading.add(index);

    // Create a key for the video player if it doesn't exist
    if (!_playerKeys.containsKey(index)) {
      _playerKeys[index] = GlobalKey<ShortPlayerItemState>();
    }

    // Mark as preloaded (will be handled by ShortPlayerItem)
    _preloadedVideos[index] = true;
    _currentlyPreloading.remove(index);
  }

  void _disposeVideosOutsideRange(int start, int end) {
    final keysToRemove = <int>[];

    for (final key in _playerKeys.keys) {
      if (key < start || key > end) {
        // Dispose the video player
        _playerKeys[key]?.currentState?.disposePlayer();
        keysToRemove.add(key);
      }
    }

    // Clean up maps
    for (final key in keysToRemove) {
      _playerKeys.remove(key);
      _preloadedVideos.remove(key);
      _currentlyPreloading.remove(key);
    }
  }

  void _disposeAllPlayers() {
    for (final key in _playerKeys.keys) {
      _playerKeys[key]?.currentState?.disposePlayer();
    }
    _playerKeys.clear();
    _preloadedVideos.clear();
    _currentlyPreloading.clear();
  }

  void _pauseCurrentVideo() {
    _playerKeys[currentIndex]?.currentState?.pauseVideo();
  }

  void _resumeCurrentVideo() {
    _playerKeys[currentIndex]?.currentState?.playVideo();
  }

  Future<void> _blockUserAndAdvance({required ShortFeedItem videoItem, required String otherUserId}) async {
    final controller = shortsFeedController;
    final currentFeedList = _getCurrentFeedList(controller);
    final String? currentId = videoItem.video?.id;

    if(currentFeedList!=null) return;
    int index = currentFeedList!.indexWhere((v) => v.video?.id == currentId);

    if (index == -1) {
      // Fallback to current index
      index = currentIndex;
    }

    _playerKeys[index]?.currentState?.pauseVideo();

    final bool hasNext = index < currentFeedList.length - 1;
    final bool hasPrev = index > 0;

    if (hasNext) {
      await _pageController.animateToPage(
        index + 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else if (hasPrev) {
      await _pageController.animateToPage(
        index - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }

    await Get.find<ShortsController>().userBlocked(
      shortsType: widget.shorts,
      otherUserId: otherUserId,
    );
  }

  void _onPageChanged(int index) {
    setState(() => currentIndex = index);

    // Pause previous video
    for (int i = 0; i < _playerKeys.length; i++) {
      if (i != index) {
        _playerKeys[i]?.currentState?.pauseVideo();
      }
    }

    // Play current video
    _playerKeys[index]?.currentState?.playVideo();

    // Preload videos around new index
    _preloadVideosAroundIndex(index);

    // Load more content if near the end
    final currentFeedList = _getCurrentFeedList(shortsFeedController);
    if (index >= (currentFeedList?.length??0) - 3) {
      _onScrollToEnd(shortsFeedController);
    }

    if (adUnitId != null && index != 0 && index % 6 == 0) {
      _isAdShowing = true;

      // Pause current video
      _playerKeys[index]?.currentState?.pauseVideo();

      // Pause any other video just in case
      _playerKeys.forEach((key, playerKey) {
        playerKey.currentState?.pauseVideo();
      });

      _interstitialService.showInterstitialAd(
        onAdClosed: () {
          _isAdShowing = false;
          // Resume the current video
          _playerKeys[index]?.currentState?.playVideo();
          setState(() {}); // rebuild to re-enable autoPlay
        },
      );

      // Preload next ad for future
      if(Platform.isAndroid) {
        _interstitialService.loadInterstitialAd(adUnitId: adUnitId!);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Obx(() {
        final currentFeedList = _getCurrentFeedList(shortsFeedController);

        return Stack(
          children: [
            PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              itemCount: currentFeedList?.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final videoItem = currentFeedList?[index];

                // Create key if it doesn't exist
                if (!_playerKeys.containsKey(index)) {
                  _playerKeys[index] = GlobalKey<ShortPlayerItemState>();
                }

                return ShortPlayerItem(
                  key: _playerKeys[index],
                  videoItem: videoItem!,
                  autoPlay: !_isAdShowing && currentIndex == index,
                  shorts: widget.shorts,
                  shouldPreload: _preloadedVideos.containsKey(index),
                  onTapOption: () {
                    openBlockSelectionDialog(
                      context: context,
                      reportType: 'VIDEO_POST',
                      userId: videoItem.video?.userId??'',
                      contentId: videoItem.video?.id??'',
                      userBlockVoidCallback: () async {
                        await _blockUserAndAdvance(
                          videoItem: videoItem,
                          otherUserId: videoItem.video?.userId ?? '',
                        );
                      },
                        reportCallback: (params){

                        }
                    );
                  },
                );
              },
            ),
            Positioned(
              top: SizeConfig.size40,
              left: SizeConfig.size15,
              right: SizeConfig.size15,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size6),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _disposeAllPlayers();
                        Navigator.of(context).pop();
                      },
                      icon: LocalAssets(
                        imagePath: AppIconAssets.back_arrow,
                        height: SizeConfig.paddingM,
                        width: SizeConfig.paddingM,
                        imgColor: Colors.white,
                      ),
                    ),
                  ),
                  // IconButton(
                  //   onPressed: () {},
                  //   icon: Icon(
                  //     Icons.more_vert,
                  //     color: Colors.white,
                  //     size: SizeConfig.paddingL,
                  //   ),
                  // )
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
