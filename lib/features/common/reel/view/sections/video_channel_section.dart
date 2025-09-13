import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/reel/widget/video_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoChannelSection extends StatefulWidget {
  final bool isOwnVideos;
  final bool isParentScroll;
  final SortBy? sortBy;
  final String channelId;
  final String authorId;
  final PostVia? postVia;
  final double? padding;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onLoadMore; // Callback for pagination


  const VideoChannelSection({
    super.key,
    this.onLoadMore,
    this.postVia,
    this.isOwnVideos = false,
    this.isParentScroll = true,
    this.sortBy,
    this.padding,
    this.boxShadow,
    required this.channelId,
    required this.authorId
  });

  @override
  State<VideoChannelSection> createState() => _VideoChannelSectionState();
}

class _VideoChannelSectionState extends State<VideoChannelSection> {
  final VideoController videosController = Get.put<VideoController>(VideoController());
  VideoType videos = VideoType.latest;

  @override
  void initState() {
    setVideosType();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchChannelVideos(isInitialLoad: true, postVia: widget.postVia);
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VideoChannelSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy) {
      setVideosType();
      fetchChannelVideos(isInitialLoad: true, postVia: widget.postVia);
    }
  }

  setVideosType(){
    videos = switch (widget.sortBy) {
      SortBy.Latest       => VideoType.latest,
      SortBy.Popular      => VideoType.popular,
      SortBy.Oldest       => VideoType.oldest,
      SortBy.UnderProgress=> VideoType.underProgress,
      null                => VideoType.latest, // default for null
    };
  }


  void fetchChannelVideos({bool isInitialLoad = false, bool refresh = false, PostVia? postVia}) {
    videosController.getVideosByType(
        videos,
        widget.channelId,
        widget.authorId,
        isInitialLoad: isInitialLoad,
        refresh: refresh,
        postVia: postVia
    );
  }

  // Method to be called from parent for pagination
  void loadMore() {
    if (videosController.isMoreDataAvailable &&
        videosController.isLoading.isFalse) {
      fetchChannelVideos(postVia: widget.postVia);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if(videosController.isInitialLoading(videos).isFalse){
        if(videosController.channelVideosResponse.value.status == Status.COMPLETE){
          final channelVideos = videosController.getListByType(videoType: videos);
          log("videosPosts--> $channelVideos");

          if (channelVideos.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(top: SizeConfig.size80),
                child: EmptyStateWidget(
                  message: 'No videos available.',
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: channelVideos.length +
                (videosController.isMoreDataLoading(videos).value ? 1 : 0),
            padding: EdgeInsets.only(
                left: widget.padding ?? SizeConfig.paddingXSL,
                right: widget.padding ?? SizeConfig.paddingXSL,
                bottom: widget.padding ?? SizeConfig.paddingXSL,
                top: widget.padding ?? SizeConfig.paddingXSL
            ),
            shrinkWrap: true,
            physics: (widget.isParentScroll) ?  NeverScrollableScrollPhysics(): AlwaysScrollableScrollPhysics(), // Prevent scrolling conflicts
            itemBuilder: (context, index) {
              if (index >= channelVideos.length) {
                return Container(
                  padding: EdgeInsets.all(SizeConfig.size20),
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor),
                  ),
                );
              }

              final videoFeedItem = channelVideos[index];

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
                        videoType: videos,
                        otherUserId: videoFeedItem.video?.userId??'',
                      );
                    },
                    reportCallback: (params){
                        Get.find<VideoController>().videoPostReport(
                            videoId: videoFeedItem.video?.id??'',
                            videoType: videos,
                            params: params
                        );
                      }
                  );
                },
                videoType: videos,
                boxShadow: widget.boxShadow,
              );
            },
          );
        }else{
          return LoadErrorWidget(
              errorMessage: 'Failed to load videos',
              onRetry: ()=>  fetchChannelVideos(isInitialLoad: true,postVia: widget.postVia)
          );
        }
      }else{
        return Center(child: CircularProgressIndicator());
      }
    });
  }
}
