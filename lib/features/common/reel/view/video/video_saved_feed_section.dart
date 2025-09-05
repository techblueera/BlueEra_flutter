import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
 import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/reel/widget/video_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoSavedFeedSection extends StatefulWidget {
  final Function(bool isVisible)? onHeaderVisibilityChanged;
  final String? query;
  final double headerHeight;

  const VideoSavedFeedSection({
    super.key,
    this.onHeaderVisibilityChanged,
    this.query,
    required this.headerHeight
  });

  @override
  State<VideoSavedFeedSection> createState() => _VideoSavedFeedSectionState();
}

class _VideoSavedFeedSectionState extends State<VideoSavedFeedSection>  with RouteAware {
  final ScrollController _scrollController = ScrollController();
  VideoController videoController = Get.put(VideoController());

  @override
  void initState() {
    super.initState();
    videoController.getAllSavedVideos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // we came back to this screen
    videoController.getAllSavedVideos();
  }

  Widget _buildVideoList() {
    return setupScrollVisibilityNotification(
      controller: _scrollController,
      headerHeight: widget.headerHeight,
      onVisibilityChanged: (visible, offset) {
        final controller = Get.find<HomeScreenController>();
        final currentOffset = controller.headerOffset.value;

        // Linear animation step (same speed up/down)
        const step = 0.25; // smaller = smoother, larger = faster

        double newOffset = currentOffset;

        if (visible) {
          // show header → decrease offset
          newOffset = (currentOffset - step).clamp(0.0, 1.0);
        } else {
          // hide header → increase offset
          newOffset = (currentOffset + step).clamp(0.0, 1.0);
        }

        controller.headerOffset.value = newOffset;

        controller.isVisible.value = visible;
        widget.onHeaderVisibilityChanged?.call(visible);
      },
      child: ListView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: videoController.savedVideos.length +
            (videoController.isLoading.value ? 1 : 0),
        padding: EdgeInsets.only(
            left: SizeConfig.paddingXSL,
            right: SizeConfig.paddingXSL,
            bottom: SizeConfig.paddingXSL,
            top: SizeConfig.paddingXSmall
        ),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index >= videoController.savedVideos.length) {
            return Container(
              padding: EdgeInsets.all(SizeConfig.size20),
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            );
          }

          final videoFeedItem = videoController.savedVideos[index];

          return VideoCard(
            videoItem: videoFeedItem,
            onTapOption: () {
              openBlockSelectionDialog(
                  context: context,
                  reportType: 'VIDEO_POST',
                  userId: videoFeedItem.video?.userId??'',
                  contentId: videoFeedItem.video?.id??'',
                  userBlockVoidCallback: () async {
                    await Get.find<VideoController>().userBlocked(
                      videoType: VideoType.saved,
                      otherUserId: videoFeedItem.video?.userId??'',
                    );
                  },
                  reportCallback: (params){
                    Get.find<VideoController>().videoPostReport(
                        videoId: videoFeedItem.video?.id??'',
                        videoType: VideoType.saved,
                        params: params
                    );
                  }
              );
            },
            videoType: VideoType.saved,
          );

        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {

      // if(videoController.isSavedVideosLoading.isFalse){
          final savedVideos = videoController.savedVideos
              .where((e) => e.video?.type == 'long')
              .toList();
          log("savedVideos--> $savedVideos");

          if (savedVideos.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(top: SizeConfig.size80),
                child: EmptyStateWidget(
                  message: 'No videoe saved.',
                ),
              ),
            );
          }

          // Show video list when data is available
          return _buildVideoList();
      // }else{
      //   // Show loading state during initial load
      //   return VideosShimmerStrip();
      // }


    });
  }
}
