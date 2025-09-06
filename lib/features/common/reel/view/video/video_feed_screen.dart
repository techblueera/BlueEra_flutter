import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/reel/view/video/videos_shimmer_strip.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/native_ad_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoFeedScreen extends StatefulWidget {
  final Function(bool isVisible)? onHeaderVisibilityChanged;
  final bool isOwnProfile;
  final String? query;
  final double headerHeight;

  const VideoFeedScreen({
    super.key,
    this.isOwnProfile = false,
    this.onHeaderVisibilityChanged,
    this.query,
    required this.headerHeight
  });

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  VideoController videoController = Get.put(VideoController());
  ValueNotifier<bool> globalMuteNotifier = ValueNotifier(false);
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initializeVideoFeed();
    _setupScrollListener();
  }

  void _initializeVideoFeed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      videoController.getAllFeedVideos(isInitialLoad: true, refresh: true, query: widget.query??'');
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Handle pagination
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (videoController.isMoreDataAvailable && videoController.isLoading.isFalse) {
          videoController.getAllFeedVideos(query: widget.query??'');
        }
      }
    });
  }

  // this will if changes in sort by cause page is already loaded
  @override
  void didUpdateWidget(covariant VideoFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    /// this is the case when search query changes
    if (oldWidget.query != widget.query) {
      _onQueryChanged(widget.query);
    }
  }

  void _onQueryChanged(String? newQuery) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      // call the same method you already use
      videoController.getAllFeedVideos(isInitialLoad: true, query: widget.query??'');
    });
  }

  @override
  void dispose() {
    log('dispose');

    _scrollController.dispose();
    globalMuteNotifier.dispose();
    super.dispose();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.emptyIcon,
              height: SizeConfig.size80,
              width: SizeConfig.size80,
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              widget.isOwnProfile ? 'No videos uploaded yet' : 'No videos available',
              color: AppColors.mainTextColor,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              widget.isOwnProfile
                  ? 'Start sharing your moments by uploading your first video!'
                  : 'Check back later for new content from creators.',
              color: AppColors.mainTextColor.withValues(alpha:0.7),
              fontSize: SizeConfig.medium,
              textAlign: TextAlign.center,
            ),
            if (widget.isOwnProfile) ...[
              SizedBox(height: SizeConfig.size24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to upload screen
                  Navigator.pushNamed(context, RouteHelper.getVideoReelRecorderScreenRoute());
                },
                icon: Icon(Icons.add_circle_outline),
                label: CustomText(
                  'Upload Video',
                  color: Colors.white,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size24,
                    vertical: SizeConfig.size12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList() {
    const int videosPerAd = 9;
    const int cycleSize = videosPerAd + 1;

    return setupScrollVisibilityNotification(
      controller: _scrollController,
      headerHeight: widget.headerHeight,
      onVisibilityChanged: (visible, offset) {
        final controller = Get.find<HomeScreenController>();
        final currentOffset = controller.headerOffset.value;

        const step = 0.25;

        double newOffset = currentOffset;
        if (visible) {
          newOffset = (currentOffset - step).clamp(0.0, 1.0);
        } else {
          newOffset = (currentOffset + step).clamp(0.0, 1.0);
        }

        controller.headerOffset.value = newOffset;
        controller.isVisible.value = visible;
        widget.onHeaderVisibilityChanged?.call(visible);
      },
      child: RefreshIndicator(
        notificationPredicate: (notification) {
          return Get.find<HomeScreenController>().headerOffset.value == 0.0 &&
              notification.metrics.pixels <= notification.metrics.minScrollExtent;
        },
        onRefresh: () async {
          if (Get.find<HomeScreenController>().headerOffset.value != 0.0) return;
          videoController.getAllFeedVideos(
            isInitialLoad: true,
            refresh: true,
            query: '',
          );
        },
        child: ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: SizeConfig.paddingXSL,
            right: SizeConfig.paddingXSL,
            bottom: SizeConfig.paddingXSL,
            top: SizeConfig.paddingXSmall,
          ),
          shrinkWrap: true,
          itemCount: videoController.videoFeedPosts.length +
              (videoController.videoFeedPosts.length ~/ videosPerAd) +
              (videoController.isLoadingMore.isTrue ? 1 : 0),
          itemBuilder: (context, index) {
            final String? adUnitId = getNativeAdUnitId();

            // how many ads before this index
            int adCountBeforeIndex = index ~/ cycleSize;
            int videoIndex = index - adCountBeforeIndex;

            // ✅ Loader at the end
            if (videoIndex >= videoController.videoFeedPosts.length) {
              return Container(
                padding: EdgeInsets.all(SizeConfig.size16),
                alignment: Alignment.center,
                child: staggeredDotsWaveLoading(),
              );
            }

            // ✅ Insert ad after every 9 videos (only if NOT iOS)
            if (Platform.isAndroid &&
                adUnitId != null &&
                adUnitId.isNotEmpty &&
                (index + 1) % cycleSize == 0 &&
                videoIndex < videoController.videoFeedPosts.length) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: SizeConfig.size370,
                  maxHeight: SizeConfig.size450,
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: SizeConfig.size10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: NativeAdWidget(adUnitId: adUnitId),
                ),
              );
            }

            // ✅ Normal video card
            final videoFeedItem = videoController.videoFeedPosts[videoIndex];
            return AutoPlayVideoCard(
              videoItem: videoFeedItem,
              globalMuteNotifier: globalMuteNotifier,
              videoType: VideoType.videoFeed,
              onTapOption: () {
                openBlockSelectionDialog(
                  context: context,
                  reportType: 'VIDEO_POST',
                  userId: videoFeedItem.video?.userId??'',
                  contentId: videoFeedItem.video?.id??'',
                  userBlockVoidCallback: () async {
                    await Get.find<VideoController>().userBlocked(
                      videoType: VideoType.videoFeed,
                      otherUserId: videoFeedItem.video?.userId ?? '',
                    );
                  },
                    reportCallback: (params){
                      Get.find<VideoController>().videoPostReport(
                          videoId: videoFeedItem.video?.id??'',
                          videoType: VideoType.videoFeed,
                          params: params
                      );
                    }
                );
              },
            );
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {

      if(videoController.isLoading.isFalse){
        if(videoController.videoPostsResponse.value.status == Status.COMPLETE){

          // Show empty state when no videos are available
          if (videoController.videoFeedPosts.isEmpty) {
            return _buildEmptyState();
          }

          // Show video list when data is available
          return _buildVideoList();
        }else if(videoController.videoPostsResponse.value.status == Status.ERROR){
          return LoadErrorWidget(
            errorMessage: 'Failed to load videos',
            onRetry: () {
              videoController.getAllFeedVideos(isInitialLoad: true, refresh: true);
            });
        }
      }else{
        // Show loading state during initial load
        return VideosShimmerStrip();
      }

      return SizedBox();

    });
  }
}
