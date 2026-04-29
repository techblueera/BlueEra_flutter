import 'dart:async';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/view/feed_shimmer_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/shared/widgets/animated/fade_in_up.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeedScreen extends StatefulWidget {
  final PostType postFilterType;
  final String? id;
  final String? query;
  final Function(bool)? onHeaderVisibilityChanged;
  final double? headerHeight;
  final double? bottomPaddingChannel;
  final double? horizontalPaddingChannel;
  final bool isInParentScroll;

  const FeedScreen({
    super.key,
    required this.postFilterType,
    this.id,
    this.query,
    this.onHeaderVisibilityChanged,
    this.headerHeight,
    this.bottomPaddingChannel,
    this.horizontalPaddingChannel,
    this.isInParentScroll = false,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final feedController = Get.isRegistered<FeedController>()
      ? Get.find<FeedController>()
      : Get.put(FeedController());
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  // 🔹 State to track if "Scroll to Top" button should be visible
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);

      if (!widget.isInParentScroll) {
        _scrollController.addListener(_scrollListener);
      }

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

    // 🔹 1. Handle "Back to Top" button visibility
    // Show button after scrolling down 600 pixels
    bool show = position.pixels > 600;
    if (show != _showBackToTop) {
      setState(() {
        _showBackToTop = show;
      });
    }

    // 🔹 2. Handle Pagination (Existing logic)
    final isAtBottom = position.pixels >= position.maxScrollExtent - 200;
    if (isAtBottom) {
      feedController.handleScrollToBottom(widget.postFilterType);
    }
  }

  // 🔹 Method to animate back to the top
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postFilterType != widget.postFilterType) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
    }
    if (oldWidget.query != widget.query) {
      _onQueryChanged(widget.query);
    }
  }

  void _onQueryChanged(String? newQuery) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
      fetchPostData(isInitialLoad: true, id: widget.id, query: newQuery);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    if (!widget.isInParentScroll) {
      _scrollController.removeListener(_scrollListener);
      _scrollController.dispose();
    }
    super.dispose();
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

  int _calculateItemCount(int postsLength) {
    int totalItems = postsLength;
    if (widget.postFilterType != PostType.saved &&
        feedController.isTargetHasMoreData.isTrue) {
      totalItems += 1;
    }
    return totalItems;
  }

  Widget _buildListItem(int index, List<Post> posts) {
    int postIndex = index;
    if (postIndex >= posts.length) {
      return Obx(() => feedController.isTargetMoreDataLoading.value
          ? staggeredDotsWaveLoading()
          : const SizedBox.shrink());
    }

    return VisibilityDetector(
      key: Key('post_$index'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          trackPostView(posts[postIndex].id);
        }
      },
      child: FeedCard(
        post: posts[postIndex],
        index: postIndex,
        postFilteredType: widget.postFilterType,
        bottomPadding: widget.bottomPaddingChannel,
        horizontalPadding: widget.horizontalPaddingChannel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
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

              final content = RefreshIndicator(
                notificationPredicate: (notification) {
                  return Get.find<HomeScreenController>().headerOffset.value ==
                          0.0 &&
                      notification.metrics.pixels <=
                          notification.metrics.minScrollExtent;
                },
                onRefresh: () async {
                  if (Get.find<HomeScreenController>().headerOffset.value !=
                      0.0) return;
                  fetchPostData(
                      isInitialLoad: true, refresh: true, id: widget.id);
                  return Future.value();
                },
                child: ListView.builder(
                  controller:
                      widget.isInParentScroll ? null : _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                      top: SizeConfig.size2, bottom: SizeConfig.size80),
                  shrinkWrap: widget.isInParentScroll,
                  physics: widget.isInParentScroll
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  itemCount: _calculateItemCount(posts.length),
                  itemBuilder: (context, index) => _buildListItem(index, posts),
                ),
              );

              if (widget.postFilterType == PostType.all ||
                  widget.postFilterType == PostType.saved) {
                return setupScrollVisibilityNotification(
                  controller:
                      widget.isInParentScroll ? null : _scrollController,
                  headerHeight: (widget.headerHeight ?? SizeConfig.size100),
                  onVisibilityChanged: (visible, offset) {
                    final controller = Get.find<HomeScreenController>();
                    const step = 0.25;
                    double newOffset = visible
                        ? (controller.headerOffset.value - step).clamp(0.0, 1.0)
                        : (controller.headerOffset.value + step)
                            .clamp(0.0, 1.0);

                    controller.headerOffset.value = newOffset;
                    controller.isVisible.value = visible;
                    widget.onHeaderVisibilityChanged?.call(visible);
                  },
                  child: content,
                );
              }
              return content;
            } else if (feedController.postsResponse.value.status ==
                Status.ERROR) {
              return LoadErrorWidget(
                errorMessage: 'Failed to load posts',
                onRetry: () {
                  feedController.isLoading.value = true;
                  fetchPostData(
                      isInitialLoad: true, refresh: true, id: widget.id);
                },
              );
            } else {
              return const SizedBox();
            }
          } else {
            return FeedShimmerCard();
          }
        }),

        // 🔹 Floating Action Button Implementation
        if (_showBackToTop && !widget.isInParentScroll)
          Positioned(
            bottom: SizeConfig.size80,
            // Adjust height to avoid overlapping bottom bar
            right: SizeConfig.size10,
            child: FadeInUp(
              // Assuming you use animate_do or similar, otherwise use AnimatedOpacity
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton(
                backgroundColor:AppColors.primaryColor,
                mini: true,
                onPressed: _scrollToTop,
                child: const Icon(Icons.arrow_circle_up, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
/*class FeedScreen extends StatefulWidget {
  final PostType postFilterType;
  final String? id;
  final String? query;
  final Function(bool)? onHeaderVisibilityChanged;
  final double? headerHeight;
  final double? bottomPaddingChannel;
  final double? horizontalPaddingChannel;
  final bool isInParentScroll; // Flag to indicate if used in parent scroll view

  const FeedScreen({
    super.key,
    required this.postFilterType,
    this.id,
    this.query,
    this.onHeaderVisibilityChanged,
    this.headerHeight,
    this.bottomPaddingChannel,
    this.horizontalPaddingChannel,
    this.isInParentScroll = false, // Default to false for individual page
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final feedController = Get.isRegistered<FeedController>()
      ? Get.find<FeedController>()
      : Get.put(FeedController());
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
      ever(Get
          .find<NavigationHelperController>()
          .shouldRefreshBottomBar,
              (shouldRefresh) {
            if (shouldRefresh == true) {
              fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
              Get
                  .find<NavigationHelperController>()
                  .shouldRefreshBottomBar
                  .value =
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

  void fetchPostData({bool isInitialLoad = false,
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
      return Obx(() =>
      feedController.isTargetMoreDataLoading.value
          ? staggeredDotsWaveLoading()
          : const SizedBox.shrink());
    }

    return VisibilityDetector(
      key: Key('post_$index'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.5) {
          trackPostView(posts[postIndex].id);
        }
      },
      child: FeedCard(
        post: posts[postIndex],
        index: postIndex,
        postFilteredType: widget.postFilterType,
        bottomPadding: widget.bottomPaddingChannel,
        horizontalPadding: widget.horizontalPaddingChannel,
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
              return Get
                  .find<HomeScreenController>()
                  .headerOffset
                  .value ==
                  0.0 &&
                  notification.metrics.pixels <=
                      notification.metrics.minScrollExtent;
            },
            onRefresh: () async {
              if (Get
                  .find<HomeScreenController>()
                  .headerOffset
                  .value != 0.0) {
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
        } else {
          return const SizedBox();
        }
      } else {
        return FeedShimmerCard();
      }
    });
  }

}*/
