import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/home/view/widget/symbol_story_row.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

DateTime? lastHomeFetchTime;
// Define the threshold (e.g., 5 seconds)
final Duration fetchThreshold = const Duration(seconds: 90);

class HomeFeedScreenNew extends StatefulWidget {
  final PostType postFilterType;
  final String? id;
  final String? query;
  final Function(bool)? onHeaderVisibilityChanged;
  final double? headerHeight;
  final bool isInParentScroll; // Flag to indicate if used in parent scroll view

  const HomeFeedScreenNew({
    super.key,
    required this.postFilterType,
    this.id,
    this.query,
    this.onHeaderVisibilityChanged,
    this.headerHeight,
    this.isInParentScroll = false, // Default to false for individual page
  });

  @override
  State<HomeFeedScreenNew> createState() => _HomeFeedScreenNewState();
}

class _HomeFeedScreenNewState extends State<HomeFeedScreenNew> {
  final FeedController feedController = Get.put(FeedController());
  final ScrollController _scrollController = ScrollController();
  late ShortsController? shortsController;

  var inventoryController = Get.isRegistered<InventoryController>()
      ? Get.find<InventoryController>()
      : Get.put(InventoryController());

  var homeScreenController = Get.isRegistered<HomeScreenController>()
      ? Get.find<HomeScreenController>()
      : Get.put(HomeScreenController());

  final viewPersonalDetailsController =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  void _guardedFetchData({bool refreshFlag = false}) {
    final currentTime = DateTime.now();

    if (lastHomeFetchTime != null &&
        currentTime.difference(lastHomeFetchTime!) < fetchThreshold) {
      // Too soon! Ignore the request.
      debugPrint(
          "API call ignored: executed less than ${fetchThreshold.inSeconds}s ago.");
      return;
    }

    // Update the timestamp and execute
    lastHomeFetchTime = currentTime;
    fetchPostData(refreshFlag: refreshFlag);
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ShortsController>()) {
      shortsController = Get.find<ShortsController>();
    } else {
      shortsController = Get.put(ShortsController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardedFetchData(refreshFlag: true); // Guarded call
      // fetchPostData(refreshFlag: true);
      _scrollController.addListener(_scrollListener);

      /// forcefully we are calling api due to page is already loaded but we want to call api due to some new post is added by us
      ever(Get.find<NavigationHelperController>().shouldRefreshBottomBar,
          (shouldRefresh) {
        if (shouldRefresh == true) {
          _guardedFetchData(refreshFlag: true); // Guarded call
          // fetchPostData(refreshFlag: true);
          Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
              false;
        }
      });
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      feedController.handleScrollToBottomNew();
    }
  }

  // this will if changes in sort by cause page is already loaded
  @override
  void didUpdateWidget(covariant HomeFeedScreenNew oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// this is the case when post api is calling when sort by changed
    if (oldWidget.postFilterType != widget.postFilterType) {
      fetchPostData();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  fetchPostData({bool? refreshFlag}) async {
    await feedController.getFeed(refresh: refreshFlag ?? false);
  }

  List<FeedBlock> _buildBlocks(List<Post> items) {
    final List<FeedBlock> blocks = [];
    // final Set<String> gridTypes = {'image_post', 'short_video'};

    List<Post> buffer = [];

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        // If only 1 item in buffer we still show it as a single full-width card
        if (buffer.length == 1) {
          blocks.add(FeedBlock(isGrid: false, items: [buffer.first]));
        } else {
          blocks.add(FeedBlock(isGrid: true, items: List.from(buffer)));
        }
        buffer.clear();
      }
    }

    for (final item in items) {
      flushBuffer();
      blocks.add(FeedBlock(isGrid: false, items: [item]));
    }
    // end: flush remaining buffer
    flushBuffer();
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // if (feedController.isLoadingHome.isFalse) {
      if (feedController.feedResponse.value.status == Status.COMPLETE ||
          widget.postFilterType == PostType.saved) {
        List<Post> posts = feedController.allPosts;

        if (posts.isEmpty) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: Get.height / 10),
                    child: EmptyStateWidget(
                      message: widget.postFilterType == PostType.saved
                          ? 'No post is in saved.'
                          : 'No post available.',
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        final blocks = _buildBlocks(posts);
        final bool showStories = widget.postFilterType == PostType.all;
        final listView = ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          // 1. Set padding to zero if you want it flush, or keep only what is necessary
          padding: EdgeInsets.zero,
          itemCount: blocks.length + (showStories ? 1 : 0),
          shrinkWrap: widget.isInParentScroll,
          physics: widget.isInParentScroll
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, indexFeed) {
            if (showStories && indexFeed == 0) {
              return const SymbolStoryRow();
            }

            int index = showStories ? indexFeed - 1 : indexFeed;
            final block = blocks[index];
            final item = block.items.first;

            final type = item.type?.toLowerCase();
            if (type == "message_post" || type == "poll_post") {
              trackPostView(item.id);

              // 2. Removed the wrapping Padding widget entirely to eliminate extra space.
              // Use FeedCard's internal padding properties instead.
              return FeedCard(
                post: item,
                index: index,
                postFilteredType: PostType.all,
                bottomPadding: 0,
                horizontalPadding: 0, // Set to 0 to remove side gaps
                isRepost: false,
              );
            }
            return const SizedBox.shrink();
          },
          // separatorBuilder: (BuildContext context, int index) {
          //   // 3. Cleaned up the separator - removing the redundant return and container padding
          //   return Divider(
          //     color: AppColors.whiteE5,
          //     thickness: 1.5,
          //     height: 1, // Ensures the divider itself doesn't add vertical height
          //     indent: 0,
          //     endIndent: 0,
          //   );
          // },
        );
        /*    // 🔹 Build listView once
        final listView = ListView.separated(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding:
              EdgeInsets.only(top: SizeConfig.size2, bottom: SizeConfig.size80),
          itemCount: blocks.length + (showStories ? 1 : 0),
          shrinkWrap: widget.isInParentScroll,
          physics: widget.isInParentScroll
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, indexFeed) {
            // First item: story row (scrolls with feed)
            if (showStories && indexFeed == 0) {
              return const SymbolStoryRow();
            }
            int index = showStories ? indexFeed - 1 : indexFeed;
            final block = blocks[index];
            final item = block.items.first;
            if (item.type?.toLowerCase() == "message_post" ||
                item.type?.toLowerCase() == "poll_post") {
              trackPostView(item.id);
              // widget.post?.media_types?.firstOrNull == "video/mp4"

              return Padding(
                // padding: EdgeInsetsGeometry.zero,
                padding: EdgeInsets.only(
                    left: item.type?.toLowerCase() == "poll_post"
                        ? SizeConfig.size5
                        : SizeConfig.size1,
                    right: item.type?.toLowerCase() == "poll_post"
                        ? 0
                        : SizeConfig.size2,
                    top: item.type?.toLowerCase() == "poll_post"
                        ? SizeConfig.size10
                        : 1,
                    bottom: item.type?.toLowerCase() == "message_post" ? 0 : 0),
                child: FeedCard(
                  post: item,
                  index: index,
                  postFilteredType: PostType.all,
                  bottomPadding: 0,
                  horizontalPadding: 10,
                  isRepost: false,
                ),
              );
            }
            return const SizedBox.shrink(); // skip if no card
          },
          separatorBuilder: (BuildContext context, int index) {
            return Container(height: 1,color: Colors.red,padding: EdgeInsets.zero,);
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
              child: Divider(
                color: AppColors.whiteE5,
                thickness: 1.5,
              ),
            );
          },
        );*/

