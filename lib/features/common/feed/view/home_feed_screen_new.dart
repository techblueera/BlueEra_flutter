import 'dart:async';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/dummy_model/media_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/block_report_selection_dialog.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/view/feed_shimmer_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_media_carosal_widget.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/native_ad_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  static const int postsPerAd = 9;
  static const int cycleSize = postsPerAd + 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPostData();
      _scrollController.addListener(_scrollListener);
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

  fetchPostData() async {
    await feedController.getFeed();
  }

  int _calculateItemCount(int postsLength) {
    int adCount = postsLength ~/ postsPerAd; // how many ads will fit
    int totalItems = postsLength + adCount;

    // Add loading indicator if there's more data
    if (widget.postFilterType != PostType.saved &&
        feedController.hasMoreData.value) {
      totalItems += 1;
    }

    return totalItems;
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // if (feedController.isLoadingHome.isFalse) {
        if (feedController.feedResponse.value.status == Status.COMPLETE ||
            widget.postFilterType == PostType.saved) {
          List<Post> posts = feedController.allPosts;
          // feedController.getListByType(widget.postFilterType);

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
            controller:  _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
                top: SizeConfig.size2, bottom: SizeConfig.size80),
            shrinkWrap: widget.isInParentScroll,
            physics: widget.isInParentScroll
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            // itemCount: (posts.length),
            itemCount: _calculateItemCount(posts.length),
            itemBuilder: (context, index) {
              return _buildListItem(index, posts);
            },
          );

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
              fetchPostData();

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
        } else if (feedController.feedResponse.value.status == Status.ERROR) {
          return LoadErrorWidget(
            errorMessage: 'Failed to load posts',
            onRetry: () {
              feedController.isLoadingHome.value = true;
              fetchPostData();
            },
          );
        }
   /*   } else {
        return FeedShimmerCard();
      }*/

      return const SizedBox();
    });
  }
  Widget _buildListItem(int index, List<Post> posts) {
    // How many ads are inserted before this index
    int adCountBeforeIndex = (index / cycleSize).floor();

    // The adjusted post index
    int postIndex = index - adCountBeforeIndex;

    final String? adUnitId = getNativeAdUnitId();

    // Show ad after every 9 posts → ad goes at index 9, 19, 29...
    if (Platform.isAndroid &&
        adUnitId != null &&
        adUnitId.isNotEmpty &&
        (index + 1) % cycleSize == 0 &&
        postIndex < posts.length) {
      if (kReleaseMode) {
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
      if (kDebugMode) {
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
            child: Center(child: CustomText("You are in Debug Mode ")),
          ),
        );
      }
    }

   /* // Loader at the end
    // Loader at the end
    if (postIndex >= posts.length) {
      // Only show loader if pagination is in progress
      return Obx(() => feedController.isTargetMoreDataLoading.value
          ? staggeredDotsWaveLoading()
          : const SizedBox.shrink());
    }*/
    // return FeedCard(
    //   post: posts[postIndex],
    //   index: postIndex,
    //   postFilteredType: widget.postFilterType,
    // );
    final item = posts[index];

    if (item.type?.toLowerCase() == "message_post" ||
        item.type?.toLowerCase() == "poll_post") {
      return FeedCard(
        post: item,
        index: index,
        postFilteredType: PostType.all,
      );
    }
    if (item.type == "long_video") {
      logs(("item   ${item.thumbnail}"));
      ShortFeedItem videoData = getVideoData(item);

      return Padding(
        padding: EdgeInsets.symmetric(),
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
        final pair = posts
            .skip(index)
            .take(2) // ✅ only 2 reels
            .where((e) => e.type == "short_video")
            .toList();

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    } // 🔹 Check if this is a short_video group (pair of 2)
    if (item.type == "image_post") {
      // Only process if index is even (avoid duplicates)
      if (index % 2 == 0) {
        final pair = posts
            .skip(index)
            .take(2) // ✅ only 2 reels
            .where((e) => e.type == "image_post")
            .toList();

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: pair.length,
            itemBuilder: (context, i) {
              final imgPostData = pair[i];

              return ClipRRect(
                borderRadius: (BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: imgPostData.subTitle,
                        appBarTitle:
                        AppLocalizations.of(context)!.imageViewer,
                        imageUrls: imgPostData.media??[],
                        initialIndex: index,
                      ),
                    );

                  },
                  child: SizedBox(
                    width: SizeConfig.size220,
                    height: 250,
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: CachedNetworkImage(
                          width: double.infinity,
                          height: double.infinity,
                          // height: widget.imageHeight ?? SizeConfig.size220,
                          fit: BoxFit.cover,
                          imageUrl: imgPostData.media?.firstOrNull ?? "",
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              border:
                              Border.all(color: AppColors.white, width: 1),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: LocalAssets(
                                imagePath: AppIconAssets.blueEraIcon,
                                boxFix: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (imgPostData.subTitle != null &&
                          (imgPostData.subTitle?.isNotEmpty ?? false) &&
                          imgPostData.subTitle?.toLowerCase() != "null")
                        Positioned(
                            bottom: 0,
                            right: 0,
                            left: 0,
                            // right: SizeConfig.size6,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              // padding: EdgeInsets.symmetric(
                              //     vertical: SizeConfig.size2,
                              //     horizontal: SizeConfig.size5),
                              padding: EdgeInsets.only(
                                  bottom: 10,
                                  left: SizeConfig.size10,
                                  right: SizeConfig.size10,
                                  top: 5),

                              decoration: BoxDecoration(
                                  color: AppColors.mainTextColor
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(5.0)),
                              child: CustomText(
                                "${imgPostData.subTitle}",
                                color: AppColors.white,
                                fontSize: SizeConfig.size16,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                                fontFamily: "arialround",
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                    ]),
                  ),
                ),
              );
            },
          ),
        );
      } else {
        return const SizedBox.shrink();

        // Skip duplicate when index is odd
      }
    } else {
      return FeedCard(
        post: posts[postIndex],
        index: postIndex,
        postFilteredType: widget.postFilterType,
      );
    }
    // return  CustomText("Coming soon ${item.type}");
    // Return the actual post
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
            id: video.id,
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
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'])
            : null,
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
