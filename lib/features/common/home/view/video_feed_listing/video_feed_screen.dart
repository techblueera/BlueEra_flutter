import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_feed_controller.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_player_item.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import your other files: VideoFeedController, FeedController, VideoPlayerItem, etc.

class VideoFeedScreen extends StatefulWidget {
  final VideoPost videoData; // Assuming VideoPost is your model
  const VideoFeedScreen({super.key, required this.videoData});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  // Use 'tag' if you want separate feed instances, otherwise standard put is fine
  final controller = Get.put(VideoFeedController());
  final feedController = Get.put(FeedController());
  final PageController _pageController = PageController();

  // Local state for the UI index (faster than controller updates for animations)
  final RxInt currentIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _setupInitialVideo();
  }

  void _setupInitialVideo() {
    // Reset controller state for fresh navigation
    controller.reset();

    // Insert the tapped video first so it shows immediately at index 0
    controller.videos.add(widget.videoData);

    // Fetch remaining videos from API
    controller.fetchVideos(feedId: widget.videoData.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 3. REMOVED Obx() from here. Don't rebuild the whole PageView on change.
      body: SafeArea(
        child: Obx(() {
          if (controller.videos.isEmpty && controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.videos.isEmpty) {
            return const SizedBox.shrink();
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: controller.videos.length,
            onPageChanged: (index) {
              currentIndex.value = index;

              controller.updateCurrentIndex(index);

              // Pagination — trigger when 3 items from end
              if (index >= controller.videos.length - 3 &&
                  controller.hasMore.value &&
                  !controller.isLoadingMore.value) {
                controller.fetchVideos(loadMore: true, feedId: '');
              }
            },
            itemBuilder: (context, index) {
              final video = controller.videos[index];

              // 4. Wrap ONLY the item in Obx to check 'isActive'.
              // This isolates the rebuild to just this specific video cell.
              return Obx(() {
                bool isActive = currentIndex.value == index;

                return VideoPlayerItem(
                  // 5. Key is CRITICAL for PageView stability
                  key: ValueKey(video.id),
                  video: video,
                  isActive: isActive,
                  onLikeToggle: () {
                    feedController.postLikeDislike(
                      postId: video.id,
                      type: PostType.all,
                    );
                    controller.toggleLike(index);
                  },
                  onCommentTap: () {
                    onCommentPressed(context, video);
                  },
                );
              });
            },
          );
        }),
      ),
    );
  }

  void onCommentPressed(BuildContext context, VideoPost _post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: CommentBottomSheet(
            id: _post.id,
            totalComments: _post.comments_count,
            commentType: CommentType.post,
            onNewCommentCount: (int newCommentCount) {
              feedController.updateCommentCount(
                  postId: _post.id,
                  type: PostType.all,
                  newCommentCount: newCommentCount);
            }),
      ),
    );
  }
}
