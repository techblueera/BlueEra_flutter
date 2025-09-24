import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
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
import 'package:cached_network_image/cached_network_image.dart';

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
      // appBar: CommonBackAppBar(
      //   title: "Home Feed",
      // ),
      body: Obx(() {
        final apiResponse = _controller.feedResponse.value;
        if (_controller.paginationBatches.isEmpty)
        /*if (apiResponse.status == Status.LOADING &&
            _controller.paginationBatches.isEmpty &&
            _controller.videoItems.isEmpty)*/
        {
          return const Center(child: CircularProgressIndicator());
        } else if (apiResponse.status == Status.ERROR) {
          return Center(child: CustomText("Error: ${apiResponse.message}"));
        } else {
          if (_controller.paginationBatches.isEmpty) {
            return Center(child: CustomText("No Data found"));
          }

          return RefreshIndicator(
            onRefresh: () => _controller.getFeed(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _controller.paginationBatches.length +
                  // _controller.videoItems.length +
                  (_controller.isLoading.value ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index == _controller.paginationBatches.length
                    ) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final batch = _controller.paginationBatches[index];
                return _buildBatchSection(batch, index);

              },
            ),
          );
        }
      }),
    );
  }

  Widget _buildBatchSection(PaginationBatch batch, int batchIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Posts slider (if there are any posts)
        if (batch.posts.isNotEmpty)
          _buildContentSlider(
            "message_post",
            batch.posts,
          ),
        (batch.videos.isNotEmpty)
            ? _buildContentSlider(
                "long_video",
                batch.videos,
              )
            : SizedBox.shrink(),
        // // Shorts slider (if there are any shorts)
        if (batch.shorts.isNotEmpty)
          _buildContentSlider(
            "short_video",
            batch.shorts,
          ),
      ],
    );
  }

  Widget _buildContentSlider(
    String title,
    List<Post> items,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title == 'message_post')
          Container(
            padding: EdgeInsets.only(left: SizeConfig.size15),
            height: SizeConfig.size450,
            child: PageView.builder(
              // shrinkWrap: true,
              scrollDirection: Axis.horizontal,

              controller: PageController(
                  viewportFraction: items
                              .where((data) => data.type == "message_post")
                              .length ==
                          1
                      ? 1
                      : 0.87),
              itemCount:
                  items.where((data) => data.type == "message_post").length,
              padEnds: false,
              itemBuilder: (context, index) {
                final item = items[index];
                // Return appropriate widget based on item type
                if (item.type == 'message_post') {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: SizeConfig.size15,
                      top: SizeConfig
                          .size15,
                    ),
                    child: Container(
                        width: Get.width,
                        child: _buildPostItemCard(item, index)),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        if (title == "long_video" &&
            (items.where((data) => data.type == "long_video").isNotEmpty))
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10,
            ),
            itemCount: items.where((data) => data.type == "long_video").length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(
                  top: SizeConfig.size10,
                ),
                child: _buildVideoItem(item),
              );

              return const SizedBox.shrink();
            },
          ),
        if (title == 'short_video')
          Container(
            padding: EdgeInsets.only(left: SizeConfig.size12),
            height: SizeConfig.size250,
            child: ListView.builder(
              // shrinkWrap: true,
              scrollDirection: Axis.horizontal,

              itemCount:
                  items.where((data) => data.type == "short_video").length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.type == 'short_video') {
                  return Padding(
                    padding: EdgeInsets.only(left: 0),
                    child: _buildShortVideoItemCard(item, index),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPostItemCard(Post post, int postIndex) {
    return Container(
      padding: EdgeInsets.only(right: SizeConfig.size20),
      child: FeedCard(
        post: post,
        index: postIndex,
        postFilteredType: PostType.all,
        horizontalPadding: 0,
      ),
    );
  }

  Widget _buildVideoItem(Post video) {
    ShortFeedItem shortFeedItem = ShortFeedItem(
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
            duration: video.duration,
            stats: Stats(
                comments: video.commentsCount,
                likes: video.likesCount,
                shares: video.sharesCount,
                views: video.viewsCount)),
        interactions: Interactions(
            isBookmarked: false, isFollowing: false, isLiked: false));

    return AutoPlayVideoCard(
      videoItem: shortFeedItem,
      globalMuteNotifier: ValueNotifier(false),
      videoType: VideoType.videoFeed,
      onTapOption: () {
        openBlockSelectionDialog(
            context: context,
            reportType: 'VIDEO_POST',
            userId: userId,
            contentId: shortFeedItem.videoId ?? '',
            userBlockVoidCallback: () async {
              await Get.find<VideoController>().userBlocked(
                videoType: VideoType.videoFeed,
                otherUserId: shortFeedItem.author?.id ?? '',
              );
            },
            reportCallback: (params) {
              Get.find<VideoController>().videoPostReport(
                  videoId: shortFeedItem.videoId ?? '',
                  videoType: VideoType.videoFeed,
                  params: params);
            });
      },
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video header with type indicator
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const CustomText(
                    "Video",
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Video thumbnail
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: video.thumbnail ?? '',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  height: 200,
                  width: double.infinity,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  height: 200,
                  width: double.infinity,
                  child: const Icon(Icons.error),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Video content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video title
                if (video.title != null)
                  CustomText(
                    video.title!,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                // Author info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: video.user?.profileImage ?? "",
                        height: 30,
                        width: 30,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          height: 30,
                          width: 30,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          height: 30,
                          width: 30,
                          child: const Icon(Icons.person, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        video.user?.name,
                        fontSize: 14,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Video stats
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(Icons.visibility_outlined,
                        video.viewsCount?.toString() ?? '0'),
                    _buildStatItem(Icons.favorite_outline,
                        video.likesCount?.toString() ?? '0'),
                    _buildStatItem(Icons.comment_outlined,
                        video.commentsCount?.toString() ?? '0'),
                    _buildStatItem(Icons.share_outlined,
                        video.sharesCount.toString() ?? '0'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortVideoItemCard(Post shortVideo, int index) {
    ShortFeedItem shortFeedItem = ShortFeedItem(
        author: Author(
          name: shortVideo.user?.name,
          username: shortVideo.user?.username,
          designation: shortVideo.user?.designation,
          profileImage: shortVideo.user?.profileImage,
          accountType: shortVideo.user?.accountType,
          id: shortVideo.user?.id,
        ),
        metadata: VideoItemMetadata(
            addedAt: shortVideo.createdAt.toString(),
            source: "personalized",
            watchedBefore: false),
        video: VideoData(
            id: "",
            userId: shortVideo.user?.id,
            type: "short",
            title: shortVideo.title,
            description: shortVideo.message,
            videoUrl: shortVideo.videoUrl,
            coverUrl: shortVideo.thumbnail,
            duration: shortVideo.duration,
            stats: Stats(
                comments: shortVideo.commentsCount,
                likes: shortVideo.likesCount,
                shares: shortVideo.sharesCount,
                views: shortVideo.viewsCount)),
        interactions: Interactions(
            isBookmarked: false, isFollowing: false, isLiked: false));
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteHelper.getShortsPlayerScreenRoute(),
          arguments: {
            ApiKeys.shorts: Shorts.latest,
            ApiKeys.videoItem: "",
            ApiKeys.initialIndex: index
          },
        );
      },
      child: Padding(
        padding: EdgeInsets.only(right: SizeConfig.size10),
        child: ClipRRect(
          borderRadius: (BorderRadius.circular(12)),
          child: SingleShortStructure(
            shorts: Shorts.latest,
            allLoadedShorts: [shortFeedItem],
            initialIndex: index,
            shortItem: shortFeedItem,
            withBackground: true,
            imageWidth: 170,
            imageHeight: 250,
          ),
        ),
      ),
    );

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Short video thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: shortVideo.thumbnail ?? '',
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    height: 300,
                    width: double.infinity,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    height: 300,
                    width: double.infinity,
                    child: const Icon(Icons.error),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Short video content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: shortVideo.user?.profileImage ?? "",
                        height: 24,
                        width: 24,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          height: 24,
                          width: 24,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          height: 24,
                          width: 24,
                          child: const Icon(Icons.person, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        shortVideo.user?.name,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Video stats
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(Icons.favorite_outline,
                        /* shortVideo.stats?.likes?.toString() ?? */ '0'),
                    _buildStatItem(Icons.visibility_outlined,
                        /*shortVideo.stats?.views?.toString() ?? */ '0'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        CustomText(
          count,
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ],
    );
  }
}
