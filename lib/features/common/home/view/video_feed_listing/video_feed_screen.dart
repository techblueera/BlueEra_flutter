import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_feed_controller.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_player_item.dart';

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
