import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/home_cache_service.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/feed/hive_model/video_hive_model.dart';
import 'package:BlueEra/features/common/feed/models/block_user_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoController extends GetxController{
  ApiResponse videoPostsResponse = ApiResponse.initial('Initial');
  ApiResponse videoLikeResponse = ApiResponse.initial('Initial');
  ApiResponse videoUnlikeResponse = ApiResponse.initial('Initial');
  ApiResponse followChannelResponse = ApiResponse.initial('Initial');
  ApiResponse unFollowChannelResponse = ApiResponse.initial('Initial');
  ApiResponse channelVideosResponse = ApiResponse.initial('Initial');
  ApiResponse deleteVideosResponse = ApiResponse.initial('Initial');
  ApiResponse blockUserResponse = ApiResponse.initial('Initial');

  RxList<VideoFeedItem> videoFeedPosts = <VideoFeedItem>[].obs;
  VideoFeedItem? videoFeedItem;
  RxBool isLoading = true.obs;
  RxBool isLoadingMore = false.obs;
  bool isMoreDataAvailable = false;
  RxBool isLiked = false.obs;
  RxBool isChannelFollow = false.obs;
  RxInt likes = 0.obs;
  RxInt comments = 0.obs;
  int page = 1;
  int limit = 40;

  ///Channel Videos(Trending, Popular, Oldest)
  RxList<VideoFeedItem> latestVideosPosts = <VideoFeedItem>[].obs;
  RxList<VideoFeedItem> popularVideosPosts = <VideoFeedItem>[].obs;
  RxList<VideoFeedItem> oldestVideosPosts = <VideoFeedItem>[].obs;
  RxList<VideoFeedItem> underProgressVideosPosts = <VideoFeedItem>[].obs;
  RxList<VideoFeedItem> draftVideosPosts = <VideoFeedItem>[].obs;
  ApiResponse shortVideoLikeResponse = ApiResponse.initial('Initial');
  int latestVideosPage = 1, popularVideosPage = 1, oldestVideosPage = 1, underProgressVideosPage = 1, draftVideoPage = 1;
  RxBool isLatestVideosLoading = true.obs, isPopularVideosLoading = true.obs, isOldestVideosLoading = true.obs, isUnderProgressVideosLoading = true.obs, isDraftVideosLoading = true.obs;
  RxBool isLatestVideosMoreDataLoading = false.obs, isPopularVideosMoreDataLoading = false.obs, isOldestVideosMoreDataLoading = false.obs,  isUnderProgressVideosMoreDataLoading = false.obs, isDraftVideosMoreDataLoading = false.obs;
  bool isLatestVideosHasMoreData = true, isPopularVideosHasMoreData = true, isOldestVideosHasMoreData = true, isUnderProgressVideosHasMoreData = true, isDraftVideosHasMoreData = true;

  /// Saved Videos
  RxList<VideoFeedItem> savedVideos = <VideoFeedItem>[].obs;
  RxBool isSavedVideosLoading = true.obs;
  RxBool isVideoSavedInDb = false.obs;


  /// View Video
  Future<void> videoView({required String videoId}) async {
    try {

      final response = await FeedRepo().viewVideo(videoId: videoId);

      if (response.isSuccess) {
        shortVideoLikeResponse = ApiResponse.complete(response);
      } else {
        shortVideoLikeResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      shortVideoLikeResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
    }
  }

  ///GET ALL Feed Videos...
  Future<void> getAllFeedVideos({
    bool isInitialLoad = false,
    bool refresh = false,
    String query = ''
  }) async {
    try {
      if (isInitialLoad) {
        page = 1;
        isLoadingMore.value = false;
        isMoreDataAvailable = true;
        
        // Try to get cached videos first
        if (page == 1) {
          final cachedVideos = await HomeCacheService().getCachedVideos();
          if (cachedVideos != null && cachedVideos.isNotEmpty) {
            print('📱 Showing cached videos: ${cachedVideos.length} items');
            videoFeedPosts.value = cachedVideos;
            isLoading.value = false;
            
            // Fetch fresh data in background
            _fetchVideosInBackground(queryParams: {
              ApiKeys.page: page,
              ApiKeys.limit: limit,
              ApiKeys.userId: userId,
              ApiKeys.type: 'long',
              ApiKeys.refresh: refresh,
            });
            return;
          } else {
            print('📱 No cached videos found, fetching from API...');
          }
        }
      }

      if(!isMoreDataAvailable || isLoadingMore.isTrue) return;

      isLoadingMore.value = true;

      final queryParams = {
        ApiKeys.page: page,
        ApiKeys.limit: limit,
        ApiKeys.userId: userId,
        ApiKeys.type: 'long'
      };

      ResponseModel response;
      if(query.isEmpty){
        queryParams[ApiKeys.refresh] = refresh;
        response = await FeedRepo().getAllFeedVideos(queryParams: queryParams);
      }else{
        queryParams[ApiKeys.query] = query;
        response = await FeedRepo().videosFeedSearch(queryParams: queryParams);
      }

      if (response.isSuccess) {
        videoPostsResponse =  ApiResponse.complete(response);
        final videoFeedModelResponse = VideoResponse.fromJson(response.response?.data);
          List<VideoFeedItem> videoFeedItem = videoFeedModelResponse.data?.videos??[];
          if(page==1){
            videoFeedPosts.value = videoFeedItem;
            
            // Cache videos
            if (videoFeedItem.isNotEmpty) {
              await HomeCacheService().cacheVideos(videoFeedItem);
              print('💾 Cached ${videoFeedItem.length} videos');
            }
          }else{
            videoFeedPosts.addAll(videoFeedItem);
          }

          if (videoFeedModelResponse.pagination?.hasMore??false) {
            page++;
          } else {
            isMoreDataAvailable = false;
          }
      } else {
        videoPostsResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('error--> $e');
      log('error--> $s');
      videoPostsResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Fetch videos in background for cache updates
  Future<void> _fetchVideosInBackground({required Map<String, dynamic> queryParams}) async {
    try {
      ResponseModel response = await FeedRepo().getAllFeedVideos(queryParams: queryParams);
      
      if (response.isSuccess) {
        final videoFeedModelResponse = VideoResponse.fromJson(response.response?.data);
        List<VideoFeedItem> videoFeedItem = videoFeedModelResponse.data?.videos ?? [];
        
        if (videoFeedItem.isNotEmpty) {
          // Cache videos
          await HomeCacheService().cacheVideos(videoFeedItem);
          
          // Update the UI with fresh data
          videoFeedPosts.value = videoFeedItem;
        }
      }
    } catch (e) {
      // Silently fail for background fetch
      print('Background video fetch failed: $e');
    }
  }

  /// Preload videos for better performance
  // Future<void> _preloadNewVideos(List<VideoFeedItem> videos) async {
  //   if (!isCacheEnabled.value) return;
  //
  //   try {
  //     // Check network conditions before preloading
  //     final shouldCache = await NetworkUtils.shouldCacheBasedOnNetwork();
  //     if (!shouldCache) return;
  //
  //     // Preload first few videos from the new batch
  //     for (int i = 0; i < videos.length && i < 3; i++) {
  //       final videoUrl = videos[i].video?.videoUrl;
  //       if (videoUrl != null &&
  //           videoUrl.isNotEmpty &&
  //           !_cachedVideoUrls.contains(videoUrl)) {
  //
  //         _cachedVideoUrls.add(videoUrl);
  //         await EnhancedVideoCacheManager.preloadVideo(videoUrl);
  //       }
  //     }
  //   } catch (e) {
  //     log('Preload videos error: $e');
  //   }
  // }

  ///VIDEO LIKE...
  Future<void> videoLike({required String videoId}) async {
    try {

      final response = await FeedRepo().likeVideo(videoId: videoId);

      if (response.isSuccess) {
        videoLikeResponse = ApiResponse.complete(response);

        isLiked.value = !(isLiked.value);
        likes.value = likes.value + 1;

        // final currentVideo = videoItem.value;
        // final currentStats = currentVideo.videoData?.videoData?.stats;
        //
        // videoItem.value = currentVideo.copyWith(
        //   videoData: currentVideo.videoData?.copyWith(
        //     videoData: currentVideo.videoData?.videoData?.copyWith(
        //       stats: currentStats?.copyWith(
        //         isLiked: !(currentStats.isLiked??false),
        //         likes: currentStats.likes??0 + 1,
        //       ),
        //     ),
        //   ),
        // );

      } else {
        videoLikeResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      videoLikeResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
    }
  }

  ///VIDEO UnLIKE...
  Future<void> videoUnLike({required String videoId}) async {
    try {

      final response = await FeedRepo().unlikeVideo(videoId: videoId);

      if (response.isSuccess) {
        videoUnlikeResponse = ApiResponse.complete(response);
        isLiked.value = !(isLiked.value);
        likes.value =  likes.value - 1;
      } else {
        videoUnlikeResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      videoUnlikeResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
    }
  }

  ///FOLLOW CHANNEL...
  Future<void> followChannel({required String channelId}) async {
    try {

      final response = await ChannelRepo().followChannel(channelId: channelId);

      if (response.isSuccess) {
        followChannelResponse = ApiResponse.complete(response);
        isChannelFollow.value = !(isChannelFollow.value);
        // Update the _videoItem with updated channel
        videoFeedItem = videoFeedItem?.copyWith(
          channel: videoFeedItem?.channel?.copyWith(
            isFollowing: !isChannelFollow.value,
          ),
        );
      } else {
        followChannelResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      followChannelResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
    }
  }

  ///UNFOLLOW CHANNEL...
  Future<void> unFollowChannel({required String channelId}) async {
    try {

      final response = await ChannelRepo().unFollowChannel(channelId: channelId);

      if (response.isSuccess) {
        unFollowChannelResponse = ApiResponse.complete(response);
        isChannelFollow.value = !(isChannelFollow.value);

        // Update the _videoItem with updated channel
        videoFeedItem = videoFeedItem?.copyWith(
          channel: videoFeedItem?.channel?.copyWith(
            isFollowing: !isChannelFollow.value,
          ),
        );
      } else {
        unFollowChannelResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      unFollowChannelResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
    }
  }

  /// GET CHANNEL VIDEOS (LATEST, POPULAR, OLDEST, etc.)
  Future<void> getVideosByType(
      Videos videos,
      String channelOrUserId,
      String authorId,
      bool isOwnVideos, {
        bool isInitialLoad = false,
        bool refresh = false,
        PostVia? postVia,
      }) async {
    switch (videos) {
      case Videos.latest:
        await _fetchVideos(
          videos: videos,
          page: latestVideosPage,
          isInitialLoad: isInitialLoad,
          targetInitialLoading: isLatestVideosLoading,
          isTargetHasMoreData: isLatestVideosHasMoreData,
          isTargetMoreDataLoading: isLatestVideosMoreDataLoading,
          targetList: latestVideosPosts,
          onPageIncrement: () => latestVideosPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnVideos: isOwnVideos,
          postVia: postVia,
        );
        break;

      case Videos.popular:
        await _fetchVideos(
          videos: videos,
          page: popularVideosPage,
          isInitialLoad: isInitialLoad,
          targetInitialLoading: isPopularVideosLoading,
          isTargetHasMoreData: isPopularVideosHasMoreData,
          isTargetMoreDataLoading: isPopularVideosMoreDataLoading,
          targetList: popularVideosPosts,
          onPageIncrement: () => popularVideosPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnVideos: isOwnVideos,
          postVia: postVia,
        );
        break;

      case Videos.oldest:
        await _fetchVideos(
          videos: videos,
          page: oldestVideosPage,
          isInitialLoad: isInitialLoad,
          targetInitialLoading: isOldestVideosLoading,
          isTargetHasMoreData: isOldestVideosHasMoreData,
          isTargetMoreDataLoading: isOldestVideosMoreDataLoading,
          targetList: oldestVideosPosts,
          onPageIncrement: () => oldestVideosPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnVideos: isOwnVideos,
          postVia: postVia,
        );
        break;

      case Videos.underProgress:
        await _fetchVideos(
          videos: videos,
          page: underProgressVideosPage,
          isInitialLoad: isInitialLoad,
          targetInitialLoading: isUnderProgressVideosLoading,
          isTargetHasMoreData: isUnderProgressVideosHasMoreData,
          isTargetMoreDataLoading: isUnderProgressVideosMoreDataLoading,
          targetList: underProgressVideosPosts,
          onPageIncrement: () => underProgressVideosPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnVideos: isOwnVideos,
          postVia: postVia,
        );
        break;

      default:
      // Draft or any other fallback
        await _fetchVideos(
          videos: videos,
          page: draftVideoPage,
          isInitialLoad: isInitialLoad,
          targetInitialLoading: isDraftVideosLoading,
          isTargetHasMoreData: isDraftVideosHasMoreData,
          isTargetMoreDataLoading: isDraftVideosMoreDataLoading,
          targetList: draftVideosPosts,
          onPageIncrement: () => draftVideoPage++,
          refresh: refresh,
          channelOrUserId: channelOrUserId,
          authorId: authorId,
          isOwnVideos: isOwnVideos,
          postVia: postVia,
        );
    }
  }


  /// Utility to get post list by type
  Future<void> _fetchVideos({
    required Videos? videos,
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
    required bool isOwnVideos,
    required PostVia? postVia,
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
        ApiKeys.typeFilter: 'long'
      };

      ResponseModel response;
      if(postVia == PostVia.channel) {
        if (videos == Videos.latest || videos == Videos.popular || videos == Videos.oldest) {
          params[ApiKeys.sortBy] = videos!.queryValue;
          params[ApiKeys.status] = VideoStatus.published.queryValue;
        } else if (videos == Shorts.underProgress) {
          params[ApiKeys.status] = VideoStatus.processing.queryValue;
        } else {
          params[ApiKeys.status] = VideoStatus.draft.queryValue;
        }
        params[ApiKeys.postVia] = 'channel';

        if(isOwnVideos){
          /// for own channel we will fetch videos by user Id
          response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
        }else {
          /// for own channel we will fetch videos by other user channel id
          response = await ChannelRepo().getVisitingChannelVideos(channelOrUserId: channelOrUserId, queryParams: params);
        }
      }else if(postVia == PostVia.profile){
        if (videos == Videos.latest) {
          params[ApiKeys.status] = VideoStatus.published.queryValue;
        } else if (videos == Videos.underProgress) {
          params[ApiKeys.status] = VideoStatus.processing.queryValue;
        }
        params[ApiKeys.postVia] = 'user';

        /// for own profile videos we will fetch videos by user Id
        response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
      }else{
        /// for getting  all videos of user we will fetch videos by user Id (will not sent postVia)
        response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
      }

      // if (videos == Videos.latest || videos == Videos.popular || videos == Videos.oldest) {
      //   params[ApiKeys.sortBy] = videos!.queryValue;
      //   params[ApiKeys.status] = VideoStatus.published.queryValue;
      // } else if (videos == Shorts.underProgress) {
      //   params[ApiKeys.status] = VideoStatus.processing.queryValue;
      // } else {
      //   params[ApiKeys.status] = VideoStatus.draft.queryValue;
      // }
      //
      // ResponseModel response;
      // if(isOwnVideos){
      //   response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
      // }else {
      //   response = await ChannelRepo().getVisitingChannelVideos(channelOrUserId: channelOrUserId, queryParams: params);
      // }

      if (response.isSuccess) {
        channelVideosResponse = ApiResponse.complete(response);
        final videoResponse = VideoResponse.fromJson(response.response?.data);
        final List<VideoFeedItem> newVideos = videoResponse.data?.videos ?? [];
        // if (newVideos.isNotEmpty) {
          if(page == 1){
            targetList.value = newVideos;
          }else{
            targetList.addAll(newVideos);
          }

          if (newVideos.length < limit) {
            isTargetHasMoreData = false;
          } else {
            onPageIncrement();
          }
        // } else {
        //   isTargetHasMoreData = false;
        // }
      } else {
        channelVideosResponse = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      channelVideosResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      targetInitialLoading.value = false;
      isTargetMoreDataLoading.value = false;
    }
  }

  RxBool isInitialLoading(Videos videos) {
    switch (videos) {
      case Videos.latest:
        return isLatestVideosLoading;
      case Videos.popular:
        return isPopularVideosLoading;
      case Videos.oldest:
        return isOldestVideosLoading;
      case Videos.underProgress:
        return isUnderProgressVideosLoading;
      case Videos.draft:
        return isDraftVideosLoading;
      default:
        return false.obs; // fallback for videoFeed, saved
    }
  }

  bool isHasMoreData(Videos videos) {
    switch (videos) {
      case Videos.latest:
        return isLatestVideosHasMoreData;
      case Videos.popular:
        return isPopularVideosHasMoreData;
      case Videos.oldest:
        return isOldestVideosHasMoreData;
      case Videos.underProgress:
        return isUnderProgressVideosHasMoreData;
      case Videos.draft:
        return isDraftVideosHasMoreData;
      default:
        return false; // for videoFeed, saved
    }
  }

  RxBool isMoreDataLoading(Videos videos) {
    switch (videos) {
      case Videos.latest:
        return isLatestVideosMoreDataLoading;
      case Videos.popular:
        return isPopularVideosMoreDataLoading;
      case Videos.oldest:
        return isOldestVideosMoreDataLoading;
      case Videos.underProgress:
        return isUnderProgressVideosMoreDataLoading;
      case Videos.draft:
        return isDraftVideosMoreDataLoading;
      default:
        return false.obs; // fallback for videoFeed, saved
    }
  }


  /// Utility to get post list by type
  RxList<VideoFeedItem> getListByType({required Videos videoType}) {
    switch (videoType) {
      case Videos.videoFeed:
        return videoFeedPosts;
      case Videos.saved:
        return savedVideos;
      case Videos.latest:
        return latestVideosPosts;
      case Videos.popular:
        return popularVideosPosts;
      case Videos.oldest:
        return oldestVideosPosts;
      case Videos.underProgress:
        return underProgressVideosPosts;
      case Videos.draft:
        return draftVideosPosts;
    }
  }

  /// Delete Post
  Future<void> videoDelete({required Videos videoType, required String videoId}) async {
    final list = getListByType(videoType: videoType);
    final index = list.indexWhere((v) => v.video?.id == videoId);

      try {
        if (videoType == Videos.videoFeed) {
          await HiveServices().deleteVideoById(videoId);
        } else {
          final response = await ChannelRepo().deleteVideo(videoId: videoId);
          if (response.isSuccess) {
            if (index != -1) list.removeAt(index);
            Navigator.pop(navigator!.context);
            commonSnackBar(message: response.message);
            deleteVideosResponse = ApiResponse.complete(response);
          }else {
            deleteVideosResponse = ApiResponse.error('error');
          }
        }
      } catch (_) {
        deleteVideosResponse = ApiResponse.error('error');
      }
    }

  ///USER BLOCK...
  Future<void> userBlocked({required Videos videoType,required String otherUserId}) async {
    final list = getListByType(videoType: videoType);
    // final index = list.indexWhere((v) => v.video?.id == videoId);

    try {
      Map<String, dynamic> params = {
        ApiKeys.blockedTo:  otherUserId,
        ApiKeys.type: BlockedType.full.label,
        ApiKeys.duration:  0
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

  ///POST BLOCK...
  Future<void> postBlocked({required Videos videoType,required String otherUserId}) async {
    final list = getListByType(videoType: videoType);
    // final index = list.indexWhere((v) => v.video?.id == videoId);

    try {
      Map<String, dynamic> params = {
        ApiKeys.blockedTo:  otherUserId,
        ApiKeys.type: BlockedType.full.label,
        ApiKeys.duration:  0
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

  /// Save Video To LOCAL DB
  Future<bool> saveVideosToLocalDB({required VideoFeedItem videoFeedItem}) async {
    bool isSaved = HiveServices().isVideoSaved(videoFeedItem.videoId??'');
    if(isSaved){
      await HiveServices().deleteVideoById(videoFeedItem.videoId??'');
      // commonSnackBar(message: 'Video removed.');
      return false;
    }else{
      final hiveModel = VideoFeedItemHive.fromJson(videoFeedItem.toJson());
      await HiveServices().saveVideo(hiveModel);
      // commonSnackBar(message: 'Video saved.');
      return true;
    }
  }

  /// Get All Saved Videos
  void getAllSavedVideos() {
    // isSavedVideosLoading.value = true;
    savedVideos.clear();
    List<VideoFeedItemHive> savedVideoFeed = HiveServices().getAllSavedVideos();
    final filteredList = savedVideoFeed
        .where((e) => e.video?.type == 'long') // <-- replace 'short' with your desired type
        .map((e) => e.toVideoFeedItem())
        .toList();

    savedVideos.addAll(filteredList);
    // isSavedVideosLoading.value = false;
  }

  /// Get Video By ID for deep link handling
  Future<VideoFeedItem?> getVideoById(String videoId) async {
    try {
      log('DEEPLINK_DEBUG: Fetching video with ID: $videoId');
      final response = await FeedRepo().getVideoById(videoId: videoId);
      
      log('DEEPLINK_DEBUG: API Response - Success: ${response.isSuccess}');
      log('DEEPLINK_DEBUG: API Response - Message: ${response.message}');
      log('DEEPLINK_DEBUG: API Response - Data: ${response.response?.data}');
      
      if (response.isSuccess) {
        final responseData = response.response?.data;
        if (responseData != null) {
          log('DEEPLINK_DEBUG: Response data found, extracting video from nested structure');
          
          // The API returns: { data: { videos: [VideoFeedItem] } }
          // We need to extract the first video from the videos array
          final videosData = responseData['data'];
          if (videosData != null && videosData['videos'] != null && videosData['videos'].isNotEmpty) {
            final videoData = videosData['videos'][0];
            log('DEEPLINK_DEBUG: Extracted video data from nested structure');
            
            final videoFeedItem = VideoFeedItem.fromJson(videoData);
            
            // Log the parsed video details
            log('DEEPLINK_DEBUG: Parsed VideoFeedItem - Video URL: ${videoFeedItem.video?.videoUrl}');
            log('DEEPLINK_DEBUG: Parsed VideoFeedItem - Video ID: ${videoFeedItem.video?.id}');
            log('DEEPLINK_DEBUG: Parsed VideoFeedItem - Video Title: ${videoFeedItem.video?.title}');
            
            return videoFeedItem;
          } else {
            log('DEEPLINK_DEBUG: No videos found in nested data structure');
          }
        } else {
          log('DEEPLINK_DEBUG: Video data is null in successful response');
        }
      } else {
        log('DEEPLINK_DEBUG: API call failed with message: ${response.message}');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      log('DEEPLINK_DEBUG: Error fetching video by ID: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    
    return null;
  }



}