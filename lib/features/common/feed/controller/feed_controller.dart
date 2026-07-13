import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/all_like_users_list_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/home_cache_service.dart';
import 'package:BlueEra/core/services/keyed_json_cache.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/feed/models/block_user_response.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/features/common/home/model/home_feed_model.dart';
import 'package:BlueEra/features/common/home/repo/home_feed_repo.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/widgets/custom_success_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeedController extends GetxController {
  Rx<ApiResponse> postsResponse = ApiResponse.initial('Initial').obs;
  ApiResponse likeDislikeResponse = ApiResponse.initial('Initial');
  ApiResponse deletePostResponse = ApiResponse.initial('Initial');
  ApiResponse blockUserResponse = ApiResponse.initial('Initial');
  ApiResponse pollAnswerResponse = ApiResponse.initial('Initial');
  ApiResponse reportPostResponse = ApiResponse.initial('Initial');
  ApiResponse allLikeUsersOfPostResponse = ApiResponse.initial('Initial');
  RxList<Post> allPosts = <Post>[].obs;
  RxList<Post> myPosts = <Post>[].obs;
  RxList<Post> otherPosts = <Post>[].obs;
  RxList<Post> savedPosts = <Post>[].obs;
  RxList<Post> latestPosts = <Post>[].obs;
  RxList<Post> popularPosts = <Post>[].obs;
  RxList<Post> oldestPosts = <Post>[].obs;
  RxList<Post> otherChannelPosts = <Post>[].obs;
  RxBool isLoading = true.obs;
  RxBool isTargetHasMoreData = true.obs;
  RxBool isTargetMoreDataLoading = false.obs;
  int allPage = 1,
      myPage = 1,
      otherPage = 1,
      latestPostsPage = 1,
      popularPostsPage = 1,
      oldestPostsPage = 1,
      otherChannelPostsPage = 1;
  var postFilterType = "latest";

  // New variables for enhanced pagination
  final Map<PostType, List<Post>> _cachedPosts = {};
  final Map<PostType, int> _displayedCounts = {};
  final int initialFetchLimit = 40;
  final int displayLimit = 20;

  RxList<LikeUserData> allLikeUsersList = <LikeUserData>[].obs;
  RxBool allLikeUsersListLoading = true.obs;

  String? _lastFetchedId;

  /// Fetch posts based on filter
  Future<void> getPostsByType(
    PostType type, {
    bool isInitialLoad = false,
    bool refresh = false,
    String? id,
    String? query,
    required String? screenName,
  }) async {
    switch (type) {
      case PostType.all:
        await _fetchPostsWithEnhancedCache(
            page: allPage,
            type: type,
            isInitialLoad: isInitialLoad,
            targetList: allPosts,
            onPageReset: () => allPage = 1,
            onPageIncrement: () => allPage++,
            refresh: refresh,
            id: id,
            query: query);
        break;
      case PostType.myPosts:
        await _fetchPostsWithEnhancedPagination(
          page: myPage,
          type: type,
          isInitialLoad: isInitialLoad,
          targetList: myPosts,
          onPageReset: () => myPage = 1,
          onPageIncrement: () => myPage++,
          refresh: refresh,
          id: id,
        );
        break;
      case PostType.otherPosts:
        await _fetchPostsWithEnhancedPagination(
          page: otherPage,
          type: type,
          isInitialLoad: isInitialLoad,
          targetList: otherPosts,
          onPageReset: () => otherPage = 1,
          onPageIncrement: () => otherPage++,
          refresh: refresh,
          id: id,
        );
        break;
      case PostType.latest:
        await _fetchPostsWithEnhancedPagination(
          page: latestPostsPage,
          type: type,
          isInitialLoad: isInitialLoad,
          targetList: latestPosts,
          onPageReset: () => latestPostsPage = 1,
          onPageIncrement: () => latestPostsPage++,
          refresh: refresh,
          id: id,
        );
        break;
      case PostType.popular:
        await _fetchPostsWithEnhancedPagination(
          page: popularPostsPage,
          type: type,
          isInitialLoad: isInitialLoad,
          targetList: popularPosts,
          onPageReset: () => popularPostsPage = 1,
          onPageIncrement: () => popularPostsPage++,
          refresh: refresh,
          id: id,
        );
        break;
      case PostType.oldest:
        await _fetchPostsWithEnhancedPagination(
          page: oldestPostsPage,
          type: type,
          isInitialLoad: isInitialLoad,
          targetList: oldestPosts,
          onPageReset: () => oldestPostsPage = 1,
          onPageIncrement: () => oldestPostsPage++,
          refresh: refresh,
          id: id,
        );
        break;
      case PostType.saved:
        getAllSavedPost();
        break;
      case PostType.otherChannelPosts:
        // TODO: Handle this case.
        await _fetchPostsWithEnhancedPagination(
          page: otherChannelPostsPage,
          type: type,
          isInitialLoad: isInitialLoad,
          targetList: otherChannelPosts,
          onPageReset: () => otherChannelPostsPage = 1,
          onPageIncrement: () => otherChannelPostsPage++,
          refresh: refresh,
          id: id,
        );
        break;
    }
  }

  Future<void> getChannelPostsByType(
    PostType type, {
    bool isInitialLoad = false,
    bool refresh = false,
    String? id,
    String? query,
    required String? screenName,
  }) async {
    _fetchPostsChannelWithEnhancedPagination(
      page: otherPage,
      type: type,
      isInitialLoad: isInitialLoad,
      targetList: otherPosts,
      onPageReset: () => otherPage = 1,
      onPageIncrement: () => otherPage++,
      refresh: refresh,
      id: id,
    );
  }

  /// Enhanced fetch with cache integration for All Posts tab
  Future<void> _fetchPostsWithEnhancedCache(
      {required int page,
      required PostType type,
      required bool isInitialLoad,
      required RxList<Post> targetList,
      required VoidCallback onPageReset,
      required VoidCallback onPageIncrement,
      required bool refresh,
      String? id,
      String? query}) async {
    print('🔄 Enhanced cache fetch - page: $page, type: $type, isInitialLoad: $isInitialLoad');

    // For initial load, try to get cached data first
    if (isInitialLoad && page == 1 && !refresh) {
      final cachedPosts = await HomeCacheService().getCachedPosts();
      if (cachedPosts != null && cachedPosts.isNotEmpty) {
        print('📱 Showing cached posts: ${cachedPosts.length} items');

        // Initialize enhanced pagination with cached data
        _cachedPosts[type] = List.from(cachedPosts);
        _displayedCounts[type] = displayLimit.clamp(0, cachedPosts.length);

        // Display only first 20 cached posts
        targetList.value = cachedPosts.take(displayLimit).toList();
        isLoading.value = false;

        print('📦 Enhanced cache: Cached ${_cachedPosts[type]!.length}, Displaying ${targetList.length}');

        // Fetch fresh data in background and enhance pagination
        _fetchEnhancedDataInBackground(
            page: page,
            type: type,
            targetList: targetList,
            onPageIncrement: onPageIncrement,
            refresh: refresh,
            id: id,
            query: query);
        return;
      } else {
        print('📱 No cached posts found, fetching from API...');
      }
    }

    // If no cache or not initial load, fetch with enhanced pagination
    await _fetchPostsWithEnhancedPagination(
        page: page,
        type: type,
        isInitialLoad: isInitialLoad,
        targetList: targetList,
        onPageReset: onPageReset,
        onPageIncrement: onPageIncrement,
        refresh: refresh,
        id: id,
        query: query);
  }

  /// Enhanced background fetch that integrates with cache
  Future<void> _fetchEnhancedDataInBackground(
      {required int page,
      required PostType type,
      required RxList<Post> targetList,
      required VoidCallback onPageIncrement,
      required bool refresh,
      String? id,
      String? query}) async {
    try {
      print('🔄 Starting enhanced background fetch for fresh data...');

      final Map<String, dynamic> queryParams = {
        ApiKeys.page: page,
        ApiKeys.limit: initialFetchLimit, // Fetch 40 items for enhancement
        ApiKeys.filter: postFilterType,
        // Ask the server to interleave reels into the post feed (default is on;
        // sent explicitly to document intent). See REELS_IN_FEED guide.
        ApiKeys.includeReels: true,
      };

      if (query == null) {
        queryParams[ApiKeys.refresh] = refresh;
      } else {
        queryParams[ApiKeys.query] = query;
      }

      ResponseModel response = await FeedRepo().fetchAllPosts(queryParams: queryParams);

      if (response.isSuccess) {
        final postResponse = PostResponse.fromJson(response.response?.data);
        if (postResponse.data.isNotEmpty) {
          print('✅ Enhanced background fetch successful: ${postResponse.data.length} items');

          // Update enhanced cache with fresh data
          _cachedPosts[type] = List.from(postResponse.data);
          _displayedCounts[type] = displayLimit.clamp(0, postResponse.data.length);

          // Update cache service with first 20 posts
          await HomeCacheService().cachePosts(postResponse.data.take(displayLimit).toList());
          print('💾 Updated cache service with first ${displayLimit} posts');

          // Update the UI with fresh data (first 20 posts)
          targetList.value = postResponse.data.take(displayLimit).toList();

          // Set pagination state. Reels are layered on top of posts and don't
          // count toward the page limit, so measure progress by post count, not
          // data.length (which now includes reels). See REELS_IN_FEED guide §6.
          final fetchedPostCount =
              postResponse.data.where((e) => !e.isReel).length;
          if (fetchedPostCount < initialFetchLimit) {
            isTargetHasMoreData.value = false;
            print('📄 No more data from server after background fetch');
          } else {
            isTargetHasMoreData.value = true;
            onPageIncrement();
            print('📄 More data available, page incremented');
          }
        }
      } else {
        print('❌ Enhanced background fetch failed: ${response.message}');
      }
    } catch (e) {
      print('❌ Enhanced background fetch error: $e');
    }
  }

  Future<void> _fetchPostsWithEnhancedPagination(
      {required int page,
      required PostType type,
      required bool isInitialLoad,
      required RxList<Post> targetList,
      required VoidCallback onPageIncrement,
      required VoidCallback onPageReset,
      required bool refresh,
      String? id,
      String? query}) async {
    print('🔄 Enhanced pagination - page: $page, type: $type, isInitialLoad: $isInitialLoad');

    if (isInitialLoad) {
      page = 1;
      onPageReset.call();
      isTargetHasMoreData.value = true;
      isTargetMoreDataLoading.value = false;
      _cachedPosts[type] = [];
      _displayedCounts[type] = 0;
    }
    print('otherPage $otherPage');

    print('isTargetHasMoreData: $isTargetHasMoreData, isTargetMoreDataLoading: $isTargetMoreDataLoading');
    if (isTargetHasMoreData.isFalse || isTargetMoreDataLoading.isTrue) return;

    print('isInitialLoad: $isInitialLoad');
    if (!isInitialLoad) {
      isTargetMoreDataLoading.value = true;
    }

    // Check if we have cached data to display first
    if (_hasMoreCachedData(type) && !isInitialLoad) {
      _displayMoreCachedData(type, targetList);
      print('_cachedPosts length: ${_cachedPosts[type]?.length ?? 0}, targetList: ${targetList.length}');
    }

    // ✅ Only show loader if last id is different
    log('last fetched id-->  $_lastFetchedId');
    if (_lastFetchedId != id) {
      isLoading.value = true;
    }
    _lastFetchedId = id;

    final Map<String, dynamic> queryParams = {
      ApiKeys.page: page,
      ApiKeys.limit: isInitialLoad ? initialFetchLimit : displayLimit,
      ApiKeys.filter: postFilterType,
    };

    // Reels are injected only into the post feeds — home/search (PostType.all),
    // my-posts, and other-user posts. The channel feed (latest/popular/oldest/
    // otherChannelPosts) is posts-only on the backend, so don't request reels
    // there. See REELS_IN_FEED_FRONTEND_GUIDE.md §1 ("channel feed → no reels").
    final feedSupportsReels = type == PostType.all ||
        type == PostType.myPosts ||
        type == PostType.otherPosts;
    if (feedSupportsReels) {
      queryParams[ApiKeys.includeReels] = true;
    }

    if (query == null) {
      queryParams[ApiKeys.refresh] = refresh;
    }

    ResponseModel response;
    // The API call must live inside this try/catch: on network failures
    // (timeout / no internet) the repo throws from ApiBaseHelper.handleError.
    // If the call sits outside the try, that throw bubbles up through
    // getPostsByType as an unhandled exception (feed crash on getAllMyPosts).
    try {
      switch (type) {
        case PostType.all:
          if (query == null) {
            response = await FeedRepo().fetchAllPosts(queryParams: queryParams);
          } else {
            queryParams[ApiKeys.query] = query;
            response =
                await FeedRepo().postsFeedSearch(queryParams: queryParams);
          }
          break;
        case PostType.myPosts:
          response = await FeedRepo().getAllMyPosts(queryParams: queryParams);
          break;
        case PostType.otherPosts:
          if (id != null) queryParams[ApiKeys.authorId] = id;
          response = await FeedRepo().getAllOtherPosts(queryParams: queryParams);
          break;
        case PostType.otherChannelPosts:
          queryParams[ApiKeys.filter] = 'latest';
          queryParams[ApiKeys.authorId] = id;
          response =
              await ChannelRepo().getChannelAllPosts(queryParams: queryParams);
          break;
        case PostType.latest || PostType.popular || PostType.oldest:
          if (id != null) queryParams[ApiKeys.authorId] = id;
          queryParams[ApiKeys.filter] = (type == PostType.latest)
              ? 'latest'
              : (type == PostType.popular)
                  ? 'popular'
                  : 'oldest';
          response =
              await ChannelRepo().getChannelAllPosts(queryParams: queryParams);
          break;
        default:
          return;
      }

      if (response.isSuccess) {
        postsResponse.value = ApiResponse.complete(response);
        final postResponse = PostResponse.fromJson(response.response?.data);

        if (page == 1) {
          targetList.clear();
          // Initial load: cache all data, display first batch
          _cachedPosts[type] = List.from(postResponse.data);
          _displayedCounts[type] = displayLimit.clamp(0, postResponse.data.length);

          // Display only first batch
          targetList.value = postResponse.data.take(displayLimit).toList();

          print(
              '📦 Initial enhanced load: Fetched ${postResponse.data.length}, Displaying ${targetList.length}, Cached ${_cachedPosts[type]!.length}');

          // Update cache service for All Posts tab
          if (type == PostType.all && postResponse.data.isNotEmpty) {
            await HomeCacheService().cachePosts(postResponse.data.take(displayLimit).toList());
            print('💾 Updated cache service with ${displayLimit} posts for All Posts tab');
          }
        } else {
          // Subsequent loads: add new data to cache
          _cachedPosts[type]!.addAll(postResponse.data);
          print(
              '📦 Added ${postResponse.data.length} new posts to cache. Total cached: ${_cachedPosts[type]!.length}');
        }

        // Check if we have more data available from server. Reels are layered
        // on top of posts and don't count toward the page limit, so measure by
        // post count, not data.length (which now includes reels). See
        // REELS_IN_FEED guide §6.
        final expectedLimit = isInitialLoad ? initialFetchLimit : displayLimit;
        final fetchedPostCount =
            postResponse.data.where((e) => !e.isReel).length;
        final hasServerMore = fetchedPostCount >= expectedLimit;
        final hasCacheMore = _hasMoreCachedData(type);

        if (!hasServerMore && !hasCacheMore) {
          print('📄 No more data (server + cache exhausted)');
          isTargetHasMoreData.value = false;
        } else {
          print('📄 More data available (cache or server)');
          isTargetHasMoreData.value = true;

          // Only increment page if server had more
          if (hasServerMore) onPageIncrement();
        }
      } else {
        postsResponse.value = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      postsResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
      isTargetMoreDataLoading.value = false;
    }
  }

  Future<void> _fetchPostsChannelWithEnhancedPagination(
      {required int page,
      required PostType type,
      required bool isInitialLoad,
      required RxList<Post> targetList,
      required VoidCallback onPageIncrement,
      required VoidCallback onPageReset,
      required bool refresh,
      String? id,
      String? query}) async {
    print('🔄 Enhanced pagination - page: $page, type: $type, isInitialLoad: $isInitialLoad');

    if (isInitialLoad) {
      page = 1;
      onPageReset.call();
      isTargetHasMoreData.value = true;
      isTargetMoreDataLoading.value = false;
      _cachedPosts[type] = [];
      _displayedCounts[type] = 0;
    }
    print('otherPage $otherPage');

    print('isTargetHasMoreData: $isTargetHasMoreData, isTargetMoreDataLoading: $isTargetMoreDataLoading');
    if (isTargetHasMoreData.isFalse || isTargetMoreDataLoading.isTrue) return;

    print('isInitialLoad: $isInitialLoad');
    if (!isInitialLoad) {
      isTargetMoreDataLoading.value = true;
    }

    // Check if we have cached data to display first
    if (_hasMoreCachedData(type) && !isInitialLoad) {
      _displayMoreCachedData(type, targetList);
      print('_cachedPosts length: ${_cachedPosts[type]?.length ?? 0}, targetList: ${targetList.length}');
    }

    // ✅ Only show loader if last id is different
    log('last fetched id-->  $_lastFetchedId');
    if (_lastFetchedId != id) {
      isLoading.value = true;
    }
    _lastFetchedId = id;

    // Channel feed is posts-only — the backend injects no reels here, so we
    // don't request them. See REELS_IN_FEED_FRONTEND_GUIDE.md §1.
    final Map<String, dynamic> queryParams = {
      ApiKeys.page: page,
      ApiKeys.limit: isInitialLoad ? initialFetchLimit : displayLimit,
      ApiKeys.filter: postFilterType,
    };

    if (query == null) {
      queryParams[ApiKeys.refresh] = refresh;
    }

    ResponseModel response;
    response = await ChannelRepo().getChannelAllPosts(queryParams: queryParams);

    try {
      if (response.isSuccess) {
        postsResponse.value = ApiResponse.complete(response);
        final postResponse = PostResponse.fromJson(response.response?.data);

        if (page == 1) {
          targetList.clear();
          // Initial load: cache all data, display first batch
          _cachedPosts[type] = List.from(postResponse.data);
          _displayedCounts[type] = displayLimit.clamp(0, postResponse.data.length);

          // Display only first batch
          targetList.value = postResponse.data.take(displayLimit).toList();

          print(
              '📦 Initial enhanced load: Fetched ${postResponse.data.length}, Displaying ${targetList.length}, Cached ${_cachedPosts[type]!.length}');

          // Update cache service for All Posts tab
          if (type == PostType.all && postResponse.data.isNotEmpty) {
            await HomeCacheService().cachePosts(postResponse.data.take(displayLimit).toList());
            print('💾 Updated cache service with ${displayLimit} posts for All Posts tab');
          }
        } else {
          // Subsequent loads: add new data to cache
          _cachedPosts[type]!.addAll(postResponse.data);
          print(
              '📦 Added ${postResponse.data.length} new posts to cache. Total cached: ${_cachedPosts[type]!.length}');
        }

        // Check if we have more data available from server. Reels are layered
        // on top of posts and don't count toward the page limit, so measure by
        // post count, not data.length (which now includes reels). See
        // REELS_IN_FEED guide §6.
        final expectedLimit = isInitialLoad ? initialFetchLimit : displayLimit;
        final fetchedPostCount =
            postResponse.data.where((e) => !e.isReel).length;
        final hasServerMore = fetchedPostCount >= expectedLimit;
        final hasCacheMore = _hasMoreCachedData(type);

        if (!hasServerMore && !hasCacheMore) {
          print('📄 No more data (server + cache exhausted)');
          isTargetHasMoreData.value = false;
        } else {
          print('📄 More data available (cache or server)');
          isTargetHasMoreData.value = true;

          // Only increment page if server had more
          if (hasServerMore) onPageIncrement();
        }
      } else {
        postsResponse.value = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      postsResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
      isTargetMoreDataLoading.value = false;
    }
  }

  bool _hasMoreCachedData(PostType type) {
    final cachedPosts = _cachedPosts[type] ?? [];
    final displayedCount = _displayedCounts[type] ?? 0;
    return displayedCount < cachedPosts.length;
  }

  void _displayMoreCachedData(PostType type, RxList<Post> targetList) {
    final cachedPosts = _cachedPosts[type] ?? [];
    final currentDisplayed = _displayedCounts[type] ?? 0;
    final nextDisplayCount = (currentDisplayed + displayLimit).clamp(0, cachedPosts.length);

    // Add next batch of cached posts to display
    final newPosts = cachedPosts.skip(currentDisplayed).take(displayLimit).toList();
    targetList.addAll(newPosts);
    _displayedCounts[type] = nextDisplayCount;

    print('📱 Displayed ${newPosts.length} cached posts. Total displayed: ${targetList.length}');

    // Update cache service with more posts if it's All Posts tab
    if (nextDisplayCount >= cachedPosts.length && isTargetHasMoreData.isTrue) {
      _triggerBackgroundFetch(type);
    }
  }

  void _triggerBackgroundFetch(PostType type) {
    print('🔄 Triggering enhanced background fetch for more data');
    // Call the appropriate fetch method based on type
    switch (type) {
      case PostType.all:
        getPostsByType(PostType.all, screenName: '');
        break;
      case PostType.myPosts:
        getPostsByType(PostType.myPosts, screenName: '');
        break;
      case PostType.otherPosts:
        getPostsByType(PostType.otherPosts, screenName: '');
        break;
      case PostType.latest:
        getPostsByType(PostType.latest, screenName: '');
        break;
      case PostType.popular:
        getPostsByType(PostType.popular, screenName: '');
        break;
      case PostType.oldest:
        getPostsByType(PostType.oldest, screenName: '');
        break;
      default:
        break;
    }
  }

  // Call this method when user scrolls to bottom
  void handleScrollToBottom(PostType type) {
    if (_hasMoreCachedData(type)) {
      final targetList = getListByType(type);
      _displayMoreCachedData(type, targetList);
    } else if (isTargetHasMoreData.isTrue && isTargetMoreDataLoading.isFalse) {
      // No more cached data, fetch from API
      _triggerBackgroundFetch(type);
    }
  }

  // Enhanced cache clearing
  void clearEnhancedCache(PostType type) {
    _cachedPosts[type] = [];
    _displayedCounts[type] = 0;

    // Also clear cache service for All Posts
    if (type == PostType.all) {
      HomeCacheService().clearCache(HomeCacheService().postsCacheBox);
    }
  }

  // Get cache info for debugging
  Map<String, dynamic> getCacheInfo(PostType type) {
    return {
      'cached_count': _cachedPosts[type]?.length ?? 0,
      'displayed_count': _displayedCounts[type] ?? 0,
      'has_more_cached': _hasMoreCachedData(type),
      'has_more_server': isTargetHasMoreData.value,
    };
  }

  /// Utility to get post list by type
  RxList<Post> getListByType(PostType type) {
    // pick the raw RxList
    final RxList<Post> list = switch (type) {
      PostType.all => allPosts,
      PostType.myPosts => myPosts,
      PostType.otherPosts => otherPosts,
      PostType.saved => savedPosts,
      PostType.latest => latestPosts,
      PostType.popular => popularPosts,
      PostType.oldest => oldestPosts,
      PostType.otherChannelPosts => otherChannelPosts,
    };

    // hydrate local flag only once (if not already done)
    if (list.isNotEmpty) {
      list.assignAll(
        list
            .map(
              (p) => p.copyWith(isPostSavedLocal: HiveServices().isPostSaved(p.id)),
            )
            .toList(),
      );
    }
    return list;
  }

  /// Like/Unlike
// Keep track of the pending API call per post
  Map<String, Future<void>?> _pendingLikeCalls = {};

// Keep track of the last intended state per post
  Map<String, bool> _lastIntendedLikeState = {};

  Future<void> postLikeDislike({
    required String postId,
    required PostType type,
    SortBy? sortBy,
  }) async {
    final list = getListByType(type);
    final index = list.indexWhere((p) => p.id == postId);

    if (index == -1) return;

    final post = list[index];
    // 🔹 Calculate new state

    final newIsLiked = !(post.isLiked ?? false);
    final newLikesCount = (post.likesCount ?? 0) + (newIsLiked ? 1 : -1);

    // 🔹 Store the user's last intended state
    _lastIntendedLikeState[postId] = newIsLiked;

    // 🔹 Optimistic update instantly
    list[index] = post.copyWith(
      isLiked: newIsLiked,
      likesCount: newLikesCount,
    );

    // 🔹 If there's already a pending call, just update the intended state and return
    if (_pendingLikeCalls[postId] != null) {
      return; // The pending call will check _lastIntendedLikeState before making API call
    }

    // 🔹 Start the debounced API call
    _pendingLikeCalls[postId] = _debouncedApiCall(postId, list);
  }

  Future<void> _debouncedApiCall(String postId, List<dynamic> list) async {
    // Wait for debounce period (let user finish rapid tapping)
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      // 🔹 Get the user's FINAL intended state
      final finalIntendedState = _lastIntendedLikeState[postId];
      print('finalIntendedState -- > $finalIntendedState');
      if (finalIntendedState == null) return;

      // 🔹 Get current post to check if we need to make API call
      final currentIndex = list.indexWhere((p) => p.id == postId);
      if (currentIndex == -1) return;

      final currentPost = list[currentIndex];
      final currentLikeState = currentPost.isLiked ?? false;

      // 🔹 Only make API call if the final intended state matches current UI state
      if (currentLikeState == finalIntendedState) {
        final response = await FeedRepo().likePost(
          postId: postId,
        );
        if (response.isSuccess) {
          likeDislikeResponse = ApiResponse.complete(response);

          // 🔹 Optional: Update with server response to ensure consistency
          if (response.data != null) {
            final serverPost = response.data;
            final finalIndex = list.indexWhere((p) => p.id == postId);
            if (finalIndex != -1) {
              list[finalIndex] = list[finalIndex].copyWith(
                isLiked: serverPost.isLiked ?? finalIntendedState,
                likesCount: serverPost.likesCount,
              );
            }
          }
        } else {
          // 🔹 Revert optimistic update on API failure
          _revertOptimisticUpdate(postId, list, finalIntendedState);
          likeDislikeResponse = ApiResponse.error('Failed to update like status');
        }
      }
    } catch (e) {
      // 🔹 Revert optimistic update on network error
      final finalIntendedState = _lastIntendedLikeState[postId];
      if (finalIntendedState != null) {
        _revertOptimisticUpdate(postId, list, finalIntendedState);
      }
      likeDislikeResponse = ApiResponse.error('Network error occurred');
    } finally {
      // 🔹 Cleanup
      _pendingLikeCalls[postId] = null;
      _lastIntendedLikeState.remove(postId);
    }
  }

  void _revertOptimisticUpdate(String postId, List<dynamic> list, bool intendedState) {
    final currentIndex = list.indexWhere((p) => p.id == postId);
    if (currentIndex != -1) {
      final currentPost = list[currentIndex];
      final revertedLikeState = !intendedState;
      final revertedCount = (currentPost.likesCount ?? 0) + (intendedState ? -1 : 1);

      list[currentIndex] = currentPost.copyWith(
        isLiked: revertedLikeState,
        likesCount: revertedCount,
      );
    }
  }

  /// Delete Post
  Future<void> postDelete({required String postId, required PostType type}) async {
    final list = getListByType(type);
    final index = list.indexWhere((p) => p.id == postId);

    if (index != -1) {
      final post = list[index];
      try {
        final response = await FeedRepo().deletePost(postId: postId);
        if (response.isSuccess) {
          // If the deleted post is a repost, decrement the original post's repost count
          if (post.is_reposted == true && post.children_post != null) {
            final originalIndex = list.indexWhere((p) => p.id == post.children_post!.id);
            if (originalIndex != -1) {
              list[originalIndex] = list[originalIndex].copyWith(
                repostCount: (list[originalIndex].repostCount ?? 0) - 1,
              );
            }
          }
          list.removeAt(index);
          Navigator.pop(navigator!.context);
          commonSnackBar(message: response.message);
          deletePostResponse = ApiResponse.complete(response);
        } else {
          deletePostResponse = ApiResponse.error('error');
        }
      } catch (_) {
        deletePostResponse = ApiResponse.error('error');
      }
    }
  }

  ///USER BLOCK...
  Future<void> userBlocked({required PostType type, required String otherUserId}) async {
    final list = getListByType(type);

    try {
      Map<String, dynamic> params = {
        ApiKeys.blockedTo: otherUserId,
        ApiKeys.type: BlockedType.full.label,
        ApiKeys.duration: 0
      };

      final response = await FeedRepo().blockUser(params: params);

      if (response.isSuccess) {
        blockUserResponse = ApiResponse.complete(response);
        BlockUserResponse blockUser = BlockUserResponse.fromJson(response.response?.data);
        list.removeWhere((p) {
          return p.user?.id == otherUserId;
        });
        Get.back();
        commonSnackBar(message: blockUser.message, isFromHomeScreen: true);
      } else {
        blockUserResponse = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      blockUserResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {}
  }

  /// Feed Report
  Future<void> postReport(
      {required PostType type, required String postId, required Map<String, dynamic> params}) async {
    final list = getListByType(type);
    final index = list.indexWhere((p) => p.id == postId);

    try {
      final response = await AuthRepo().report(params: params);
      Get.back();
      if (response.isSuccess) {
        reportPostResponse = ApiResponse.complete(response);
        if (index != -1) list.removeAt(index);
        showDialog(
            context: Get.context!,
            builder: (context) => Dialog(
                  child: Material(
                    color: Colors.transparent,
                    child: CustomSuccessSheet(
                      buttonText: AppStrings.gotIt,
                      title: AppStrings.youHaveReportedThisPost,
                      subTitle: AppStrings.thankYouForFeedback,
                      onPress: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ));
      } else {
        reportPostResponse = ApiResponse.error('error');
      }
    } catch (_) {
      Get.back();
      reportPostResponse = ApiResponse.error('error');
    }
  }

  /// Poll Answer
  Future<void> answerPoll({required int optionId, required String postId, required PostType type}) async {
    final list = getListByType(type);
    final index = list.indexWhere((p) => p.id == postId);

    if (index == -1) return;

    try {
      final response = await FeedRepo().answerPoll(params: {
        ApiKeys.optionId: optionId,
      }, postId: postId);

      if (response.isSuccess) {
        pollAnswerResponse = ApiResponse.complete(response);

        final postIndex = list.indexWhere((e) => e.id == postId);
        final currentUserId = userId;

        if (postIndex != -1) {
          final post = list[postIndex];
          final options = post..poll?.options;

          if (optionId >= 0 && optionId < (options.poll?.options.length ?? 0)) {
            final selectedOption = options.poll?.options[optionId];
            selectedOption?.votes ??= [];

            if (!selectedOption!.votes!.contains(currentUserId)) {
              selectedOption.votes?.add(currentUserId);

              // update the poll in the post
              final updatedPoll = post.poll?.copyWith(options: List.from(options.poll?.options ?? []));
              list[postIndex] = post.copyWith(poll: updatedPoll);
              // list[postIndex] = post.copyWith(poll: Poll(options: options.poll?.options??[],question: post.poll?.question));
            }
          }
        }
      } else {
        pollAnswerResponse = ApiResponse.error('error');
      }
    } catch (_) {
      pollAnswerResponse = ApiResponse.error('error');
    }
  }

  /// Save Post To LOCAL DB
  Future<void> savePostToLocalDB({required String postId, required PostType type, SortBy? sortBy}) async {
    final list = getListByType(type); // <- RxList<Post>

    final index = list.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final current = list[index];
    final isSaved = current.isPostSavedLocal ?? false;

    if (isSaved) {
      if (type == PostType.saved) {
        await HiveServices().deletePostById(postId);
        list.removeAt(index);
      } else {
        await HiveServices().deletePostById(postId);
        list.removeAt(index);
        list[index] = current.copyWith(isPostSavedLocal: false);
      }
      // commonSnackBar(message: 'Post removed.');
    } else {
      await HiveServices().savePostJson(current);
      list[index] = current.copyWith(isPostSavedLocal: true);
      // commonSnackBar(message: 'Post saved.');
    }
  }

  /// Get All Saved Posts
  void getAllSavedPost() {
    savedPosts.clear();
    List<Post> savedPostModels = HiveServices().getAllSavedPosts();
    savedPosts.addAll(savedPostModels);
    isLoading.value = false;
  }

  /// LocalSearch
  void applyFilter({required RxList<Post> targetList, required String query}) {
    if (query.isEmpty) {
      // nothing typed → restore original order (or do nothing)
      return;
    }

    final lower = query.toLowerCase();
    final filtered = targetList
        .where((post) =>
            post.type?.toLowerCase().contains(lower) == true ||
            post.subTitle?.toLowerCase().contains(lower) == true ||
            post.natureOfPost?.toLowerCase().contains(lower) == true ||
            post.title?.toLowerCase().contains(lower) == true ||
            post.location?.toLowerCase().contains(lower) == true ||
            post.likesCount?.toString().toLowerCase().contains(lower) == true ||
            post.commentsCount?.toString().toLowerCase().contains(lower) == true ||
            post.repostCount?.toString().toLowerCase().contains(lower) == true)
        .toList();

    targetList.assignAll(filtered);
  }

  Future updateCommentCount({
    required String postId,
    required PostType type,
    SortBy? sortBy,
    int? newCommentCount,
  }) async {
    // 1. Get the actual reactive list (assuming GetX RxList)
    final RxList<Post> list = getListByType(type);

    // 2. Find the specific post index
    final postIndex = list.indexWhere((p) => p.id == postId);

    if (postIndex == -1) return;

    // 3. Update ONLY that specific item using copyWith
    final post = list[postIndex];
    list[postIndex] = post.copyWith(
      commentsCount: newCommentCount,
    );

    // 4. Force the list to notify the UI (Crucial for deep updates)
    list.refresh();
  }

  // Future updateCommentCount(
  //     {required String postId,
  //     required PostType type,
  //     SortBy? sortBy,
  //     int? newCommentCount}) async {
  //   final list = getListByType(type);
  //   final postIndex = list.indexWhere((p) => p.id == postId);
  //
  //   if (postIndex == -1) return;
  //
  //   final post = list[postIndex];
  //   list[postIndex] = post.copyWith(
  //     commentsCount: newCommentCount,
  //   );
  // }

  /// Like/Unlike
  Future<void> getAllLikesUser({required String postId, bool isInitialLoading = false}) async {
    if (isInitialLoading) {
      allLikeUsersListLoading.value = true;
    }

    try {
      allLikeUsersList.clear();
      final response = await FeedRepo().allLikesOfPost(postId: postId);
      if (response.isSuccess) {
        allLikeUsersOfPostResponse = ApiResponse.complete(response);
        AllLikeUsersListModel allLikeUsersListModel = AllLikeUsersListModel.fromJson(response.response?.data);
        allLikeUsersList.value = allLikeUsersListModel.data ?? [];
      } else {
        allLikeUsersOfPostResponse = ApiResponse.error('error');
        commonSnackBar(message: response.message);
      }
    } catch (e) {
      allLikeUsersOfPostResponse = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
    } finally {
      allLikeUsersListLoading.value = false;
    }
  }

  ///new home api call
  Rx<ApiResponse> feedResponse = ApiResponse.initial('Initial').obs;

  // RxList<Post> mixedFeed = <Post>[].obs;
  RxString cursor = "".obs;
  RxBool isLoadingHome = false.obs;
  RxBool hasMoreData = true.obs;
  final int limit = 40;
  dynamic currentLat, currentLong;

  // RxList<ShortFeedItem> shortFeedItem = <ShortFeedItem>[].obs;
  // RxList<ShortFeedItem> latestShortsPosts = <ShortFeedItem>[].obs;
  late ShortsController? shortsController;

  Future<void> getFeed({bool refresh = false}) async {
    if (Get.isRegistered<ShortsController>()) {
      shortsController = Get.find<ShortsController>();
    } else {
      shortsController = Get.put(ShortsController());
    }
    if (isLoadingHome.value) return;
    if (refresh) {
      // Only a cold open (nothing on screen yet) benefits from the cache; a
      // pull-to-refresh that already has content keeps the original spinner so
      // we don't flash stale posts over live ones.
      final bool isColdOpen = allPosts.isEmpty;
      cursor.value = "";
      allPosts.clear();
      shortsController?.latestShortsPosts.clear();
      hasMoreData.value = true;
      if (isColdOpen) {
        // Paint the last-cached feed instantly so the Social tab isn't stuck on
        // a spinner on first open; the live fetch below replaces it once it
        // lands. On a cache miss this falls back to the original loading state.
        await _hydrateFeedFromCache();
      } else {
        feedResponse.value = ApiResponse.loading();
      }
    }
    if (!hasMoreData.value) return;
    isLoadingHome.value = true;
    try {
      // if ((LocationService.lat == 0.0) && (LocationService.lng == 0.0))
      //   await LocationService.fetchOnlyLocation();
      final timestamp = cursor.value;
      // Empty cursor means we're loading the first page (initial open or
      // refresh) — that fresh page must REPLACE any cache-hydrated content
      // rather than append to it (which would duplicate posts).
      final bool isFirstPage = timestamp.isEmpty;

      ResponseModel responseModel = await HomeFeedRepo().homeFeedRepo(queryParam: {
        ApiKeys.limit: limit,
        ApiKeys.refresh: refresh.toString(),
        if (cursor.value.isNotEmpty) ApiKeys.cursor: timestamp,
        // if (LocationService.lat > 0) ApiKeys.lat: LocationService.lat,
        // if (LocationService.lng > 0) ApiKeys.lon: LocationService.lng,
      });
      if (responseModel.isSuccess) {
        final homeFeedResponse = HomeFeedResponse.fromJson(responseModel.response?.data);

        if (homeFeedResponse.feed.isNotEmpty) {
          if (isFirstPage) {
            // Replace cache-hydrated (stale) content with the live first page.
            allPosts.assignAll(homeFeedResponse.feed);
            shortsController?.latestShortsPosts.clear();
          } else {
            allPosts.addAll(homeFeedResponse.feed);
          }
          for (final data in homeFeedResponse.feed) {
            if (data.type == "short_video") {
              shortsController?.latestShortsPosts.add(getVideoData(data));
            }
          }
          cursor.value = homeFeedResponse.metaData?.next_cursor ?? "";
          if (homeFeedResponse.feed.length < limit) {
            hasMoreData.value = false;
          }

          feedResponse.value = ApiResponse.complete(homeFeedResponse);

          // Cache the live first page (capped to 10 posts) for instant paint on
          // the next open.
          if (isFirstPage) {
            await _cacheFeed(homeFeedResponse.feed);
          }
        } else {
          // Server genuinely has nothing — drop any stale cache we hydrated so
          // the empty state shows correctly.
          if (isFirstPage) allPosts.clear();
          hasMoreData.value = false;
          feedResponse.value = ApiResponse.complete(homeFeedResponse);
        }
      } else {
        // Keep showing cache-hydrated content on failure; only surface an error
        // when there's nothing cached to fall back on.
        if (allPosts.isEmpty) {
          feedResponse.value = ApiResponse.error('Failed to load feed');
        }
      }
    } catch (e) {
      logs("ERROR===== ${e}");
      if (allPosts.isEmpty) {
        feedResponse.value = ApiResponse.error(e.toString());
      }
    } finally {
      isLoadingHome.value = false;
    }
  }

  /// How long a cached Social-tab feed stays usable offline before it's treated
  /// as stale and re-fetched from scratch.
  static const Duration _feedCacheTtl = Duration(days: 1);

  /// Loads the last-cached Social-tab feed into [allPosts] so the tab paints
  /// instantly on open. Sets [feedResponse] to COMPLETE on a fresh hit (content
  /// is ready to render) or LOADING on a miss / stale entry (original spinner
  /// behaviour). Stale entries are dropped.
  Future<void> _hydrateFeedFromCache() async {
    try {
      final cached = await socialFeedCache.get(userId);
      final rawList = cached?['feed'];
      if (cached != null && rawList is List && rawList.isNotEmpty) {
        if (_isCacheStale(cached['cachedAt'], _feedCacheTtl)) {
          await socialFeedCache.clear();
        } else {
          final cachedPosts = rawList
              .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          allPosts.assignAll(cachedPosts);
          for (final data in cachedPosts) {
            if (data.type == "short_video") {
              shortsController?.latestShortsPosts.add(getVideoData(data));
            }
          }
          feedResponse.value = ApiResponse.complete(
            HomeFeedResponse(success: true, feed: cachedPosts, metaData: null),
          );
          return;
        }
      }
    } catch (e) {
      logs("feed cache hydrate error: $e");
    }
    feedResponse.value = ApiResponse.loading();
  }

  /// Persists the first [10] posts of the live feed (with a timestamp for
  /// expiry) for the next cold open.
  Future<void> _cacheFeed(List<Post> feed) async {
    try {
      await socialFeedCache.save(userId, {
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'feed': feed.take(10).map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      logs("feed cache save error: $e");
    }
  }

  /// True when [cachedAtMs] is missing or older than [ttl].
  bool _isCacheStale(dynamic cachedAtMs, Duration ttl) {
    if (cachedAtMs is! int) return true;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    return DateTime.now().difference(cachedAt) > ttl;
  }

  void handleScrollToBottomNew() {
    if (!isLoadingHome.value && hasMoreData.value) {
      getFeed();
    }
  }
}
