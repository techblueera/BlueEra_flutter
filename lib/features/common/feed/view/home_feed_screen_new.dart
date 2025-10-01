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
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/more/widget/greeting_card_dialog.dart';
import 'package:BlueEra/features/common/reel/widget/auto_play_video_card.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
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
  late ShortsController? shortsController;

  static const int postsPerAd = 9;
  static const int cycleSize = postsPerAd + 1;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ShortsController>()) {
      shortsController = Get.find<ShortsController>();
    } else {
      shortsController = Get.put(ShortsController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPostData(refreshFlag: true);
      _scrollController.addListener(_scrollListener);

      /// forcefully we are calling api due to page is already loaded but we want to call api due to some new post is added by us
      ever(Get.find<NavigationHelperController>().shouldRefreshBottomBar,
          (shouldRefresh) {
        if (shouldRefresh == true) {
          fetchPostData(refreshFlag: true);
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

  List<FeedBlock> _buildBlocks(List<Post> items) {
    final List<FeedBlock> blocks = [];
    final Set<String> gridTypes = {'image_post', 'short_video'};

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
      if (gridTypes.contains(item.type)) {
        buffer.add(item);
        // keep buffering consecutive grid-type items
      } else {
        // encountered a normal item -> flush any grid buffer first
        flushBuffer();
        blocks.add(FeedBlock(isGrid: false, items: [item]));
      }
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
              (Get.find<MoreCardsScreenController>().dayCards.isNotEmpty)
                  ? Padding(
                      padding: EdgeInsets.only(
                          left: SizeConfig.size8,
                          right: SizeConfig.size8,
                          top: SizeConfig.size8),
                      child: GreetingCardDialog(
                          cards:
                              Get.find<MoreCardsScreenController>().dayCards),
                    )
                  : SizedBox.shrink(), // skip if no card

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
        // 🔹 Build listView once
        final listView = ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding:
              EdgeInsets.only(top: SizeConfig.size2, bottom: SizeConfig.size80),
          itemCount: blocks.length,
          shrinkWrap: widget.isInParentScroll,
          physics: widget.isInParentScroll
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, indexFeed) {
            if (indexFeed == 0) {
              if (Get.find<MoreCardsScreenController>().dayCards.isNotEmpty) {
                return Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size8,
                      right: SizeConfig.size8,
                      top: SizeConfig.size8),
                  child: GreetingCardDialog(
                      cards: Get.find<MoreCardsScreenController>().dayCards),
                );
              } else {
                return const SizedBox.shrink(); // skip if no card
              }
            }
            int index=indexFeed-1;
            final block = blocks[index];
            if (block.isGrid) {
              // Render a 4-column grid of thumbnails inside the list
              // We use shrinkWrap + NeverScrollableScrollPhysics so ListView handles scrolling
              return Padding(
                padding: EdgeInsets.only(
                    left: SizeConfig.size8,
                    right: SizeConfig.size8,
                    top: SizeConfig.size10,
                    bottom: SizeConfig.size5),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: block.items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.70,
                    // mainAxisSpacing: 6,
                    // crossAxisSpacing: 6,
                    // childAspectRatio: 1,
                  ),
                  itemBuilder: (c, postIndex) {
                    final imgPostData = block.items[postIndex];
                    if (imgPostData.type == "short_video") {
                      ShortFeedItem reelData = getVideoData(imgPostData);
                   int shortID=    shortsController?.latestShortsPosts
                          .indexWhere((post) =>
                      post.videoId == reelData.video?.id)??0;
                   logs("INDEX======= $shortID");
                      return ClipRRect(
                        borderRadius: (BorderRadius.circular(12)),
                        child: Stack(
                          children: [
                            SingleShortStructure(
                              key: ValueKey(shortID),
                              shorts: Shorts.latest,
                              allLoadedShorts: shortsController?.latestShortsPosts,
                              initialIndex: shortID,
                              shortItem: reelData,
                              withBackground: true,
                              // imageWidth: 170,
                              imageHeight: SizeConfig.size310,
                            ),
                            // total views
                            Positioned(
                              bottom: SizeConfig.size90,
                              top: SizeConfig.size90,
                              left: SizeConfig.size90,
                              right: SizeConfig.size90,
                              child: IgnorePointer(
                                  ignoring: true,
                                  child: LocalAssets(
                                    imagePath: AppIconAssets.playIcon,
                                  )),
                            ),
                          ],
                        ),
                      );
                    }
                    if (imgPostData.type == "image_post") {
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
                                imageUrls: imgPostData.media ?? [],
                                initialIndex: postIndex,
                              ),
                            );
                          },
                          child: SizedBox(
                            width: SizeConfig.size220,
                            height: 300,
                            child: Stack(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(0),
                                child: CachedNetworkImage(
                                  width: double.infinity,
                                  height: 310,
                                  // height: widget.imageHeight ?? SizeConfig.size220,
                                  fit: BoxFit.cover,
                                  imageUrl:
                                      imgPostData.media?.firstOrNull ?? "",
                                  placeholder: (context, str) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: LocalAssets(
                                        imagePath:
                                            AppIconAssets.place_holder_image,
                                        boxFix: BoxFit.fill,
                                      ),
                                    );
                                  },
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    // width: double.infinity,
                                    // height: 310,
                                    width: SizeConfig.size220,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.white, width: 1),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: LocalAssets(
                                        imagePath:
                                            AppIconAssets.place_holder_image,
                                        boxFix: BoxFit.fill,
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
                                      padding: EdgeInsets.only(
                                          bottom: 10,
                                          left: SizeConfig.size10,
                                          right: SizeConfig.size10,
                                          top: 5),
                                      decoration: BoxDecoration(
                                          color: AppColors.mainTextColor
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(5.0)),
                                      child: CustomText(
                                        "${imgPostData.subTitle}",
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w400,
                                        maxLines: 2,
                                        // fontFamily: "arialround",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              if (imgPostData.user?.profileImage != null &&
                                  (imgPostData.user?.profileImage?.isNotEmpty ??
                                      false) &&
                                  imgPostData.user?.profileImage
                                          ?.toLowerCase() !=
                                      "null")
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: InkWell(
                                    onTap: () {
                                      final authorId = imgPostData.user?.id;
                                      final business_id =
                                          imgPostData.user?.business_id;
                                      final accountType = imgPostData
                                          .user?.accountType
                                          ?.toUpperCase();
                                      if (accountType ==
                                          AppConstants.individual) {
                                        if (userId == authorId) {
                                          navigatePushTo(context,
                                              PersonalProfileSetupScreen());
                                        } else {
                                          Get.to(() => NewVisitProfileScreen(
                                                authorId: authorId ?? "",
                                                screenFromName:
                                                    AppConstants.feedScreen,
                                              ));
                                        }
                                      }
                                      if (accountType ==
                                          AppConstants.business) {
                                        if (businessId == business_id) {
                                          navigatePushTo(context,
                                              BusinessOwnProfileScreen());
                                        } else {
                                          Get.to(() => VisitBusinessProfileNew(
                                                businessId: business_id ?? "",
                                                screenName:
                                                    AppConstants.feedScreen,
                                              ));
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(50.0),
                                        border: Border.all(
                                            color: AppColors.primaryColor,
                                            width: 1.5),
                                      ),
                                      child: CachedAvatarWidget(
                                          imageUrl:
                                              imgPostData.user?.profileImage,
                                          size: 30,
                                          showProfileOnFullScreen: false,
                                          borderRadius: 100),
                                    ),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      );
                    }

                    ;
                  },
                ),
              );
            }

            // Single full-width item
            final item = block.items.first;

            if (item.type?.toLowerCase() == "message_post" ||
                item.type?.toLowerCase() == "poll_post") {
              return Padding(
                padding: EdgeInsets.only(
                    left: item.type?.toLowerCase() == "poll_post"
                        ? SizeConfig.size10
                        : SizeConfig.size2,
                    right: item.type?.toLowerCase() == "poll_post"
                        ? SizeConfig.size10
                        : SizeConfig.size2,
                    top: item.type?.toLowerCase() == "poll_post"
                        ? SizeConfig.size10
                        : SizeConfig.size10,
                    bottom: item.type?.toLowerCase() == "message_post"
                        ? SizeConfig.size5
                        : 0),
                child: FeedCard(
                  post: item,
                  index: index,
                  postFilteredType: PostType.all,
                  bottomPadding: 0,
                ),
              );
            }
            if (item.type == "long_video") {
              ShortFeedItem videoData = getVideoData(item);

              return Padding(
                padding: EdgeInsets.only(
                    left: SizeConfig.size5,
                    right: SizeConfig.size5,
                    top: SizeConfig.size10),
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
            return const SizedBox.shrink(); // skip if no card

            /*   return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title?.isNotEmpty??false)
                      CustomText(
                        item.title??"",
                      ),
                    if (item.subTitle?.isNotEmpty??false)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                        child: Text(item?.subTitle??"",
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                    if (thumbnail != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: thumbnail,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, err) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      ),
                    SizedBox(height: 8),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text('By ${item.raw['user']?['name'] ?? 'Unknown'}'),
                    //     Row(children: [
                    //       Icon(Icons.favorite_border),
                    //       SizedBox(width: 6),
                    //       Text('${item.raw['likes_count'] ?? 0}')
                    //     ])
                    //   ],
                    // )
                  ],
                ),
              ),
            );*/
          },
        );

        /*    final listView = ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding:
              EdgeInsets.only(top: SizeConfig.size2, bottom: SizeConfig.size80),
          shrinkWrap: widget.isInParentScroll,
          physics: widget.isInParentScroll
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemCount: (posts.length),
          itemBuilder: (context, index) {
            if (index == 0) {
              if (Get.find<MoreCardsScreenController>().dayCards.isNotEmpty) {
                return Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.size8,
                      right: SizeConfig.size8,
                      top: SizeConfig.size8),
                  child: GreetingCardDialog(
                      cards: Get.find<MoreCardsScreenController>().dayCards),
                );
              } else {
                return const SizedBox.shrink(); // skip if no card
              }
            }
            return _buildListItem(index - 1, posts);
          },
        );*/

        // 🔹 Only wrap with RefreshIndicator if headerOffset == 0
        final content = RefreshIndicator(
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
          watchedBefore: false),channel: video.channel,
      video: VideoData(
          id: video.id,
          userId: video.user?.id,
          type: video.type,
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
class FeedBlock {
  final bool isGrid;
  final List<Post> items;

  FeedBlock({required this.isGrid, required this.items});
}