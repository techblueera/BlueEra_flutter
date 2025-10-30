import 'dart:async';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_shimmer_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedScreen extends StatefulWidget {
  final PostType postFilterType;
  final String? id;
  final String? query;
  final Function(bool)? onHeaderVisibilityChanged;
  final double? headerHeight;
  final bool isInParentScroll; // Flag to indicate if used in parent scroll view

  const FeedScreen({
    super.key,
    required this.postFilterType,
    this.id,
    this.query,
    this.onHeaderVisibilityChanged,
    this.headerHeight,
    this.isInParentScroll = false, // Default to false for individual page
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final feedController = Get.find<FeedController>();
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);

      // Only add scroll listener if this is an individual page (not in parent scroll)
      if (!widget.isInParentScroll) {
        _scrollController.addListener(_scrollListener);
      }

      /// forcefully we are calling api due to page is already loaded but we want to call api due to some new post is added by us
      ever(Get.find<NavigationHelperController>().shouldRefreshBottomBar,
          (shouldRefresh) {
        if (shouldRefresh == true) {
          fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
          Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
              false;
        }
      });
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom =
        position.pixels >= position.maxScrollExtent - 200; // 100px threshold

    if (isAtBottom) {
      feedController.handleScrollToBottom(widget.postFilterType);
    }
  }

  // this will if changes in sort by cause page is already loaded
  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// this is the case when post api is calling when sort by changed
    if (oldWidget.postFilterType != widget.postFilterType) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
    }

    /// this is the case when search query changes
    if (oldWidget.query != widget.query) {
      _onQueryChanged(widget.query);
    }
  }

  void _onQueryChanged(String? newQuery) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
      // call the same method you already use
      fetchPostData(
        isInitialLoad: true,
        id: widget.id,
        query: newQuery,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _searchDebounce?.cancel();
    if (!widget.isInParentScroll) {
      _scrollController.removeListener(_scrollListener);
      _scrollController.dispose();
    }
  }

  void fetchPostData(
      {bool isInitialLoad = false,
      bool refresh = false,
      String? id,
      String? query}) {
    feedController.getPostsByType(widget.postFilterType,
        isInitialLoad: isInitialLoad,
        refresh: refresh,
        id: id,
        query: query,
        screenName: '');
  }

  // Method to be called from parent for pagination
  void loadMore() {
    if (feedController.isTargetHasMoreData.isTrue &&
        feedController.isLoading.isFalse &&
        widget.postFilterType != PostType.saved) {
      fetchPostData(id: widget.id, query: widget.query);
    }
  }

  int _calculateItemCount(int postsLength) {
    int totalItems = postsLength;

    // Add loading indicator if there's more data
    if (widget.postFilterType != PostType.saved &&
        feedController.isTargetHasMoreData.isTrue) {
      totalItems += 1;
    }

    return totalItems;
  }

  Widget _buildListItem(int index, List<Post> posts) {

    int postIndex = index;
    // Loader at the end
    if (postIndex >= posts.length) {
      // Only show loader if pagination is in progress
      return Obx(() => feedController.isTargetMoreDataLoading.value
          ? staggeredDotsWaveLoading()
          : const SizedBox.shrink());
    }

    return VisibilityDetector(
      key: Key('post_$index'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          // Post is at least 50% visible
          trackPostView(posts[postIndex].id);
          print("Post ${posts[postIndex].id} is visible");
          // _callViewApi(post.id); // 👈 Call your view API here
        }
      },
      child: FeedCard(
        post: posts[postIndex],
        index: postIndex,
        postFilteredType: widget.postFilterType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (feedController.isLoading.isFalse) {
        if (feedController.postsResponse.value.status == Status.COMPLETE ||
            widget.postFilterType == PostType.saved) {
          List<Post> posts =
              feedController.getListByType(widget.postFilterType);

          if (posts.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                message: widget.postFilterType == PostType.saved
                    ? 'No post is in saved.'
                    : 'No post available.',
              ),
            );
          }



          // 🔹 Only wrap with RefreshIndicator if headerOffset == 0
          final content = RefreshIndicator(
            notificationPredicate: (notification) {
              return Get.find<HomeScreenController>().headerOffset.value ==
                      0.0 &&
                  notification.metrics.pixels <=
                      notification.metrics.minScrollExtent;
            },
            onRefresh: () async {
              if (Get.find<HomeScreenController>().headerOffset.value != 0.0) {
                return;
              }

              // just call your function, then return a completed Future
              fetchPostData(
                isInitialLoad: true,
                refresh: true,
                id: widget.id,
              );

              return Future.value();
            },
            child: ListView.builder(
              controller: widget.isInParentScroll ? null : _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                  top: SizeConfig.size2, bottom: SizeConfig.size80),
              shrinkWrap: widget.isInParentScroll,
              physics: widget.isInParentScroll
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              itemCount: _calculateItemCount(posts.length),
              itemBuilder: (context, index) {
                return _buildListItem(index, posts);
              },
            ),
          );

          if (widget.postFilterType == PostType.all ||
              widget.postFilterType == PostType.saved) {
            return setupScrollVisibilityNotification(
              controller: widget.isInParentScroll ? null : _scrollController,
              headerHeight: (widget.headerHeight ?? SizeConfig.size100),
              onVisibilityChanged: (visible, offset) {
                final controller = Get.find<HomeScreenController>();
                final currentOffset = controller.headerOffset.value;

                // Linear animation step (same speed up/down)
                const step = 0.25;

                double newOffset = currentOffset;
                if (visible) {
                  // show header
                  newOffset = (currentOffset - step).clamp(0.0, 1.0);
                } else {
                  // hide header
                  newOffset = (currentOffset + step).clamp(0.0, 1.0);
                }

                controller.headerOffset.value = newOffset;
                controller.isVisible.value = visible;
                widget.onHeaderVisibilityChanged?.call(visible);
              },
              child: content,
            );
          }

          return content;
        } else if (feedController.postsResponse.value.status == Status.ERROR) {
          return LoadErrorWidget(
            errorMessage: 'Failed to load posts',
            onRetry: () {
              feedController.isLoading.value = true;
              fetchPostData(
                isInitialLoad: true,
                refresh: true,
                id: widget.id,
              );
            },
          );
        }
      } else {
        return FeedShimmerCard();
      }

      return const SizedBox();
    });
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
