import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/widget/feed_business_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_product_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_reel_pair_row.dart';
import 'package:BlueEra/features/common/feed/widget/feed_suggestions_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_video_card.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/home/view/widget/symbol_story_row.dart';
import 'package:BlueEra/features/common/promo/qureka_promo_banner.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

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

class _HomeFeedScreenNewState extends State<HomeFeedScreenNew>
    with AutomaticKeepAliveClientMixin {
  /// The feed lives inside the Social section's [TabBarView], which disposes a
  /// page the moment it scrolls out of the viewport. Without this, every trip to
  /// Bites and back tore the feed down and rebuilt it from scratch: scroll
  /// position lost, every card and image re-created, and initState's fetch
  /// re-armed. No feed app does that — you come back to a feed exactly where you
  /// left it.
  ///
  /// Cheap to hold: the tree stays mounted but is not laid out or painted while
  /// it is off screen, and the posts it renders are in [FeedController] either
  /// way.
  @override
  bool get wantKeepAlive => true;

  final FeedController feedController = Get.put(FeedController());
  final ScrollController _scrollController = ScrollController();
  late ShortsController? shortsController;

  var inventoryController = Get.isRegistered<InventoryController>()
      ? Get.find<InventoryController>()
      : Get.put(InventoryController());

  final homeScreenController = HomeScreenController.to;

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
    // Cache-first: put the last-known feed on screen BEFORE the first frame is
    // built (the Hive read is synchronous once the box is open, and it is
    // opened at boot). Without this the tab still flashed its spinner on every
    // cold open, because the cache hydration inside getFeed only starts after
    // the post-frame callback below and comes back an await later.
    //
    // Only when the shared list is cold — a warm one is live data from this
    // session and must not be overwritten with a snapshot from disk.
    if (widget.postFilterType == PostType.all &&
        feedController.allPosts.isEmpty) {
      feedController.primeFeedFromCacheSync();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardedFetchData(refreshFlag: true); // Guarded call
      // fetchPostData(refreshFlag: true);
      _scrollController.addListener(_scrollListener);

      /// forcefully we are calling api due to page is already loaded but we want to call api due to some new post is added by us
      ever(Get.find<NavigationHelperController>().shouldRefreshBottomBar,
          (shouldRefresh) {
        if (shouldRefresh == true) {
          // A post (message / poll / photo / video) was just uploaded, so the
          // freshest feed must show immediately. Bypass the 90s throttle in
          // _guardedFetchData — an upload almost always lands inside that
          // window, and the guard would otherwise swallow this refresh. Stamp
          // lastHomeFetchTime so later time-based calls stay consistent.
          lastHomeFetchTime = DateTime.now();
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

  /// Renders one `/feed` item, switching on its `type` discriminator.
  ///
  /// This is the renderer switch the feed contract mandates (see
  /// docs/backend/FRONTEND_FEED_INTEGRATION.md §3): `/feed` returns a
  /// heterogeneous list and the order/ratio is backend-controlled, so we render
  /// strictly in the order received and never assume a layout pattern.
  ///
  /// Unknown types fall through to an empty box on purpose — the guide (§6.5)
  /// warns new types can appear server-side and the client must skip them
  /// gracefully rather than crash.
  Widget _buildFeedItem(Post item, int index) {
    switch (item.feedType) {
      // Text / photo / poll posts all route through FeedCard, which already
      // branches internally (including posts whose media is video — decided on
      // `media_types`, not `type`, per guide §6.3).
      case 'message_post':
      case 'image_post':
      case 'poll_post':
        // FeedCard owns its internal padding; no wrapping Padding here.
        return _seen(
          [item.id],
          FeedCard(
            post: item,
            index: index,
            postFilteredType: PostType.all,
            bottomPadding: 0,
            horizontalPadding: 0,
            // Set to 0 to remove side gaps
            isRepost: false,
          ),
        );

      case 'short_video':
      case 'long_video':
        return _seen([item.id], FeedVideoCard(post: item));

      case 'business':
        return FeedBusinessCard(post: item);

      case 'product':
        return FeedProductCard(post: item);

      // Merged home feed only ("who to follow"). No trackPostView — a
      // suggestion block is not content. A block that arrived without its
      // payload (e.g. rehydrated from an older cache) renders as nothing
      // rather than an empty card.
      case 'user_suggestions':
        final block = item.suggestions;
        if (block == null) return const SizedBox.shrink();
        return FeedSuggestionsCard(block: block);

      default:
        return const SizedBox.shrink();
    }
  }

  /// Counts a view for [postId] once the card is actually **on screen**, not
  /// when it is built.
  ///
  /// `trackPostView` used to be called straight from the item builder. A
  /// `ListView` builds ahead of the viewport by its cache extent (250px by
  /// default, and more here), so posts the user scrolled past the edge of and
  /// never saw were counted as views — and on a fast flick the whole run
  /// between two resting positions got counted. Views are a ranking signal;
  /// inflating them with cards nobody looked at degrades the feed for everyone.
  ///
  /// 50% visible matches what the rest of the app treats as "on screen" (the
  /// Bites grid uses the same threshold to pick what plays), and
  /// `trackPostView` still de-duplicates per session, so a post scrolled past
  /// twice is one view either way.
  /// [postIds] is a list because a reel PAIR shares one row — the two are side
  /// by side, so either the row is on screen or neither of them is, and one
  /// detector covering both is cheaper than two.
  Widget _seen(List<String> postIds, Widget child) {
    final ids = postIds.where((id) => id.isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return child;
    return VisibilityDetector(
      key: ValueKey('feed_seen_${ids.join('_')}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.5) return;
        for (final id in ids) {
          trackPostView(id);
        }
      },
      child: child,
    );
  }

  /// True for an item the feed should be able to pair 2-up: a reel, in either
  /// of the two shapes the backends produce (`type: "short_video"` on the
  /// merged feed, `item_type: "reel"` on the include-reels post feeds).
  ///
  /// Long videos are deliberately excluded — they are 16:9 and belong
  /// full-width.
  bool _isPairableReel(Post item) =>
      item.isReel || item.feedType == 'short_video';

  /// Groups the feed into render rows.
  ///
  /// Everything is one item per row, **except** a run of consecutive reels,
  /// which is chunked into pairs and rendered side by side per the Feed design.
  /// A run of one (a reel between two posts) stays a full-width
  /// [FeedVideoCard], and an odd trailing reel keeps half width so the columns
  /// stay aligned.
  ///
  /// This only ever changes *layout* — items keep the exact order the backend
  /// sent them, which is what the feed contract requires.
  List<FeedBlock> _buildBlocks(List<Post> items) {
    final List<FeedBlock> blocks = [];
    final List<Post> reelRun = [];

    void flushReelRun() {
      if (reelRun.isEmpty) return;
      if (reelRun.length == 1) {
        // A lone reel is not a pair — render it the way it has always been.
        blocks.add(FeedBlock(isGrid: false, items: [reelRun.first]));
      } else {
        for (var i = 0; i < reelRun.length; i += 2) {
          blocks.add(FeedBlock(
            isGrid: true,
            items: reelRun.sublist(i, (i + 2).clamp(0, reelRun.length)),
          ));
        }
      }
      reelRun.clear();
    }

    for (final item in items) {
      if (_isPairableReel(item)) {
        reelRun.add(item);
        continue;
      }
      flushReelRun();
      blocks.add(FeedBlock(isGrid: false, items: [item]));
    }
    flushReelRun();
    return blocks;
  }

  /// Cached output of [_buildBlocks] + [buildNativeAdRows], keyed on the post
  /// list that produced it.
  ///
  /// Both walk the whole feed and allocate two fresh lists, and they used to run
  /// inside the `Obx` — so they re-ran on EVERY rebuild, including the ones that
  /// have nothing to do with the feed's contents (the header collapsing, a
  /// single like landing, a video card reporting a frame). By the time the feed
  /// is a few hundred posts deep that is real work, repeated many times a
  /// second, to arrive at exactly the list already in hand.
  ///
  /// The freshness check is a length + element-identity scan against a snapshot
  /// of the list the current blocks were built from.
  ///
  /// It deliberately does NOT compare the list objects themselves. `allPosts` is
  /// an `RxList` that [FeedController] mutates IN PLACE (`assignAll`, `addAll`),
  /// so the list instance is the same object for the life of the controller —
  /// an `identical` check on it would pass forever and the feed would freeze on
  /// its first page. Nor does it use `==`: `Post` has no value equality, so that
  /// degrades to the same identity comparison per element with more ceremony.
  ///
  /// A scan of N pointer comparisons costs a fraction of rebuilding two lists of
  /// N objects, and it answers the right question — a like landing mutates a
  /// `Post` in place and must NOT invalidate the layout, while a fetch swaps the
  /// elements and must.
  List<Post> _blocksSnapshot = const [];
  List<FeedBlock> _blocks = const [];
  List<NativeAdRow> _rows = const [];

  bool _blocksAreFresh(List<Post> posts) {
    if (_blocksSnapshot.length != posts.length) return false;
    for (var i = 0; i < posts.length; i++) {
      if (!identical(_blocksSnapshot[i], posts[i])) return false;
    }
    return true;
  }

  void _ensureBlocks(List<Post> posts) {
    if (_blocksAreFresh(posts)) return;
    _blocksSnapshot = List.of(posts);
    _blocks = _buildBlocks(posts);
    // Interleave native ads across the MAIN combined list (one block per post)
    // at the shared series positions — independent of each post's type.
    _rows = buildNativeAdRows(_blocks.length);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
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
        _ensureBlocks(posts);
        final blocks = _blocks;
        final rows = _rows;
        final bool showStories = widget.postFilterType == PostType.all;
        final listView = ListView.builder(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          // Build a screen's worth ahead of the viewport instead of the 250px
          // default. A feed card is ~380-500px tall, so the default barely
          // reaches the next one and every flick lands on a card that is still
          // being laid out and decoding its image. One viewport of runway is
          // what the scroll needs to stay ahead of the finger; more than that
          // and the extra cards are decoding images nobody is going to see.
          cacheExtent: MediaQuery.sizeOf(context).height,
          // 1. Set padding to zero if you want it flush, or keep only what is necessary
          padding: EdgeInsets.zero,
          itemCount: rows.length + (showStories ? 1 : 0),
          shrinkWrap: widget.isInParentScroll,
          physics: widget.isInParentScroll
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, indexFeed) {
            // Story rail only — no promo pinned under it. The ad rows
            // interleaved by [buildNativeAdRows] already carry the Qureka card
            // at the shared cadence, so one here made the feed open on a promo
            // and then show another a few posts down.
            if (showStories && indexFeed == 0) {
              return const SymbolStoryRow();
            }

            final rowIndex = showStories ? indexFeed - 1 : indexFeed;
            final row = rows[rowIndex];

            if (row.isAd) {
              print('[HOME_FEED_AD] building ad slot '
                  'ordinal=${row.adOrdinal} index=$indexFeed');
              // Feed-styled native ad: the platform `feedAdFactory` layout
              // mirrors a post card (author header + media + CTA). The white
              // fill, 20dp rounded corners and 1px greyE5 border are drawn by
              // the NATIVE layout (so all four corners stay crisp on the
              // platform view); Flutter only adds the matching radius-20 clip,
              // the soft post-card shadow, and EdgeInsets.all(5) spacing — the
              // same spacing FeedCardWidget + MessagePostWidget use.
              // Qureka promo in place of the native ad — see kQurekaReplacesNativeAds.
              return PromoAdSlot(
                adOrdinal: row.adOrdinal,
                keyPrefix: 'home_feed_native_ad',
                factoryId: 'feedAdFactory',
                height: 380,
                borderRadius: 20,
                margin: const EdgeInsets.all(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              );
            }

            final index = row.contentIndex;
            final block = blocks[index];

            // A grid block is a run of consecutive reels laid out 2-up. Both
            // reels in the pair share the row's visibility — they are side by
            // side, so either the row is on screen or neither of them is.
            if (block.isGrid) {
              return _seen(
                block.items.map((r) => r.id).toList(),
                FeedReelPairRow(reels: block.items),
              );
            }

            final item = block.items.first;

            return _buildFeedItem(item, index);
          },
        );

        // 🔹 Only wrap with RefreshIndicator if headerOffset == 0
        final content = RefreshIndicator(
          notificationPredicate: (notification) {
            return homeScreenController.headerOffset.value == 0.0 &&
                notification.metrics.pixels <=
                    notification.metrics.minScrollExtent;
          },
          onRefresh: () async {
            if (homeScreenController.headerOffset.value != 0.0) {
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
              final controller = homeScreenController;
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
  // A feed item carries its video two different ways depending on which
  // endpoint produced it: merged-feed `short_video` items put everything at the
  // top level, while `item_type: "reel"` items (post/allPosts?include_reels,
  // post/my-posts) nest it under `reel` and leave the post fields null.
  // Resolve both so either shape opens the player fully populated.
  final reel = video.reel;
  final reelStats = reel?.stats;

  return ShortFeedItem(
      videoId: reel?.id ?? video.id,
      // The post that owns this reel's likes/comments/shares, when it was
      // ingested from one. The player branches its writes on this — dropping it
      // here would send them to video-service, where nothing reads them back
      // (SOCIAL_SECTION_INTEGRATION_GUIDE.md §4).
      originPostId: video.engagementPostId,
      likesCount: reelStats?.likes ?? video.likesCount,
      commentsCount: reelStats?.comments ?? video.commentsCount,
      repostCount: video.repostCount,
      sharesCount: reelStats?.shares ?? video.sharesCount,
      viewsCount: reelStats?.views ?? video.viewsCount,
      author: Author(
        // `Author` has one `name` field for both account kinds, so resolve the
        // business/individual split here — otherwise a business's reel opens
        // the player with no name at all (its name lives in `businessName`).
        name: (video.user?.name?.trim().isNotEmpty ?? false)
            ? video.user?.name
            : video.user?.businessName,
        username: video.user?.username,
        designation: video.user?.designation,
        profileImage: video.user?.profileImage,
        accountType: video.user?.accountType,
        id: video.user?.id,
        // Routing taxonomy the player's author tap needs (openVisitProfile):
        // `/feed` authors carry only the sub-category + the business id, never
        // `type_of_business` / `profile_type`. Dropping them here is what made
        // a tapped lab / restaurant / pharmacy open the generic profile.
        categoryOfBusiness: video.user?.categoryOfBusiness,
        businessId: video.user?.business_id,
      ),
      metadata: VideoItemMetadata(
          addedAt: video.createdAt.toString(),
          source: "personalized",
          watchedBefore: false),
      channel: video.channel,
      video: VideoData(
          id: reel?.id ?? video.id,
          userId: reel?.userId ?? video.user?.id,
          channelId: reel?.channelId,
          type: reel?.type ?? video.type,
          title: reel?.title ?? video.title,
          description: reel?.description ?? video.subTitle,
          caption: reel?.caption,
          originPostId: video.engagementPostId,
          engagementSource: reel?.engagementSource,
          // `/feed` video items carry their source in `video_url` (guide §4.4);
          // fall back to `media` for post-shaped payloads that inline the file.
          videoUrl: (reel?.videoUrl?.isNotEmpty ?? false)
              ? reel!.videoUrl
              : (video.videoUrl?.isNotEmpty ?? false)
                  ? video.videoUrl
                  : video.media?.firstOrNull,
          coverUrl: reel?.coverUrl ?? video.thumbnail,
          createdAt: reel?.createdAt ?? video.createdAt.toString(),
          media_height: video.media_height,
          media_width: video.media_width,
          duration: reel?.duration ?? video.duration,
          stats: Stats(
              comments: reelStats?.comments ?? video.commentsCount,
              likes: reelStats?.likes ?? video.likesCount,
              shares: reelStats?.shares ?? video.sharesCount,
              repost_count: video.repostCount,
              views: reelStats?.views ?? video.viewsCount)),
      // For an ingested reel the backend already serves the POST's isLiked, so
      // seeding from the item keeps the heart correct on open instead of always
      // starting hollow.
      interactions: Interactions(
          isBookmarked: false,
          isFollowing: false,
          isLiked: video.isLiked ?? false));
}

class FeedBlock {
  final bool isGrid;
  final List<Post> items;

  FeedBlock({required this.isGrid, required this.items});
}
