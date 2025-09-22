import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/feed/widget/feed_action_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/feed/widget/message_post_widget.dart';
import 'package:BlueEra/features/common/home/controller/home_feed_controller.dart';
import 'package:BlueEra/features/common/home/model/home_feed_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
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

        /*if (apiResponse.status == Status.LOADING &&
            _controller.paginationBatches.isEmpty &&
            _controller.videoItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        } else*/ if (apiResponse.status == Status.ERROR) {
          return Center(child: CustomText("Error: ${apiResponse.message}"));
        } else {
          if( _controller.videoItems.isEmpty)
          {
            return Center(child: CustomText("No Data found"));
          }
          return RefreshIndicator(
            onRefresh: () => _controller.getFeed(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _controller.paginationBatches.length +
                  _controller.videoItems.length +
                  (_controller.isLoading.value ? 1 : 0),
              itemBuilder: (context, index) {

                // Show loading indicator at the bottom
                if (index ==
                    _controller.paginationBatches.length +
                        _controller.videoItems.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // Determine if this index is for a batch or a video item
                if (index < _controller.paginationBatches.length) {
                  // This is a batch index - show sliders for posts and shorts
                  final batch = _controller.paginationBatches[index];
                  return _buildBatchSection(batch, index);
                }
                return const SizedBox.shrink();

                /*else {
                  // This is a video item index - show individual video
                  final videoIndex = index - _controller.paginationBatches.length;
                  if (videoIndex < _controller.videoItems.length) {
                    return _buildVideoItem(_controller.videoItems[videoIndex]);
                  } else {
                    return const SizedBox.shrink();
                  }
                }*/
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
          _buildContentSlider("message_post", batch.posts, Colors.blue),

        // // Shorts slider (if there are any shorts)
        // if (batch.shorts.isNotEmpty)
        //   _buildContentSlider("Shorts", batch.shorts, Colors.purple),
      ],
    );
  }

  Widget _buildContentSlider(String title, List<Post> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal list of items
        if (title == "message_post")
          SizedBox(
            height:  500,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                // Return appropriate widget based on item type
                if (item.type == 'message_post') {
                  return _buildPostItemCard(item, index);
                }
                /* else if (item.type == 'short_video') {
                return _buildShortVideoItemCard(item);
              } else {
                return const SizedBox.shrink();
              }*/
                return const SizedBox.shrink();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPostItemCard(Post post, int postIndex) {
    return Container(
      width: Get.width,
      child: FeedCard(
        post: post,
        index: postIndex,
        postFilteredType: PostType.all,
      ),
    );
/*  return  Container(
// height: 400,

    width: Get.width/1.2,

    child: MessagePostWidgetNew(
      horizontalPadding: 10,
      post: post,
      authorSection: () => PostAuthorHeaderNew(
        post: post,
        authorId: post.author.id ?? '0',
        postType: PostType.all,
        // onTapAvatar: _shouldShowProfileNavigation()
        //     ? () => _navigateToProfile(authorId: _post?.authorId ?? '0')
        //     : null,
      ),
      commentView:()=> null,
      // commentView:()=> _onCommentPressed(),
      buildActions: () => PostActionsBarNew(
        post: post,
        isLiked:  false,
        totalLikes: post.stats?.likes ?? 0,
        totalComment: post.stats?.comments ?? 0,
        totalRepost: post.stats?.shares ?? 0,
        isPostAlreadySaved: false,
        onLikeDislikePressed: () {
          // _onLikeDislikePressed();
        },
        onCommentButtonPressed: () {
          // _onCommentPressed();
        },
        onSavedUnSavedButtonPressed: () {
          // _onSavedUnSavedButtonPressed();
        },
        onShareButtonPressed: () async {
          // onShareButtonPressed(_post);
        },
      ),
    ),
  );
    return Container(
      width: 250,
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
          // Post image if available
          if (post.content?.images != null && post.content!.images!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: post.content!.images![0],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  height: 150,
                  width: double.infinity,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  height: 150,
                  width: double.infinity,
                  child: const Icon(Icons.error),
                ),
              ),
            ),

          // Post content
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
                        imageUrl: post.author.avatar,
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
                        post.author.name,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Post subtitle
                if (post.subTitle != null)
                  CustomText(
                    post.subTitle!,
                    fontSize: 14,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Post stats
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(Icons.favorite_outline, post.stats?.likes?.toString() ?? '0'),
                    _buildStatItem(Icons.comment_outlined, post.stats?.comments?.toString() ?? '0'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );*/
  }

  Widget _buildVideoItem(FeedItem video) {
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
                        imageUrl: video.author.avatar,
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
                        video.author.name,
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
                        video.stats?.views?.toString() ?? '0'),
                    _buildStatItem(Icons.favorite_outline,
                        video.stats?.likes?.toString() ?? '0'),
                    _buildStatItem(Icons.comment_outlined,
                        video.stats?.comments?.toString() ?? '0'),
                    _buildStatItem(Icons.share_outlined,
                        video.stats?.shares?.toString() ?? '0'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortVideoItemCard(FeedItem shortVideo) {
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
                        imageUrl: shortVideo.author.avatar,
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
                        shortVideo.author.name,
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
                        shortVideo.stats?.likes?.toString() ?? '0'),
                    _buildStatItem(Icons.visibility_outlined,
                        shortVideo.stats?.views?.toString() ?? '0'),
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
