import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/home_cache_service.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/feed/hive_model/video_hive_model.dart';
import 'package:BlueEra/features/common/feed/models/block_user_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class ShortsController extends GetxController{
  ApiResponse personalizedShortsResponse = ApiResponse.initial('Initial');
  ApiResponse trendingShortsResponse = ApiResponse.initial('Initial');
  ApiResponse nearByShortsResponse = ApiResponse.initial('Initial');
  ApiResponse shortsResponse = ApiResponse.initial('Initial');
  ApiResponse deleteShortResponse = ApiResponse.initial('Initial');
  ApiResponse savedShortsResponse = ApiResponse.initial('Initial');
  ApiResponse blockUserResponse = ApiResponse.initial('Initial');

  RxList<VideoFeedItem> trendingVideoFeedPosts = <VideoFeedItem>[].obs;
  int trendingVideoFeedCurrentPage = 1;
  RxBool isFirstLoadTrending = true.obs;
  bool trendingVideoFeedHasMore = true;
  RxBool trendingVideoFeedIsLoadingMore = false.obs;

  RxList<VideoFeedItem> personalizedVideoFeedPosts = <VideoFeedItem>[].obs;
  int personalizedVideoFeedCurrentPage = 1;
  RxBool isFirstLoadNearBy= true.obs;
  bool personalizedVideoFeedHasMore = true;
  RxBool personalizedVideoIsLoadingMore = false.obs;

  RxList<VideoFeedItem> nearByVideoFeedPosts = <VideoFeedItem>[].obs;
  int nearByVideoFeedCurrentPage = 1;
  RxBool isFirstLoadPersonalized = true.obs;
  bool nearByVideoFeedHasMore = true;
  RxBool nearByVideoFeedIsLoadingMore = false.obs;
  double? lat;
  double? lng;

  int maxDistance = 10000;
  int limit = 20;

  /// Channel Shorts
  RxList<VideoFeedItem> allChannelShorts = <VideoFeedItem>[].obs;
  int allChannelShortsPage = 1;
  bool isAllShortsHasMore = true;
  RxBool isAllShortsIsLoadingMore = false.obs;

  ///Channel Shorts(Trending, Popular, Oldest)
  RxList<VideoFeedItem> latestShortsPosts = <VideoFeedItem>[].obs;
  RxList<VideoFeedItem> popularShortsPosts = <VideoFeedItem>[].obs;
  RxList<VideoFeedItem> oldestShortsPosts = <VideoFeedItem>[].obs;
  RxList<VideoFeedItem> underProgressShortsPosts = <VideoFeedItem>[].obs;
  RxList<VideoFeedItem> draftShortsPosts = <VideoFeedItem>[].obs;
  int latestShortsPage = 1, popularShortsPage = 1, oldestShortsPage = 1, underProgressShortsPage = 1, draftShortsPage = 1;
  RxBool isLatestShortsLoading = true.obs, isPopularShortsLoading = true.obs, isOldestShortsLoading = true.obs, isUnderProgressShortsLoading = true.obs, isDraftShortsLoading = true.obs;
  RxBool isLatestShortsMoreDataLoading = false.obs, isPopularShortsMoreDataLoading = false.obs, isOldestShortsMoreDataLoading = false.obs,  isUnderProgressShortsMoreDataLoading = false.obs, isDraftShortsMoreDataLoading = false.obs;
  bool isLatestShortsHasMoreData = true, isPopularShortsHasMoreData = true, isOldestShortsHasMoreData = true, isUnderProgressShortsHasMoreData = true, isDraftShortsHasMoreData = true;

  /// Saved Videos
  RxList<VideoFeedItem> savedShorts = <VideoFeedItem>[].obs;

  ///GET ALL Feed Trending(In Shorts)...
  Future<void> getAllFeedTrending({
    bool isInitialLoad = false,
    bool refresh = false,
    String query = ''
  }) async {
    if (isInitialLoad) {
      trendingVideoFeedCurrentPage = 1;
      trendingVideoFeedHasMore = true;
      trendingVideoFeedIsLoadingMore.value = false;
      
      // Try to get cached shorts first
      if (trendingVideoFeedCurrentPage == 1) {
        final cachedShorts = await HomeCacheService().getCachedShorts();
        if (cachedShorts != null && cachedShorts.isNotEmpty) {
          print('📱 Showing cached shorts: ${cachedShorts.length} items');
          trendingVideoFeedPosts.value = cachedShorts;
          isFirstLoadTrending.value = false;
          
          // Fetch fresh data in background
          _fetchShortsInBackground(queryParams: {
            ApiKeys.type: 'short',
            ApiKeys.page: trendingVideoFeedCurrentPage.toString(),
            ApiKeys.limit: limit,
            ApiKeys.userId: userId,
            ApiKeys.refresh: refresh,
          });
          return;
        } else {
          print('📱 No cached shorts found, fetching from API...');
        }
      }
    }

    if (!trendingVideoFeedHasMore || trendingVideoFeedIsLoadingMore.isTrue) return;

    try {
      trendingVideoFeedIsLoadingMore.value = true;

      final queryParams = {
        ApiKeys.type: 'short',
        ApiKeys.page: trendingVideoFeedCurrentPage.toString(),
        ApiKeys.limit: limit, // or whatever your backend supports
        ApiKeys.userId: userId
      };

      ResponseModel response;
      if(query.isEmpty){
        queryParams[ApiKeys.refresh] = refresh;
        response = await FeedRepo().getAllFeedTrending(queryParams: queryParams);
      }else{
        queryParams[ApiKeys.query] = query;
        response = await FeedRepo().videosFeedSearch(queryParams: queryParams);
      }

      if (response.isSuccess) {
        trendingShortsResponse = ApiResponse.complete(response);
        final videoFeedModelResponse = VideoResponse.fromJson(response.response?.data);

        final videos = videoFeedModelResponse.data?.videos ?? [];

          if(trendingVideoFeedCurrentPage == 1){
            trendingVideoFeedPosts.value = videos;
            
            // Cache shorts
            if (videos.isNotEmpty) {
              await HomeCacheService().cacheShorts(videos);
              print('💾 Cached ${videos.length} shorts');
            }
          }else{
            trendingVideoFeedPosts.addAll(videos);
          }

        if (videoFeedModelResponse.pagination?.hasMore??false) {
          trendingVideoFeedCurrentPage++;
          } else {
          trendingVideoFeedHasMore = false;
        }

      } else {
        logs("trendingShortsResponse ERROR 1");
        trendingShortsResponse = ApiResponse.error('error');
        // commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("trendingShortsResponse ERROR 2");
      trendingShortsResponse = ApiResponse.error('error');
      // commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isFirstLoadTrending.value = false;
      trendingVideoFeedIsLoadingMore.value = false;
    }
  }

  /// Fetch shorts in background for cache updates
  Future<void> _fetchShortsInBackground({required Map<String, dynamic> queryParams}) async {
    try {
      ResponseModel response = await FeedRepo().getAllFeedTrending(queryParams: queryParams);
      
      if (response.isSuccess) {
        final videoFeedModelResponse = VideoResponse.fromJson(response.response?.data);
        final videos = videoFeedModelResponse.data?.videos ?? [];
        
        if (videos.isNotEmpty) {
          // Cache shorts
          await HomeCacheService().cacheShorts(videos);
          
          // Update the UI with fresh data
          trendingVideoFeedPosts.value = videos;
        }
      }
    } catch (e) {
      // Silently fail for background fetch
      print('Background shorts fetch failed: $e');
    }
  }

  ///GET ALL Feed Personalized(In Shorts)...
  Future<void> getAllFeedPersonalized({
    bool isInitialLoad = false,
    bool refresh = false,
    String query = ''
  }) async {
    if (isInitialLoad) {
      personalizedVideoFeedCurrentPage = 1;
      personalizedVideoFeedHasMore = true;
      personalizedVideoIsLoadingMore.value = false;
    }

    if (!personalizedVideoFeedHasMore || personalizedVideoIsLoadingMore.isTrue) return;

    try {
      personalizedVideoIsLoadingMore.value = true;
      final queryParams = {
        ApiKeys.userId: userId,
        ApiKeys.page: personalizedVideoFeedCurrentPage.toString(),
        ApiKeys.limit: limit, // or whatever your backend supports
      };

      ResponseModel response;
      queryParams[ApiKeys.refresh] = refresh;
      if(query.isNotEmpty){
        queryParams[ApiKeys.query] = query;
        response = await FeedRepo().videosFeedSearch(queryParams: queryParams);
      }else{
        response = await FeedRepo().getAllFeedPersonalized(queryParams: queryParams);
      }

      if (response.isSuccess) {
        personalizedShortsResponse = ApiResponse.complete(response);
        final videoFeedModelResponse = VideoResponse.fromJson(response.response?.data);

        final videos = videoFeedModelResponse.data?.videos ?? [];

        if(personalizedVideoFeedCurrentPage == 1){
          personalizedVideoFeedPosts.value = videos;
        }else{
          personalizedVideoFeedPosts.addAll(videos);
        }

        if (videoFeedModelResponse.pagination?.hasMore??false) {
          personalizedVideoFeedCurrentPage++;
        } else {
          personalizedVideoFeedHasMore = false;
        }


      } else {
        logs("personalizedShortsResponse ERROR 1");

        personalizedShortsResponse = ApiResponse.error('error');
        // commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("personalizedShortsResponse ERROR 2");

      personalizedShortsResponse = ApiResponse.error('error');
      // commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isFirstLoadPersonalized.value = false;
      personalizedVideoIsLoadingMore.value = false;
    }
  }

  Future<({double? lat, double? lng})> fetchLocation({required BuildContext context}) async {
    try {
      final locationData = await LocationService.fetchLocation(context);
      if (locationData != null && locationData["position"] != null) {
        final position = locationData["position"];
        if (position is Position) {
          return (lat: position.latitude, lng: position.longitude);
        }
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }

    return (lat: null, lng: null);
  }

  ///GET ALL Feed Near By(In Shorts)...
  Future<void> getAllFeedNearBy({
    bool isInitialLoad = false,
    bool refresh = false,
    double lat = 0.0,
    double lng = 0.0,
    String query = ''
  }) async {
    if (isInitialLoad) {
      nearByVideoFeedCurrentPage = 1;
      nearByVideoFeedHasMore = true;
      nearByVideoFeedIsLoadingMore.value = false;
    }

    if (!nearByVideoFeedHasMore || nearByVideoFeedIsLoadingMore.isTrue) return;

    try {
      nearByVideoFeedIsLoadingMore.value = true;
      final queryParams = {
        ApiKeys.page: nearByVideoFeedCurrentPage.toString(),
        ApiKeys.limit: limit,
        ApiKeys.lat: lat,
        ApiKeys.lng: lng,
        ApiKeys.maxDistance: maxDistance,
        ApiKeys.userId: userId,
      };

      ResponseModel response;
      queryParams[ApiKeys.refresh] = refresh;

      if(query.isNotEmpty){
        queryParams[ApiKeys.query] = query;
        response = await FeedRepo().videosFeedSearch(queryParams: queryParams);
      }else{
        response = await FeedRepo().getAllFeedNearby(queryParams: queryParams);
      }

      if (response.isSuccess) {
        nearByShortsResponse = ApiResponse.complete(response);
        final videoFeedModelResponse = VideoResponse.fromJson(response.response?.data);
        final videos = videoFeedModelResponse.data?.videos ?? [];

        if(nearByVideoFeedCurrentPage == 1){
          nearByVideoFeedPosts.value = videos;
        }else{
          nearByVideoFeedPosts.addAll(videos);
        }

        if (videoFeedModelResponse.pagination?.hasMore??false) {
          nearByVideoFeedCurrentPage++;
        } else {
          nearByVideoFeedHasMore = false;
        }

      } else {
        logs("nearByShortsResponse ERROR 1");

        nearByShortsResponse =  ApiResponse.error('error');
        // commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      print('stack trace--> $s');
      nearByShortsResponse = ApiResponse.error('error');
      logs("nearByShortsResponse ERROR 2");

      // commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isFirstLoadNearBy.value = false;
      nearByVideoFeedIsLoadingMore.value = false;
    }
  }

  bool get anyFirstLoadRunning =>
      (isFirstLoadTrending.value && trendingVideoFeedPosts.isEmpty) ||
          (isFirstLoadNearBy.value && nearByVideoFeedPosts.isEmpty) ||
          (isFirstLoadPersonalized.value && personalizedVideoFeedPosts.isEmpty);

  ///GET CHANNEL ALL SHORTS...
  Future<void> getAllChannelShorts({bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      allChannelShortsPage = 1;
      allChannelShorts.clear();
      isAllShortsHasMore = true;
    }

    if (!isAllShortsHasMore || isAllShortsIsLoadingMore.isTrue) return;

    try {

      final queryParams = {
        ApiKeys.type: 'short',
        ApiKeys.channelId: channelId,
        ApiKeys.limit: limit,
        ApiKeys.page: allChannelShortsPage,
      };

      final response = await FeedRepo().getAllFeedTrending(queryParams: queryParams);

      if (response.isSuccess) {
        trendingShortsResponse = ApiResponse.complete(response);
        final videoFeedModelResponse = VideoResponse.fromJson(response.response?.data);

        final videos = videoFeedModelResponse.data?.videos ?? [];

        if (videos.isNotEmpty) {
          trendingVideoFeedPosts.addAll(videos);
          trendingVideoFeedCurrentPage++;
        } else {
          isAllShortsHasMore = false;
        }
      } else {
        trendingShortsResponse = ApiResponse.error('error');
        // commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      trendingShortsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      // isLoading.value = false;
      isAllShortsIsLoadingMore.value = false;
    }
  }

  ///GET CHANNEL SHORTS(TRENDING, POPULAR, OLDEST)...
  Future<void> getShortsByType(
      Shorts shorts,
      String channelOrUserId,
      String authorId,
      bool isOwnChannel, {
        bool isInitialLoad = false,
        bool refresh = false,
        Map<String, Object>? extraParams,
      }) async {
    switch (shorts) {
      case Shorts.latest:
        await _fetchShorts(
          shorts: shorts,
          page: latestShortsPage,
          isInitialLoad: isInitialLoad,
          targetInitialLoading: isLatestShortsLoading,
          isTargetHasMoreData: isLatestShortsHasMoreData,
          isTargetMoreDataLoading: isLatestShortsMoreDataLoading,
          targetList: latestShortsPosts,
          onPageIncrement: () => latestShortsPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnChannel: isOwnChannel,
          extraParams: extraParams,
        );
        break;

      case Shorts.popular:
        await _fetchShorts(
          shorts: shorts,
          page: popularShortsPage,
          isInitialLoad: isInitialLoad,
          targetInitialLoading: isPopularShortsLoading,
          isTargetHasMoreData: isPopularShortsHasMoreData,
          isTargetMoreDataLoading: isPopularShortsMoreDataLoading,
          targetList: popularShortsPosts,
          onPageIncrement: () => popularShortsPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnChannel: isOwnChannel,
          extraParams: extraParams,
        );
        break;

      case Shorts.oldest:
        await _fetchShorts(
          shorts: shorts,
          page: oldestShortsPage,
          isInitialLoad: isInitialLoad,
          targetList: oldestShortsPosts,
          targetInitialLoading: isOldestShortsLoading,
          isTargetHasMoreData: isOldestShortsHasMoreData,
          isTargetMoreDataLoading: isOldestShortsMoreDataLoading,
          onPageIncrement: () => oldestShortsPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnChannel: isOwnChannel,
          extraParams: extraParams,
        );
        break;

      case Shorts.underProgress:
        await _fetchShorts(
          shorts: shorts,
          page: underProgressShortsPage,
          isInitialLoad: isInitialLoad,
          targetInitialLoading: isUnderProgressShortsLoading,
          isTargetHasMoreData: isUnderProgressShortsHasMoreData,
          isTargetMoreDataLoading: isUnderProgressShortsMoreDataLoading,
          targetList: underProgressShortsPosts,
          onPageIncrement: () => underProgressShortsPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnChannel: isOwnChannel,
          extraParams: extraParams,
        );
        break;

    // 👇 default: if not sorting-related (drafts etc.)
      default:
        await _fetchShorts(
          shorts: shorts,
          page: draftShortsPage,
          isInitialLoad: isInitialLoad,
          targetList: draftShortsPosts,
          targetInitialLoading: isDraftShortsLoading,
          isTargetHasMoreData: isDraftShortsHasMoreData,
          isTargetMoreDataLoading: isDraftShortsMoreDataLoading,
          onPageIncrement: () => draftShortsPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnChannel: isOwnChannel,
          extraParams: extraParams,
        );
    }
  }

  Future<void> _fetchShorts({
    required Shorts? shorts,
    required int page,
    required bool isInitialLoad,
    required RxList<VideoFeedItem> targetList,
    required RxBool targetInitialLoading,
    required RxBool isTargetMoreDataLoading,
    required bool isTargetHasMoreData,
    required VoidCallback onPageIncrement,
    required bool refresh,
    required String channelOrUserId,
    required String authorId,
    required bool isOwnChannel,
    Map<String, Object>? extraParams,
  }) async {
    if (isInitialLoad) {
      page = 1;
      isTargetMoreDataLoading.value = false;
      isTargetHasMoreData = true;
    }

    if(!isTargetHasMoreData || isTargetMoreDataLoading.isTrue) return;

    try {
      final params = {
        ApiKeys.limit: limit,
        ApiKeys.page: page,
        ApiKeys.typeFilter: 'short'
      };

      // if(sortBy!=null){
      //   if(sortBy!=SortBy.UnderProgress){
      //     params[ApiKeys.sortBy] = sortBy.queryValue;
      //     params[ApiKeys.status] = VideoStatus.published.queryValue;
      //   }else{
      //     params[ApiKeys.status] = VideoStatus.processing.queryValue;
      //   }
      // }else{
      //   params[ApiKeys.status] = VideoStatus.draft.queryValue;
      // }

      if (shorts == Shorts.latest || shorts == Shorts.popular || shorts == Shorts.oldest) {
        params[ApiKeys.sortBy] = shorts!.queryValue;
        params[ApiKeys.status] = VideoStatus.published.queryValue;
      } else if (shorts == Shorts.underProgress) {
        params[ApiKeys.status] = VideoStatus.processing.queryValue;
      } else {
        params[ApiKeys.status] = VideoStatus.draft.queryValue;
      }

      // Merge any extra params provided by caller (e.g., post_via)
      if (extraParams != null && extraParams.isNotEmpty) {
        params.addAll(extraParams);
      }

      ResponseModel response;
      if(isOwnChannel){
        response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
      }else {
        response = await ChannelRepo().getVisitingChannelVideos(channelOrUserId: channelOrUserId, queryParams: params);
      }

      if (response.isSuccess) {
        shortsResponse = ApiResponse.complete(response);
        final videoResponse = VideoResponse.fromJson(response.response?.data);
        final List<VideoFeedItem> newShorts = videoResponse.data?.videos ?? [];
        // if (newShorts.isNotEmpty) {
          if(page == 1){
            targetList.value = newShorts;
          }else{
            targetList.addAll(newShorts);
          }

          if (newShorts.length < limit) {
            isTargetHasMoreData = false;
          } else {
            onPageIncrement();
          }
        // } else {
        //   isTargetHasMoreData = false;
        // }
      } else {
        shortsResponse = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, stack) {
      log('Stack: $stack');
      shortsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      targetInitialLoading.value = false;
      isTargetMoreDataLoading.value = false;
    }
  }

  RxBool isInitialLoading(Shorts shorts) {
    switch (shorts) {
      case Shorts.latest:
        return isLatestShortsLoading;
      case Shorts.popular:
        return isPopularShortsLoading;
      case Shorts.oldest:
        return isOldestShortsLoading;
      case Shorts.underProgress:
        return isUnderProgressShortsLoading;
      case Shorts.draft:
        return isDraftShortsLoading;
      default:
        return isDraftShortsLoading; // fallback for trending, saved, etc.
    }
  }

  bool isHasMoreData(Shorts shorts) {
    switch (shorts) {
      case Shorts.latest:
        return isLatestShortsHasMoreData;
      case Shorts.popular:
        return isPopularShortsHasMoreData;
      case Shorts.oldest:
        return isOldestShortsHasMoreData;
      case Shorts.underProgress:
        return isUnderProgressShortsHasMoreData;
      case Shorts.draft:
        return isDraftShortsHasMoreData;
      default:
        return false; // for trending, saved, nearby, personalized
    }
  }

  RxBool isMoreDataLoading(Shorts shorts) {
    switch (shorts) {
      case Shorts.latest:
        return isLatestShortsMoreDataLoading;
      case Shorts.popular:
        return isPopularShortsMoreDataLoading;
      case Shorts.oldest:
        return isOldestShortsMoreDataLoading;
      case Shorts.underProgress:
        return isUnderProgressShortsMoreDataLoading;
      case Shorts.draft:
        return isDraftShortsMoreDataLoading;
      default:
        return false.obs; // fallback for others
    }
  }


  /// Utility to get post list by type
  RxList<VideoFeedItem> getListByType({required Shorts shortsType}) {
    switch (shortsType) {
      case Shorts.trending:
        return trendingVideoFeedPosts;
      case Shorts.nearBy:
        return nearByVideoFeedPosts;
      case Shorts.personalized:
        return personalizedVideoFeedPosts;
      case Shorts.saved:
        return savedShorts;
      case Shorts.latest:
        return latestShortsPosts;
      case Shorts.popular:
        return popularShortsPosts;
      case Shorts.oldest:
        return oldestShortsPosts;
      case Shorts.underProgress:
        return underProgressShortsPosts;
      case Shorts.draft:
        return draftShortsPosts;
    }
  }


  /// Delete Post
  Future<void> shortDelete({required Shorts shortsType, required String videoId}) async {
    final list = getListByType(shortsType: shortsType);
    final index = list.indexWhere((v) => v.video?.id == videoId);

    try {
      final response = await ChannelRepo().deleteVideo(videoId: videoId);
      if (response.isSuccess) {
        if (index != -1) list.removeAt(index);
        Navigator.pop(navigator!.context);
        commonSnackBar(message: response.message);
        deleteShortResponse = ApiResponse.complete(response);
      } else {
        deleteShortResponse = ApiResponse.error('error');
      }
    } catch (_) {
      deleteShortResponse = ApiResponse.error('error');
    }
  }

  ///USER BLOCK(PARTIAL AND FULL)...
  Future<void> userBlocked({required Shorts shortsType, required String otherUserId}) async {
    final list = getListByType(shortsType: shortsType);

    try {
      Map<String, dynamic> params = {
        ApiKeys.blockedTo:  otherUserId,
        ApiKeys.type: BlockedType.full.label,
        ApiKeys.duration: 0
      };

      final response = await AuthRepo().blockUser(params: params);

      if (response.isSuccess) {
        blockUserResponse = ApiResponse.complete(response);
        BlockUserResponse blockUser = BlockUserResponse.fromJson(response.response?.data);
        list.removeWhere((v) {
          print('contain userId --> ${v.video?.userId}');
          print('userId --> $otherUserId');
          return v.video?.userId == otherUserId;
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

  /// Save Shorts To LOCAL DB
  Future<bool> saveVideosToLocalDB({required VideoFeedItem videoFeedItem}) async {
    bool isSaved = HiveServices().isVideoSaved(videoFeedItem.videoId??'');
    if(isSaved){
      await HiveServices().deleteVideoById(videoFeedItem.videoId??'');
      // commonSnackBar(message: 'Short removed.');
      return false;
    }else{
      final hiveModel = VideoFeedItemHive.fromJson(videoFeedItem.toJson());
      await HiveServices().saveVideo(hiveModel);
      // commonSnackBar(message: 'Short saved.');
      return true;
    }
  }

  /// Update like count for a specific video across all lists
  void updateVideoLikeCount({required Shorts shortsType, required String videoId, required bool isLiked, required int newLikeCount}) {
    final list = getListByType(shortsType: shortsType);
    _updateVideoInList(list, videoId, isLiked: isLiked, newLikeCount: newLikeCount);
  }

  /// Update comment count for a specific video across all lists
  void updateVideoCommentCount({required Shorts shortsType, required String videoId, required int newCommentCount}) {
    final list = getListByType(shortsType: shortsType);
    _updateVideoInList(list, videoId, newCommentCount: newCommentCount);
  }



  /// Update saved state for a specific video across all lists
  void updateVideoSavedState({required String videoId, required bool isSaved}) {
    _updateVideoInList(trendingVideoFeedPosts, videoId, isSaved: isSaved);
    _updateVideoInList(personalizedVideoFeedPosts, videoId, isSaved: isSaved);
    _updateVideoInList(nearByVideoFeedPosts, videoId, isSaved: isSaved);
    _updateVideoInList(latestShortsPosts, videoId, isSaved: isSaved);
    _updateVideoInList(popularShortsPosts, videoId, isSaved: isSaved);
    _updateVideoInList(oldestShortsPosts, videoId, isSaved: isSaved);
    _updateVideoInList(savedShorts, videoId, isSaved: isSaved);
    _updateVideoInList(allChannelShorts, videoId, isSaved: isSaved);
  }

  /// Helper method to update a video in a specific list
  void _updateVideoInList(
      RxList<VideoFeedItem> list,
      String videoId,
      { bool? isLiked,
        int? newLikeCount,
        int? newCommentCount,
        bool? isSaved
      }) {
    final index = list.indexWhere((video) => video.video?.id == videoId);
    if (index != -1) {
      final video = list[index];
      
      // Update interactions
      if (isLiked != null && video.interactions != null) {
        video.interactions!.isLiked = isLiked;
      }
      
      // Update stats
      if (video.video?.stats != null) {
        if (newLikeCount != null) {
          video.video!.stats!.likes = newLikeCount;
        }
        if (newCommentCount != null) {
          video.video!.stats!.comments = newCommentCount;
        }
      }
      
      // Update saved state
      // if (isSaved != null) {
      //   video.isVideoSavedLocal = isSaved;
      // }
      
      // Trigger UI update by reassigning the list
      list.refresh();
    }
  }

  /// Get All Saved Shorts
  void getAllSavedShorts() {
    savedShorts.clear();
    List<VideoFeedItemHive> savedVideoFeed = HiveServices().getAllSavedVideos();
    // Filter by type (e.g. "shorts", "reel", etc.)
    final filteredList = savedVideoFeed
        .where((e) => e.video?.type == 'short') // <-- replace 'short' with your desired type
        .map((e) => e.toVideoFeedItem())
        .toList();

    savedShorts.addAll(filteredList);
  }

}