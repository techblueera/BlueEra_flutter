import 'dart:async';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/dummy_model/media_model.dart';
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
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/native_ad_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final FeedController feedController = Get.put(FeedController());
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  static const int postsPerAd = 9;
  static const int cycleSize = postsPerAd + 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
    });

    // Only add scroll listener if this is an individual page (not in parent scroll)
    if (!widget.isInParentScroll) {
      _scrollController.addListener(_scrollListener);
    }

    /// forcefully we are calling api due to page is already loaded but we want to call api due to some new post is added by us
    ever(Get.find<NavigationHelperController>().shouldRefreshBottomBar, (shouldRefresh) {
      if (shouldRefresh == true) {
        fetchPostData(isInitialLoad: true, refresh: true, id: widget.id);
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value = false;
      }
    });

  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 200; // 100px threshold

    if (isAtBottom) {
      // Trigger pagination for individual page
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

  void fetchPostData({bool isInitialLoad = false, bool refresh = false, String? id, String? query}) {
    feedController.getPostsByType(
      widget.postFilterType,
      isInitialLoad: isInitialLoad,
      refresh: refresh,
      id: id,
      query: query
    );
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
    int adCount = postsLength ~/ postsPerAd; // how many ads will fit
    int totalItems = postsLength + adCount;

    // Add loading indicator if there's more data
    if (widget.postFilterType != PostType.saved &&
        feedController.isTargetHasMoreData.isTrue) {
      totalItems += 1;
    }

    return totalItems;
  }

  Widget _buildListItem(int index, List<Post> posts) {
    // How many ads are inserted before this index
    int adCountBeforeIndex = (index / cycleSize).floor();

    // The adjusted post index
    int postIndex = index - adCountBeforeIndex;

    final String? adUnitId = getNativeAdUnitId();

    // Show ad after every 9 posts → ad goes at index 9, 19, 29...
    if (Platform.isAndroid && adUnitId != null &&
        adUnitId.isNotEmpty &&
        (index + 1) % cycleSize == 0 &&
        postIndex < posts.length) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: SizeConfig.size370,
          maxHeight: SizeConfig.size450,
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: SizeConfig.paddingXS,
            left: SizeConfig.paddingXS,
            right: SizeConfig.paddingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [AppShadows.cardShadow],
          ),
          child: NativeAdWidget(adUnitId: adUnitId),
        ),
      );
    }

    // Loader at the end
    if (postIndex >= posts.length) {
      return staggeredDotsWaveLoading();
    }

    // Return the actual post
    return FeedCard(
      post: posts[postIndex],
      index: postIndex,
      postFilteredType: widget.postFilterType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (feedController.isLoading.isFalse) {
        if (feedController.postsResponse.value.status == Status.COMPLETE ||
            widget.postFilterType == PostType.saved) {
          List<Post> posts = feedController.getListByType(widget.postFilterType);

          if (posts.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                message: widget.postFilterType == PostType.saved
                    ? 'No post is in saved.'
                    : 'No post available.',
              ),
            );
          }

          // 🔹 Build listView once
          final listView = ListView.builder(
            controller: widget.isInParentScroll ? null : _scrollController,
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
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
          );

          // 🔹 Only wrap with RefreshIndicator if headerOffset == 0
          final content =
          RefreshIndicator(
            notificationPredicate: (notification) {
              return Get.find<HomeScreenController>().headerOffset.value == 0.0 &&
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
            child: listView,
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

}

class PostData {
  final int id;
  final String? title;
  final String? message;
  final FeedType? type;
  final int? authorId;
  final List<Media>? media;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalLikes;
  final int totalComments;
  final int totalReposts;
  final bool isLike;
  final String totalViews;

  PostData({
    required this.id,
    this.title,
    this.message,
    this.type,
    this.authorId,
    this.media,
    this.createdAt,
    this.updatedAt,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalReposts = 0,
    this.totalViews = "0",
    this.isLike = false,
  });

  factory PostData.fromJson(Map<String, dynamic> json) => PostData(
    id: json['id'] ?? 0,
    title: json['title'],
    message: json['message'],
    type: json['type'],
    authorId: json['author_id'],
    media: (json['media'] as List<dynamic>?)
        ?.map((e) => Media.fromJson(e))
        .toList(),
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    totalLikes: json['total_likes'] ?? 0,
    totalComments: json['total_comments'] ?? 0,
    totalReposts: json['total_reposts'] ?? 0,
    totalViews: json['total_views'] ?? "0",
    isLike: json['is_like'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'author_id': authorId,
    'media': media?.map((e) => e.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'total_likes': totalLikes,
    'total_comments': totalComments,
    'total_reposts': totalReposts,
    'total_views': totalViews,
    'is_like': isLike,
  };
}
