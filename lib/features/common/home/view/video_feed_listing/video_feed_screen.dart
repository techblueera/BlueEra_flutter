import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_feed_controller.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_player_item.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoFeedScreenNew extends StatefulWidget {
  const VideoFeedScreenNew({Key? key, required this.videoData}) : super(key: key);
  final VideoPost videoData;

  @override
  State<VideoFeedScreenNew> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreenNew> {
  final controller = Get.put(VideoFeedController());
  final PageController _pageController = PageController();
  final RxInt currentIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _setupInitialVideo();
  }

  void _setupInitialVideo() {
    // Add clicked video first
    controller.videos.add(widget.videoData);
    controller.fetchVideos(); // Load API videos after that
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final videos = controller.videos;

          if (videos.isEmpty && controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) {
              currentIndex.value = index;

              // Pagination trigger
              if (index == videos.length - 2 && controller.hasMore.value) {
                controller.fetchVideos(loadMore: true);
              }
            },
            itemBuilder: (context, index) {
              final video = videos[index];

              // 🟢 No Obx here
              return VideoPlayerItem(
                video: video,
                isActive: currentIndex.value == index,
              );
            },
          );
        }),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final videos = controller.videos;
          if (videos.isEmpty && controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
        
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) {
              currentIndex.value = index;
              // Pagination trigger
              if (index == videos.length - 2 && controller.hasMore.value) {
                controller.fetchVideos(loadMore: true);
              }
            },
            itemBuilder: (context, index) {
              final video = videos[index];

              return Obx(() => VideoPlayerItem(
                video: video,
                isActive: currentIndex.value == index,
              ));
            },
          );
        }),
      ),
    );
  }
}
/*
*   return  PostFeedAutoPlayVideoCard(
                videoItem: ShortFeedItem(
                    videoId: video.id,
                    likesCount: video.likes_count,
                    commentsCount: video.comments_count,
                    repostCount: video.repost_count,
                    sharesCount: 0,
                    viewsCount: video.views_count,

                    metadata: VideoItemMetadata(
                        addedAt: video.createdAt.toString(),
                        source: "personalized",
                        watchedBefore: false),
                    video: VideoData(
                        id: video.id,
                        type: video.type,
                        title: video.title,
                        description: video.subTitle,
                        videoUrl: video.videoUrl,
                        coverUrl: video.thumbnail,
                        // videoUrl: video.videoUrl,
                        // coverUrl: video.thumbnail,
                        createdAt: video.createdAt.toString(),
                        stats: Stats(
                            comments: video.comments_count,
                            likes: video.likes_count,
                            shares: 0,
                            repost_count: video.repost_count,
                            views: video.views_count)),
                    interactions: Interactions(
                        isBookmarked: false, isFollowing: false, isLiked: false)),
                globalMuteNotifier: ValueNotifier(false),
                videoType: VideoType.videoFeed,
                onTapOption: () {
                  // openBlockSelectionDialog(
                  //     context: context,
                  //     reportType: 'VIDEO_POST',
                  //     userId: video?.video?.userId ?? '',
                  //     contentId: videoData?.video?.id ?? '',
                  //     userBlockVoidCallback: () async {
                  //       await Get.find<VideoController>().userBlocked(
                  //         videoType: VideoType.videoFeed,
                  //         otherUserId: videoData?.video?.userId ?? '',
                  //       );
                  //     },
                  //     reportCallback: (params) {
                  //       Get.find<VideoController>().videoPostReport(
                  //           videoId: videoData?.video?.id ?? '',
                  //           videoType: VideoType.videoFeed,
                  //           params: params);
                  //     });
                },
              );*/

/*
class VideoFeedScreenNew extends StatefulWidget {
  const VideoFeedScreenNew({Key? key, required this.videoData})
      : super(key: key);
  final ShortFeedItem videoData;

  @override
  State<VideoFeedScreenNew> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreenNew> {
  final controller = Get.put(VideoFeedController());
  final PageController _pageController = PageController();
  final RxInt currentIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    controller.fetchVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final videos = controller.videos;
          if (videos.isEmpty && controller.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) {
              currentIndex.value = index;
              if (index == videos.length - 2 && controller.hasMore.value) {
                controller.fetchVideos(loadMore: true);
              }
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return Obx(() => VideoPlayerItem(
                    video: video,
                    isActive: currentIndex.value == index,
                  ));
            },
          );
        }),
      ),
    );
  }
}
*/
