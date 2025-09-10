import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/all_like_users_list_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/home_cache_service.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
 
import 'package:BlueEra/features/common/feed/models/block_user_response.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_success_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeedController extends GetxController{
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
  RxBool isLoading = true.obs;
  RxBool isTargetHasMoreData = true.obs;
  RxBool isTargetMoreDataLoading = false.obs;
  int allPage = 1, myPage = 1, otherPage = 1, latestPostsPage = 1, popularPostsPage = 1, oldestPostsPage = 1;
  var postFilterType = "latest";

  // New variables for enhanced pagination
  final Map<PostType, List<Post>> _cachedPosts = {};
  final Map<PostType, int> _displayedCounts = {};
  final int initialFetchLimit = 40;
  final int displayLimit = 20;

  RxList<LikeUserData> allLikeUsersList = <LikeUserData>[].obs;
  RxBool allLikeUsersListLoading = true.obs;

  /// Fetch posts based on filter
  Future<void> getPostsByType(
      PostType type,
      { bool isInitialLoad = false,
        bool refresh = false,
        String? id,
        String? query
      }) async {
    switch (type) {
      case PostType.all:
        await _fetchPostsWithEnhancedCache(
            page: allPage,
            type: type,
            isInitialLoad: isInitialLoad,
            targetList: allPosts,
            onPageIncrement: () => allPage++,
            refresh: refresh,
            id: id,
            query: query
        );
        break;
      case PostType.myPosts:
        await _fetchPostsWithEnhancedPagination(
          page: myPage,
          type: type,
          isInitialLoad: isInitialLoad,
          targetList: myPosts,
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
          onPageIncrement: () => oldestPostsPage++,
          refresh: refresh,
          id: id,
        );
        break;
      case PostType.saved:
        getAllSavedPost();
        break;
    }
  }

  /// Enhanced fetch with cache integration for All Posts tab
  Future<void> _fetchPostsWithEnhancedCache({
    required int page,
    required PostType type,
    required bool isInitialLoad,
    required RxList<Post> targetList,
    required VoidCallback onPageIncrement,
    required bool refresh,
    String? id,
    String? query
  }) async {
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
            query: query
        );
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
        onPageIncrement: onPageIncrement,
        refresh: refresh,
        id: id,
        query: query
    );
  }

  /// Enhanced background fetch that integrates with cache
  Future<void> _fetchEnhancedDataInBackground({
    required int page,
    required PostType type,
    required RxList<Post> targetList,
    required VoidCallback onPageIncrement,
    required bool refresh,
    String? id,
    String? query
  }) async {
    try {
      print('🔄 Starting enhanced background fetch for fresh data...');

      final Map<String, dynamic> queryParams = {
        ApiKeys.page: page,
        ApiKeys.limit: initialFetchLimit, // Fetch 40 items for enhancement
        ApiKeys.filter: postFilterType
      };

      if(query == null){
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

          // Set pagination state
          if (postResponse.data.length < initialFetchLimit) {
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

  Future<void> _fetchPostsWithEnhancedPagination({
    required int page,
    required PostType type,
    required bool isInitialLoad,
    required RxList<Post> targetList,
    required VoidCallback onPageIncrement,
    required bool refresh,
    String? id,
    String? query
  }) async {
    print('🔄 Enhanced pagination - page: $page, type: $type, isInitialLoad: $isInitialLoad');

    if (isInitialLoad) {
      page = 1;
      isTargetHasMoreData.value = true;
      isTargetMoreDataLoading.value = false;
      _cachedPosts[type] = [];
      _displayedCounts[type] = 0;
    }

    if (isTargetHasMoreData.isFalse || isTargetMoreDataLoading.isTrue) return;

    // Check if we have cached data to display first
    if (_hasMoreCachedData(type) && !isInitialLoad) {
      _displayMoreCachedData(type, targetList);
      return;
    }

    // Set loading state
    // if (!isInitialLoad) {
    //   isTargetMoreDataLoading.value = true;
    // } else {
    //   // isLoading.value = true;
    // }

    final Map<String, dynamic> queryParams = {
      ApiKeys.page: page,
      ApiKeys.limit: isInitialLoad ? initialFetchLimit : displayLimit,
      ApiKeys.filter: postFilterType
    };

    if (query == null) {
      queryParams[ApiKeys.refresh] = refresh;
    }

    ResponseModel response;
    switch (type) {
      case PostType.all:
        if (query == null) {
          response = await FeedRepo().fetchAllPosts(queryParams: queryParams);
        } else {
          queryParams[ApiKeys.query] = query;
          response = await FeedRepo().postsFeedSearch(queryParams: queryParams);
        }
        break;
      case PostType.myPosts:
        response = await FeedRepo().getAllMyPosts(queryParams: queryParams);
        break;
      case PostType.otherPosts:
        if (id != null) queryParams[ApiKeys.authorId] = id;
        response = await FeedRepo().getAllOtherPosts(queryParams: queryParams);
        break;
      case PostType.latest || PostType.popular || PostType.oldest:
        if (id != null) queryParams[ApiKeys.authorId] = id;
        queryParams[ApiKeys.filter] = (type == PostType.latest)
            ? 'latest'
            : (type == PostType.popular)
            ? 'popular'
            : 'oldest';
        response = await ChannelRepo().getChannelAllPosts(queryParams: queryParams);
        break;
      default:
        return;
    }

    try {
      if (response.isSuccess) {
        postsResponse.value = ApiResponse.complete(response);
        final postResponse = PostResponse.fromJson(response.response?.data);

        if (page == 1) {
          // Initial load: cache all data, display first batch
          _cachedPosts[type] = List.from(postResponse.data);
          _displayedCounts[type] = displayLimit.clamp(0, postResponse.data.length);

          // Display only first batch
          targetList.value = postResponse.data.take(displayLimit).toList();

          print('📦 Initial enhanced load: Fetched ${postResponse.data.length}, Displaying ${targetList.length}, Cached ${_cachedPosts[type]!.length}');

          // Update cache service for All Posts tab
          if (type == PostType.all && postResponse.data.isNotEmpty) {
            await HomeCacheService().cachePosts(postResponse.data.take(displayLimit).toList());
            print('💾 Updated cache service with ${displayLimit} posts for All Posts tab');
          }
        } else {
          // Subsequent loads: add new data to cache
          _cachedPosts[type]!.addAll(postResponse.data);
          print('📦 Added ${postResponse.data.length} new posts to cache. Total cached: ${_cachedPosts[type]!.length}');
        }

        // Check if we have more data available from server
        final expectedLimit = isInitialLoad ? initialFetchLimit : displayLimit;
        if (postResponse.data.length < expectedLimit) {
          print('📄 No more data from server');
          isTargetHasMoreData.value = false;
        } else {
          print('📄 More data available from server');
          isTargetHasMoreData.value = true;
          onPageIncrement();
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
        getPostsByType(PostType.all);
        break;
      case PostType.myPosts:
        getPostsByType(PostType.myPosts);
        break;
      case PostType.otherPosts:
        getPostsByType(PostType.otherPosts);
        break;
      case PostType.latest:
        getPostsByType(PostType.latest);
        break;
      case PostType.popular:
        getPostsByType(PostType.popular);
        break;
      case PostType.oldest:
        getPostsByType(PostType.oldest);
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
      PostType.all               => allPosts,
      PostType.myPosts           => myPosts,
      PostType.otherPosts        => otherPosts,
      PostType.saved             => savedPosts,
      PostType.latest            => latestPosts,
      PostType.popular           => popularPosts,
      PostType.oldest            => oldestPosts,
    };

    // hydrate local flag only once (if not already done)
    if (list.isNotEmpty) {
      list.assignAll(
        list.map(
              (p) => p.copyWith(isPostSavedLocal: HiveServices().isPostSaved(p.id)),
        ).toList(),
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

    try {
      final response = await FeedRepo().deletePost(postId: postId);
      if (response.isSuccess) {
        if (index != -1) list.removeAt(index);
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

  ///USER BLOCK...
  Future<void> userBlocked({required PostType type, required String otherUserId}) async {
    final list = getListByType(type);

    try {
      Map<String, dynamic> params = {
        ApiKeys.blockedTo:  otherUserId,
        ApiKeys.type: BlockedType.full.label,
        ApiKeys.duration:  0
      };

      final response = await FeedRepo().blockUser(params: params);

      if (response.isSuccess) {
        blockUserResponse = ApiResponse.complete(response);
        BlockUserResponse blockUser = BlockUserResponse.fromJson(response.response?.data);
        list.removeWhere((p) {
          return p.authorId == otherUserId;
        });
        Get.back();
        commonSnackBar(message: blockUser.message, isFromHomeScreen: true);
      } else {
        blockUserResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      blockUserResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
    }
  }

  /// Feed Report
  Future<void> postReport({required PostType type, required String postId, required Map<String, dynamic> params}) async {
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
                  buttonText: AppLocalizations.of(context)!.gotIt,
                  title: AppLocalizations.of(context)!.youHaveReportedThisPost,
                  subTitle: AppLocalizations.of(context)!.reportSuccessMessage,
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
          final options = post.poll?.options;

          if (options != null && optionId >= 0 && optionId < options.length) {
            final selectedOption = options[optionId];
            selectedOption.votes ??= [];

            if (!selectedOption.votes!.contains(currentUserId)) {
              selectedOption.votes!.add(currentUserId);

              // update the poll in the post
              final updatedPoll = post.poll!.copyWith(options: List.from(options));
              list[postIndex] = post.copyWith(poll: updatedPoll);
            }
          }
        }
      }
      else {
        pollAnswerResponse = ApiResponse.error('error');
      }
    } catch (_) {
      pollAnswerResponse = ApiResponse.error('error');
    }
  }

  /// Save Post To LOCAL DB
  Future<void> savePostToLocalDB({required String postId, required PostType type, SortBy? sortBy}) async {
    final list = getListByType(type);   // <- RxList<Post>

    final index = list.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final current = list[index];
    final isSaved = current.isPostSavedLocal ?? false;

    if (isSaved) {
      if(type == PostType.saved){
        await HiveServices().deletePostById(postId);
        list.removeAt(index);
      }else{
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
  }

  /// LocalSearch
  void applyFilter({required RxList<Post> targetList, required String query}) {
    if (query.isEmpty) {
      // nothing typed → restore original order (or do nothing)
      return;
    }

    final lower = query.toLowerCase();
    final filtered = targetList.where((post) =>
    post.type?.toLowerCase().contains(lower) == true ||
    post.subTitle?.toLowerCase().contains(lower) == true ||
    post.natureOfPost?.toLowerCase().contains(lower) == true ||
    post.title?.toLowerCase().contains(lower) == true ||
    post.location?.toLowerCase().contains(lower) == true ||
    post.likesCount?.toString().toLowerCase().contains(lower) == true ||
    post.commentsCount?.toString().toLowerCase().contains(lower) == true ||
    post.repostCount?.toString().toLowerCase().contains(lower) == true).toList();

    targetList.assignAll(filtered);
  }

  void updateCommentCount({required String postId, required PostType type, SortBy? sortBy, int? newCommentCount}){
    final list = getListByType(type);
    final postIndex = list.indexWhere((p) => p.id == postId);

    if (postIndex == -1) return;

    final post = list[postIndex];
    list[postIndex] = post.copyWith(
      commentsCount: newCommentCount,
    );
  }

  /// Like/Unlike
  Future<void> getAllLikesUser({required String postId, bool isInitialLoading = false}) async {

    if(isInitialLoading){
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
    }finally{
      allLikeUsersListLoading.value = false;
    }
  }

}