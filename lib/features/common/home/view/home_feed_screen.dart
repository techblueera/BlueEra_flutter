import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/home/controller/home_feed_controller.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({Key? key}) : super(key: key);

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final HomeFeedController _controller = Get.put(HomeFeedController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.handleScrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final apiResponse = _controller.feedResponse.value;
          if (apiResponse.status == Status.LOADING &&
              _controller.mixedFeed.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (apiResponse.status == Status.ERROR) {
            return Center(child: CustomText("Error: ${apiResponse.message}"));
          } else {
            if (_controller.mixedFeed.isEmpty) {
              return Center(child: CustomText("No Data found"));
            }

            return RefreshIndicator(
              onRefresh: () => _controller.getFeed(refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _controller.mixedFeed.length,
                padding: EdgeInsets.only(
                    bottom: kBottomNavigationBarHeight + SizeConfig.size50),
                itemBuilder: (context, index) {
                  final item = _controller.mixedFeed[index];

                  if (item.type ==
                      "message_post" /*||item.type=="poll_post"*/) {
                    return FeedCard(
                      post: item,
                      index: index,
                      postFilteredType: PostType.all,
                    );
                  }
                  if (item.type == "long_video") {
                    ShortFeedItem videoData = getVideoData(item);

                    return Padding(
                      padding:  EdgeInsets.symmetric(),
                      child: AutoPlayVideoCard(
                        videoItem: videoData,
                        globalMuteNotifier: ValueNotifier(false),
                        videoType: VideoType.videoFeed,
                        onTapOption: () {
                          openBlockSelectionDialog(
                              context: context,
                              reportType: 'VIDEO_POST',
                              userId: videoData.video?.userId ?? '',
                              contentId: videoData.video?.id ?? '',
                              userBlockVoidCallback: () async {
                                await Get.find<VideoController>().userBlocked(
                                  videoType: VideoType.videoFeed,
                                  otherUserId: videoData.video?.userId ?? '',
                                );
                              },
                              reportCallback: (params) {
                                Get.find<VideoController>().videoPostReport(
                                    videoId: videoData.video?.id ?? '',
                                    videoType: VideoType.videoFeed,
                                    params: params);
                              });
                        },
                      ),
                    );
                  }
                  // 🔹 Check if this is a short_video group (pair of 2)
                  if (item.type == "short_video") {
                    // Only process if index is even (avoid duplicates)
                    if (index % 2 == 0) {
                      final pair = _controller.mixedFeed
                          .skip(index)
                          .take(2) // ✅ only 2 reels
                          .where((e) => e.type == "short_video")
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: pair.length,
                          itemBuilder: (context, i) {
                            final video = pair[i];

                            ShortFeedItem reelData = getVideoData(video);

                            return ClipRRect(
                              borderRadius: (BorderRadius.circular(12)),
                              child: SingleShortStructure(
                                shorts: Shorts.latest,
                                allLoadedShorts: [reelData],
                                initialIndex: index,
                                shortItem: reelData,
                                withBackground: true,
                                // imageWidth: 170,
                                imageHeight: 250,
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();

                      // Skip duplicate when index is odd
                    }
                  }
                  return const SizedBox.shrink();

                  return ListTile(
                    title: CustomText(item.type),
                    subtitle: CustomText(""),
                  );
                },
              ),
            );
            //
            // return RefreshIndicator(
            //   onRefresh: () => _controller.getFeed(refresh: true),
            //   child: ListView.builder(
            //     controller: _scrollController,
            //     physics: const AlwaysScrollableScrollPhysics(),
            //     itemCount: _controller.mixedFeed.length + 1, // +1 for loading indicator
            //     itemBuilder: (context, index) {
            //       // Show loading indicator at the end
            //       if (index == _controller.mixedFeed.length) {
            //         return _controller.isLoading.value
            //             ? const Padding(
            //           padding: EdgeInsets.all(16.0),
            //           child: Center(child: CircularProgressIndicator()),
            //         )
            //             : const SizedBox.shrink();
            //       }
            //
            //       // Get the current post
            //       final post = _controller.mixedFeed[index];
            //
            //       // Every 5th item, show a horizontal section
            //       if (index > 0 && index % 5 == 0) {
            //         // Determine which horizontal section to show based on the index
            //         final sectionType = (index ~/ 5) % 3;
            //
            //         if (sectionType == 0 && _controller.shortReels.isNotEmpty) {
            //           // Show short reels horizontal section
            //           return _buildShortReelsSection();
            //         } else if (sectionType == 1 && _controller.photoPosts.isNotEmpty) {
            //           // Show photo posts horizontal section
            //           return _buildPhotoPostsSection();
            //         } else if (sectionType == 2 && _controller.videoPosts.isNotEmpty) {
            //           // Show video posts horizontal section
            //           return _buildVideoHorizontalSection();
            //         }
            //       }
            //
            //       // Every 10th item, show an ad if available
            //       if (index > 0 && index % 10 == 0 && _controller.adPosts.isNotEmpty) {
            //         return _buildAdCard(_controller.adPosts[index % _controller.adPosts.length]);
            //       }
            //
            //       // Display the post based on its type
            //       return _buildPostItem(post, index);
            //     },
            //   ),
            // );
          }
        }),
      ),
    );
  }

  ShortFeedItem getVideoData(Post video) {
    return ShortFeedItem(
        videoId: video.id,
        author: Author(
          name: video.user?.name,
          username: video.user?.username,
          designation: video.user?.designation,
          profileImage: video.user?.profileImage,
          accountType: video.user?.accountType,
          id: video.user?.id,
        ),

        metadata: VideoItemMetadata(
            addedAt: video.createdAt.toString(),
            source: "personalized",
            watchedBefore: false),
        video: VideoData(
            id: "",
            userId: video.user?.id,
            type: "long_video",
            title: video.title,
            description: video.message,
            videoUrl: video.videoUrl,
            coverUrl: video.thumbnail,
            createdAt: video.createdAt.toString(),
            duration: video.duration,
            stats: Stats(
                comments: video.commentsCount,
                likes: video.likesCount,
                shares: video.sharesCount,
                views: video.viewsCount)),
        interactions: Interactions(
            isBookmarked: false, isFollowing: false, isLiked: false));
  }
}

class ShortVideoWidget extends StatelessWidget {
  final Post item;

  const ShortVideoWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Image.network(item.thumbnail ?? "",
              fit: BoxFit.cover, height: 180, width: double.infinity),
          CustomText(item.type, fontWeight: FontWeight.bold)
        ],
      ),
    );
  }
}

class ProductWidget extends StatelessWidget {
  final Post item;

  const ProductWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Image.network(item.thumbnail ?? "", height: 120, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomText(item.type, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
