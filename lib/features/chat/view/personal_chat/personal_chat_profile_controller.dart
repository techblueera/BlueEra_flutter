import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/user_testimonial_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalChatProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  final List<String> tabs = const [
    'Overview',
    'Testimonials',
    'Posts',
    'Shorts',
    'Videos',
  ];
  
  ApiResponse postsResponse = ApiResponse.initial('Initial');
  Rx<ApiResponse> getTestimonialResponse = ApiResponse.initial('Initial').obs;
  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
    RxBool isTargetHasMoreData = true.obs;
  RxBool isTargetMoreDataLoading = false.obs;  
  

    final Map<PostType, List<Post>> _cachedPosts = {};
  final Map<PostType, int> _displayedCounts = {};
  final int initialFetchLimit = 40;
  final int displayLimit = 20;
   RxBool isLoading = true.obs;
   var postFilterType = "latest";
  RxList<Testimonials>? testimonialsList = <Testimonials>[].obs;
   RxList<Post> otherPosts = <Post>[].obs;
    int allPage = 1, myPage = 1, otherPage = 1, latestPostsPage = 1, popularPostsPage = 1, oldestPostsPage = 1;
    Future<void> getTestimonialController({required String? userID}) async {
    try {
      testimonialsList?.clear();
      getTestimonialResponse.value = ApiResponse.initial('Initial');

      ///FOR NOW WE SET
      ResponseModel responseModel =
          await UserRepo().getTestimonialRepo(userId: userID);
      if (responseModel.isSuccess) {
        UserTestimonialModel userTestimonialModel =
            UserTestimonialModel.fromJson(responseModel.response?.data);
        testimonialsList?.value = userTestimonialModel.testimonials ?? [];
        getTestimonialResponse.value = ApiResponse.complete(responseModel);
      } else {
        getTestimonialResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getTestimonialResponse.value = ApiResponse.error('error');
    }
  }
  Future<void> getPostsByType(
      PostType type,
      { bool isInitialLoad = false,
        bool refresh = false,
        String? id,
        String? query
      }) async {
  await _fetchPostsWithEnhancedPagination(
          page: otherPage,
          type: type,
          isInitialLoad: isInitialLoad,
          targetList: otherPosts,
          onPageIncrement: () => otherPage++,
          refresh: refresh,
          id: id,
        );
        }
     Future<void> _fetchPostsWithEnhancedPagination({
  required int page,
  required PostType type,
  required bool isInitialLoad,
  required RxList<Post> targetList,
  required VoidCallback onPageIncrement,
  required bool refresh,
  String? id,
  String? query,
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

  final Map<String, dynamic> queryParams = {
    ApiKeys.page: page,
    ApiKeys.limit: isInitialLoad ? initialFetchLimit : displayLimit,
    ApiKeys.filter: postFilterType,
  };

  if (query == null) {
    queryParams[ApiKeys.refresh] = refresh;
  }

  ResponseModel response;

  // ✅ Only keep otherPosts API
  if (type == PostType.otherPosts) {
    if (id != null) queryParams[ApiKeys.authorId] = id;
    response = await FeedRepo().getAllOtherPosts(queryParams: queryParams);
  } else {
    return;
  }

  try {
    if (response.isSuccess) {
      postsResponse = ApiResponse.complete(response);
      final postResponse = PostResponse.fromJson(response.response?.data);

      if (page == 1) {
        // Initial load: cache all data, display first batch
        _cachedPosts[type] = List.from(postResponse.data);
        _displayedCounts[type] = displayLimit.clamp(0, postResponse.data.length);

        // Display only first batch
        targetList.value = postResponse.data.take(displayLimit).toList();

        print(
            '📦 Initial enhanced load: Fetched ${postResponse.data.length}, '
            'Displaying ${targetList.length}, '
            'Cached ${_cachedPosts[type]!.length}');
      } else {
        // Subsequent loads: add new data to cache
        _cachedPosts[type]!.addAll(postResponse.data);
        print(
            '📦 Added ${postResponse.data.length} new posts to cache. '
            'Total cached: ${_cachedPosts[type]!.length}');
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
      postsResponse = ApiResponse.error('error');
      commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
    }
  } catch (e) {
    postsResponse = ApiResponse.error('error');
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
    // if (nextDisplayCount >= cachedPosts.length && isTargetHasMoreData.isTrue) {
    //   _triggerBackgroundFetch(type);
    // }
  }



}