        // 🔹 Only wrap with RefreshIndicator if headerOffset == 0
        final content = RefreshIndicator(
          notificationPredicate: (notification) {
            Get.isRegistered<HomeScreenController>()
                ? Get.find<HomeScreenController>()
                : Get.put(HomeScreenController());
            return Get.find<HomeScreenController>().headerOffset.value == 0.0 &&
                notification.metrics.pixels <=
                    notification.metrics.minScrollExtent;
          },
          onRefresh: () async {
            if (Get.find<HomeScreenController>().headerOffset.value != 0.0) {
              return;
            }

            // just call your function, then return a completed Future
            fetchPostData(refreshFlag: true);

            return Future.value();
          },
          child: listView,
        );

        if (widget.postFilterType == PostType.all ||
            widget.postFilterType == PostType.saved) {
          return setupScrollVisibilityNotification(
            controller: widget.isInParentScroll ? null : _scrollController,
            headerHeight: (widget.headerHeight ?? SizeConfig.size100),
            onVisibilityChanged: (visible, offset) {
              final controller = Get.find<HomeScreenController>();
              controller.headerOffset.value = offset;
              controller.isVisible.value = visible;
              widget.onHeaderVisibilityChanged?.call(visible);
            },
            child: content,
          );
        }

        return content;
      } else if (feedController.feedResponse.value.status == Status.LOADING) {
        return const Center(child: CircularProgressIndicator());
      } else if (feedController.feedResponse.value.status == Status.ERROR) {
        return LoadErrorWidget(
          errorMessage: 'Failed to load posts',
          onRetry: () {
            feedController.isLoadingHome.value = false;
            fetchPostData();
          },
        );
      }
      // } else {
      //   return Center(child: CircularProgressIndicator());
      // }

      return const SizedBox();
    });
  }
}

ShortFeedItem getVideoData(Post video) {
  return ShortFeedItem(
      videoId: video.id,
      likesCount: video.likesCount,
      commentsCount: video.commentsCount,
      repostCount: video.repostCount,
      sharesCount: video.sharesCount,
      viewsCount: video.viewsCount,
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
      channel: video.channel,
      video: VideoData(
          id: video.id,
          userId: video.user?.id,
          type: video.type,
          title: video.title,
          description: video.subTitle,
          videoUrl: video.media?.firstOrNull,
          coverUrl: video.thumbnail,
          // videoUrl: video.videoUrl,
          // coverUrl: video.thumbnail,
          createdAt: video.createdAt.toString(),
          media_height: video.media_height,
          media_width: video.media_width,
          duration: video.duration,
          stats: Stats(
              comments: video.commentsCount,
              likes: video.likesCount,
              shares: video.sharesCount,
              repost_count: video.repostCount,
              views: video.viewsCount)),
      interactions: Interactions(
          isBookmarked: false, isFollowing: false, isLiked: false));
}

class FeedBlock {
  final bool isGrid;
  final List<Post> items;

  FeedBlock({required this.isGrid, required this.items});
}
