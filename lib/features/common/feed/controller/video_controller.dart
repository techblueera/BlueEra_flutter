import 'dart:developer';
import 'dart:io';

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
import 'package:BlueEra/features/common/reel/controller/reel_upload_details_controller.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_success_sheet.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoController extends GetxController{
  Rx<ApiResponse> videoPostsResponse = ApiResponse.initial('Initial').obs;
  ApiResponse videoLikeResponse = ApiResponse.initial('Initial');
  ApiResponse videoUnlikeResponse = ApiResponse.initial('Initial');
  ApiResponse followChannelResponse = ApiResponse.initial('Initial');
  ApiResponse unFollowChannelResponse = ApiResponse.initial('Initial');
  ApiResponse channelVideosResponse = ApiResponse.initial('Initial');
  ApiResponse deleteVideosResponse = ApiResponse.initial('Initial');
  ApiResponse blockUserResponse = ApiResponse.initial('Initial');
  ApiResponse updateVideoThumbnailResponse = ApiResponse.initial('Initial');
  ApiResponse videoViewResponse = ApiResponse.initial('Initial');
  ApiResponse reportVideoPostResponse = ApiResponse.initial('Initial');

  RxList<ShortFeedItem> videoFeedPosts = <ShortFeedItem>[].obs;
  ShortFeedItem? videoFeedItem;
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
  RxList<ShortFeedItem> latestVideosPosts = <ShortFeedItem>[].obs;
  RxList<ShortFeedItem> popularVideosPosts = <ShortFeedItem>[].obs;
  RxList<ShortFeedItem> oldestVideosPosts = <ShortFeedItem>[].obs;
  RxList<ShortFeedItem> underProgressVideosPosts = <ShortFeedItem>[].obs;
  RxList<ShortFeedItem> draftVideosPosts = <ShortFeedItem>[].obs;
  int latestVideosPage = 1, popularVideosPage = 1, oldestVideosPage = 1, underProgressVideosPage = 1, draftVideoPage = 1;
  RxBool isLatestVideosLoading = true.obs, isPopularVideosLoading = true.obs, isOldestVideosLoading = true.obs, isUnderProgressVideosLoading = true.obs, isDraftVideosLoading = true.obs;
  RxBool isLatestVideosMoreDataLoading = false.obs, isPopularVideosMoreDataLoading = false.obs, isOldestVideosMoreDataLoading = false.obs,  isUnderProgressVideosMoreDataLoading = false.obs, isDraftVideosMoreDataLoading = false.obs;
  bool isLatestVideosHasMoreData = true, isPopularVideosHasMoreData = true, isOldestVideosHasMoreData = true, isUnderProgressVideosHasMoreData = true, isDraftVideosHasMoreData = true;

  /// Saved Videos
  RxList<ShortFeedItem> savedVideos = <ShortFeedItem>[].obs;
  RxBool isSavedVideosLoading = true.obs;
  RxBool isVideoSavedInDb = false.obs;


  /// View Video
  Future<void> videoView({required String videoId}) async {
    try {

      final response = await FeedRepo().viewVideo(videoId: videoId);

      if (response.isSuccess) {
        videoViewResponse = ApiResponse.complete(response);
      } else {
        videoViewResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      videoViewResponse =  ApiResponse.error('error');
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
        videoPostsResponse.value =  ApiResponse.complete(response);
        final videoFeedModelResponse = VideoResponse.fromJson(response.response?.data);
          List<ShortFeedItem> videoFeedItem = videoFeedModelResponse.data?.videos??[];
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
        videoPostsResponse.value =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('error--> $s');
      videoPostsResponse.value =  ApiResponse.error('error');
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
        List<ShortFeedItem> videoFeedItem = videoFeedModelResponse.data?.videos ?? [];
        
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
      VideoType videos,
      String channelOrUserId,
      String authorId,
      bool isOwnVideos, {
        bool isInitialLoad = false,
        bool refresh = false,
        PostVia? postVia,
      }) async {
    switch (videos) {
      case VideoType.latest:
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

      case VideoType.popular:
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

      case VideoType.oldest:
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

      case VideoType.underProgress:
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
    required VideoType? videos,
    required int page,
    required bool isInitialLoad,
    required RxList<ShortFeedItem> targetList,
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
      if(postVia == PostVia.channel || postVia == PostVia.profile) {
        if (videos == VideoType.latest || videos == VideoType.popular || videos == VideoType.oldest) {
          params[ApiKeys.sortBy] = videos!.queryValue;
          params[ApiKeys.status] = VideoStatus.published.queryValue;
        } else if (videos == VideoType.underProgress) {
          params[ApiKeys.status] = VideoStatus.processing.queryValue;
        } else {
          params[ApiKeys.status] = VideoStatus.draft.queryValue;
        }

        params[ApiKeys.postVia] = (postVia == PostVia.channel) ? 'channel' : 'user';

        if(isOwnVideos){
          /// for own channel we will fetch videos by user Id
          response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
        }else {
          /// for own channel we will fetch videos by other user channel id
          response = await ChannelRepo().getVisitingChannelVideos(channelOrUserId: channelOrUserId, queryParams: params);
        }
      }else{
        /// for getting  all videos of user we will fetch videos by user Id (will not sent postVia)
        response = await ChannelRepo().getOwnChannelVideos(authorId: authorId, queryParams: params);
      }

      if (response.isSuccess) {
        channelVideosResponse = ApiResponse.complete(response);
        final videoResponse = VideoResponse.fromJson(response.response?.data);
        final List<ShortFeedItem> newVideos = videoResponse.data?.videos ?? [];
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

  RxBool isInitialLoading(VideoType videos) {
    switch (videos) {
      case VideoType.latest:
        return isLatestVideosLoading;
      case VideoType.popular:
        return isPopularVideosLoading;
      case VideoType.oldest:
        return isOldestVideosLoading;
      case VideoType.underProgress:
        return isUnderProgressVideosLoading;
      case VideoType.draft:
        return isDraftVideosLoading;
      default:
        return false.obs; // fallback for videoFeed, saved
    }
  }

  bool isHasMoreData(VideoType videos) {
    switch (videos) {
      case VideoType.latest:
        return isLatestVideosHasMoreData;
      case VideoType.popular:
        return isPopularVideosHasMoreData;
      case VideoType.oldest:
        return isOldestVideosHasMoreData;
      case VideoType.underProgress:
        return isUnderProgressVideosHasMoreData;
      case VideoType.draft:
        return isDraftVideosHasMoreData;
      default:
        return false; // for videoFeed, saved
    }
  }

  RxBool isMoreDataLoading(VideoType videos) {
    switch (videos) {
      case VideoType.latest:
        return isLatestVideosMoreDataLoading;
      case VideoType.popular:
        return isPopularVideosMoreDataLoading;
      case VideoType.oldest:
        return isOldestVideosMoreDataLoading;
      case VideoType.underProgress:
        return isUnderProgressVideosMoreDataLoading;
      case VideoType.draft:
        return isDraftVideosMoreDataLoading;
      default:
        return false.obs; // fallback for videoFeed, saved
    }
  }


  /// Utility to get post list by type
  RxList<ShortFeedItem> getListByType({required VideoType videoType}) {
    switch (videoType) {
      case VideoType.videoFeed:
        return videoFeedPosts;
      case VideoType.saved:
        return savedVideos;
      case VideoType.latest:
        return latestVideosPosts;
      case VideoType.popular:
        return popularVideosPosts;
      case VideoType.oldest:
        return oldestVideosPosts;
      case VideoType.underProgress:
        return underProgressVideosPosts;
      case VideoType.draft:
        return draftVideosPosts;
    }
  }

  /// Delete Video
  Future<void> videoDelete({required VideoType video, required String videoId}) async {
    final list = getListByType(videoType: video);
    final index = list.indexWhere((v) => v.video?.id == videoId);

      try {
        if (video == VideoType.saved) {
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
  Future<void> userBlocked({required VideoType videoType,required String otherUserId}) async {
    final list = getListByType(videoType: videoType);

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

  ///VIDEO POST REPOST...
  Future<void> videoPostReport({
    required VideoType videoType,
    required String videoId,
    required Map<String, dynamic> params
  }) async {
    final list = getListByType(videoType: videoType);
    final index = list.indexWhere((v) => v.video?.id == videoId);

    try {

      final response = await AuthRepo().report(params: params);

      if (response.isSuccess) {
        reportVideoPostResponse = ApiResponse.complete(response);
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
        reportVideoPostResponse =  ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      reportVideoPostResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
    }
  }


  ///UPDATE VIDEO Thumbnail...
  Future<void> updateVideoThumbnail({
    required VideoType videoType,
    required String videoId,
    required String thumbnail,
  }) async {
    final reelUploadDetailsController = Get.put(ReelUploadDetailsController());
    final list = getListByType(videoType: videoType);
    final index = list.indexWhere((v) => v.video?.id == videoId);

    try {
      double progress = 0.0;

      void updateProgress(double value) {
        progress = value.clamp(0.0, 1.0);
        UploadProgressDialog.update(progress); // ✅ use new dialog updater
      }

      // ✅ Show dialog
      UploadProgressDialog.show(initialProgress: progress);

      final coverFile = File(thumbnail);
      final coverInfo = getFileInfo(coverFile);

      // 1. Init upload
      await reelUploadDetailsController.uploadInit(
        queryParams: {
          ApiKeys.fileName: coverInfo['fileName'],
          ApiKeys.fileType: coverInfo['mimeType'],
        },
        isVideoUpload: false,
      );
      updateProgress(0.2);

      // 2. Upload to S3 (20% → 90%)
      await reelUploadDetailsController.uploadFileToS3(
        file: coverFile,
        fileType: coverInfo['mimeType']!,
        preSignedUrl:
        reelUploadDetailsController.uploadInitCoverImageFile?.uploadUrl ?? "",
        onProgress: (total) {
          // total is 0.0 - 1.0
          final combined = 0.2 + total * 0.7;
          updateProgress(combined);
        },
      );

      updateProgress(0.9);

      // 3. Save new thumbnail URL from backend
      final newCoverUrl =
          reelUploadDetailsController.uploadInitCoverImageFile?.publicUrl ?? '';

      ResponseModel? response = await ChannelRepo().updateVideoDetails(
        videoId: videoId,
        params: {ApiKeys.coverUrl: newCoverUrl},
      );

      updateProgress(1.0);
      if (response.isSuccess) {

        final videoItem = list[index];

        list[index] = videoItem.copyWith(
            video: videoItem.video?.copyWith(
            coverUrl: thumbnail,
          ),
        );

        updateVideoThumbnailResponse = ApiResponse.complete(response);
      } else {
        updateVideoThumbnailResponse = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      updateVideoThumbnailResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      // ✅ Always close the dialog (GetX version, no context needed)
      UploadProgressDialog.close();
    }
  }

  /// Save Video To LOCAL DB
  Future<bool> saveVideosToLocalDB({required ShortFeedItem videoFeedItem}) async {
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
        .where((e) => e.video?.type == 'long')
        .map((e) => e.toVideoFeedItem())
        .toList();

    savedVideos.addAll(filteredList);
    // isSavedVideosLoading.value = false;
  }

  /// Get Video By ID for deep link handling
  Future<ShortFeedItem?> getVideoById(String videoId) async {
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
          // We need to extract t he first video from the videos array
          final videosData = responseData['data'];
          if (videosData != null && videosData['videos'] != null && videosData['videos'].isNotEmpty) {
            final videoData = videosData['videos'][0];
            log('DEEPLINK_DEBUG: Extracted video data from nested structure');
            
            final videoFeedItem = ShortFeedItem.fromJson(videoData);
            
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