import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/repo/feed_repo.dart';
import 'package:get/state_manager.dart';
class FullScreenShortController extends GetxController{
  ApiResponse shortVideoLikeResponse = ApiResponse.initial('Initial');
  ApiResponse shortVideoUnlikeResponse = ApiResponse.initial('Initial');
  ApiResponse shortVideoViewResponse = ApiResponse.initial('Initial');
  ShortFeedItem? videoItem;
  RxBool isLiked = false.obs;
  RxInt likes = 0.obs;
  RxInt comments = 0.obs;

  final Map<String, Timer> _shortLikeApiTimers = {};

  ///SHORT VIDEO View...
  /// Fire-and-forget background view ping (hits `GET videos/metadata/:id`,
  /// which increments the view count server-side). Intentionally SILENT: it
  /// runs with `showProgress: false` and swallows every failure without a
  /// snackbar — a missed view is non-critical and must never disrupt playback.
  Future<void> shortVideoView({required String videoId}) async {
    if (videoId.isEmpty || videoId == '0') return;
    try {
      final response = await FeedRepo().viewVideo(videoId: videoId);
      shortVideoViewResponse = response.isSuccess
          ? ApiResponse.complete(response)
          : ApiResponse.error('error');
    } catch (_) {
      shortVideoViewResponse = ApiResponse.error('error');
    }
  }

  // ///SHORT VIDEO LIKE...
  // Future<void> shortVideoLike({required String videoId}) async {
  //   try {
  //
  //     final response = await FeedRepo().likeVideo(videoId: videoId);
  //
  //     if (response.isSuccess) {
  //       shortVideoLikeResponse = ApiResponse.complete(response);
  //
  //       // isLiked.value = !(isLiked.value);
  //       // likes.value =  likes.value + 1;
  //
  //       // final currentVideo = videoItem.value;
  //       // final currentStats = currentVideo.videoData?.videoData?.stats;
  //       //
  //       // videoItem.value = currentVideo.copyWith(
  //       //   videoData: currentVideo.videoData?.copyWith(
  //       //     videoData: currentVideo.videoData?.videoData?.copyWith(
  //       //       stats: currentStats?.copyWith(
  //       //         isLiked: !(currentStats.isLiked??false),
  //       //         likes: currentStats.likes??0 + 1,
  //       //       ),
  //       //     ),
  //       //   ),
  //       // );
  //
  //     } else {
  //       shortVideoLikeResponse =  ApiResponse.error('error');
  //       commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     shortVideoLikeResponse =  ApiResponse.error('error');
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   } finally {
  //   }
  // }
  //
  // ///SHORT VIDEO UnLIKE...
  // Future<void> shortVideoUnLike({required String videoId}) async {
  //   try {
  //
  //     final response = await FeedRepo().unlikeVideo(videoId: videoId);
  //
  //     if (response.isSuccess) {
  //       shortVideoUnlikeResponse = ApiResponse.complete(response);
  //       // isLiked.value = !(isLiked.value);
  //       // likes.value =  likes.value - 1;
  //     } else {
  //       shortVideoUnlikeResponse =  ApiResponse.error('error');
  //       commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     shortVideoUnlikeResponse =  ApiResponse.error('error');
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   } finally {
  //   }
  // }


  ///SHORT VIDEO LIKE...
  Future<void> shortVideoLike({required String videoId}) async {
    // Cancel existing timer for this specific video
    _shortLikeApiTimers[videoId]?.cancel();

    // Start new debounced timer for this video
    _shortLikeApiTimers[videoId] = Timer(const Duration(milliseconds: 400), () async {
      try {
        final response = await FeedRepo().likeVideo(videoId: videoId);

        if (response.isSuccess) {
          shortVideoLikeResponse = ApiResponse.complete(response);
        } else {
          shortVideoLikeResponse = ApiResponse.error('error');
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        shortVideoLikeResponse = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        // Clean up timer after API call completes
        _shortLikeApiTimers.remove(videoId);
      }
    });
  }

  ///SHORT VIDEO UnLIKE...
  Future<void> shortVideoUnLike({required String videoId}) async {
    // Cancel existing timer for this specific video
    _shortLikeApiTimers[videoId]?.cancel();

    // Start new debounced timer for this video
    _shortLikeApiTimers[videoId] = Timer(const Duration(milliseconds: 400), () async {
      try {
        final response = await FeedRepo().unlikeVideo(videoId: videoId);

        if (response.isSuccess) {
          shortVideoUnlikeResponse = ApiResponse.complete(response);
        } else {
          shortVideoUnlikeResponse = ApiResponse.error('error');
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        shortVideoUnlikeResponse = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      } finally {
        // Clean up timer after API call completes
        _shortLikeApiTimers.remove(videoId);
      }
    });
  }

}
