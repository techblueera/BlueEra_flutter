import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_dialogs.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/reel/widget/video_card.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoChannelSection extends StatefulWidget {
  final bool isOwnChannel;
  final bool isScroll;
  final SortBy? sortBy;
  final String channelId;
  final String authorId;
  final VoidCallback? onLoadMore; // Callback for pagination

  const VideoChannelSection({
    super.key,
    this.onLoadMore,
    this.isOwnChannel = false,
    this.isScroll = true,
    this.sortBy,
    required this.channelId,
    required this.authorId
  });

  @override
  State<VideoChannelSection> createState() => _VideoChannelSectionState();
}

class _VideoChannelSectionState extends State<VideoChannelSection> {
  final VideoController videosController = Get.put<VideoController>(VideoController());
  ValueNotifier<bool> globalMuteNotifier = ValueNotifier(false);
  Videos videos = Videos.latest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchChannelVideos(isInitialLoad: true);
    });
    setVideosType();
  }

  @override
  void didUpdateWidget(covariant VideoChannelSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy) {
      setVideosType();
      fetchChannelVideos(isInitialLoad: true);
    }
  }

  setVideosType(){
    videos = switch (widget.sortBy) {
      SortBy.Latest       => Videos.latest,
      SortBy.Popular      => Videos.popular,
      SortBy.Oldest       => Videos.oldest,
      SortBy.UnderProgress=> Videos.underProgress,
      null                => Videos.latest, // default for null
    };
  }


  void fetchChannelVideos({bool isInitialLoad = false, bool refresh = false}) {
    videosController.getVideosByType(
        videos,
        widget.channelId,
        widget.authorId,
        widget.isOwnChannel,
        isInitialLoad: isInitialLoad,
        refresh: refresh,
    );
  }

  // Method to be called from parent for pagination
  void loadMore() {
    if (videosController.isMoreDataAvailable &&
        videosController.isLoading.isFalse) {
      fetchChannelVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if(videosController.isInitialLoading(videos).isFalse){
        if(videosController.channelVideosResponse.status == Status.COMPLETE){
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
                (videosController.isLoading.value ? 1 : 0),
            padding: EdgeInsets.only(
                left: SizeConfig.paddingXSL,
                right: SizeConfig.paddingXSL,
                bottom: SizeConfig.paddingXSL,
                top: SizeConfig.paddingM
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Prevent scrolling conflicts
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
                globalMuteNotifier: globalMuteNotifier,
                onTapOption: () {
                  openBlockSelectionDialog(
                      context: context,
                     voidCallback: () async {
                       // if( type=='videoChannel' ||
                       //     type=='videoFeed' ||
                       //     type=='videoSaved'
                       // ){
                         print('call');
                         await Get.find<VideoController>().userBlocked(
                           videoType: videos,
                           otherUserId: videoFeedItem.video?.userId??'',
                         );
                       // }
                     }
                  );
                },
                videoType: videos
              );
            },
          );
        }else{
          return LoadErrorWidget(
              errorMessage: 'Failed to load videos',
              onRetry: ()=>  fetchChannelVideos(isInitialLoad: true)
          );
        }
      }else{
        return Center(child: CircularProgressIndicator());
      }
    });
  }
}
