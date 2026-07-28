import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/navigation_helper_controller.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/features/common/reel/models/upload_init_response.dart';
import 'package:BlueEra/features/common/reel/models/video_category_response.dart';
import 'package:BlueEra/features/common/reel/models/video_meta_data_response.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/common/reel/view/channel/reel_upload_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/personal_profile_setup_new_screen.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';

class ReelUploadDetailsController extends GetxController {
  ApiResponse uploadInitResponse = ApiResponse.initial('Initial');
  ApiResponse uploadFileToS3Response = ApiResponse.initial('Initial');
  ApiResponse videoUploadResponse = ApiResponse.initial('Initial');
  ApiResponse videoCategoriesResponse = ApiResponse.initial('Initial');
  ApiResponse videoDetailsResponse = ApiResponse.initial('Initial');
  Rx<VideoMetaDataResponse> videoMetaData = VideoMetaDataResponse().obs;
  RxList<VideoCategoryData> videoCategory = <VideoCategoryData>[].obs;
  UploadInitResponse? uploadInitVideoFile;
  UploadInitResponse? uploadInitCoverImageFile;

  RxBool isVideoDetailsLoading = false.obs;
  Rx<ShortFeedItem> videoData = ShortFeedItem().obs;

  RxString VideoUploadProgress = ''.obs;

  Video video = Video.video;

  void navigateAfterUploadVideo() {
    // Navigate to Channel Screen, clear stack so back goes to bottom nav
    Get.until(
      (route) =>
          route.settings.name ==
          RouteHelper.getBottomNavigationBarScreenRoute(),
    );
    if (channelId.isNotEmpty) {
      // Then open channel screen on top of bottom nav
      Get.toNamed(
        RouteHelper.getChannelScreenRoute(),
        arguments: {
          ApiKeys.argAccountType: accountTypeGlobal,
          ApiKeys.channelId: channelId,
          ApiKeys.authorId: (accountTypeGlobal == AppConstants.individual)
              ? userId
              : userId
        },
      );
    } else {
      // No channel → go to profile
      if (accountTypeGlobal == AppConstants.individual) {
        openMeOverview();

        // Get.to(() => PersonalProfileSetupNewScreen());
      } else {
        Get.to(() => BusinessOwnProfileScreen());
      }
    }
  }

  // void showProgressVideoUploading(bool isShowDialog) {
  //   logs("isShowDialog====${isShowDialog}");
  //
  //   if (isShowDialog) {
  //     if (Get.isDialogOpen != true) {
  //       if (kDebugMode) {
  //         print('|--------------->🕙️ Loader start 🕑️<---------------|');
  //       }
  //       Get.dialog(
  //         PopScope(
  //           canPop: false, // Disable back press
  //           onPopInvokedWithResult: (didPop, result) {
  //             // Optional: do something when back is attempted
  //           },
  //           child: const CircularIndicator(), // Your loading widget
  //         ),
  //         barrierDismissible: false,
  //       );
  //     }
  //     else{
  //       logs("STEP 2 ELSE");
  //       Get.back();
  //     }
  //   } else {
  //     logs("Get.isDialogOpen====${Get.isDialogOpen}");
  //     if (Get.isDialogOpen == true) {
  //       // if (kDebugMode) {
  //         print('|--------------->🕙️ Loader end 🕑️<---------------|');
  //       // }
  //       Get.back();
  //     }
  //
  //   }
  // }

  /// Returns true only when the presigned URL was obtained. On failure it
  /// clears the corresponding init file (so a stale URL from a prior attempt
  /// can't leak through) and returns false — the caller decides whether to
  /// proceed, instead of this step silently swallowing the error.
  Future<bool> uploadInit(
      {required Map<String, dynamic> queryParams,
      required bool isVideoUpload}) async {
    try {
      ResponseModel? response = await ChannelRepo()
          .uploadInit(queryParams: queryParams, url: initUpload);

      if (response?.isSuccess ?? false) {
        uploadInitResponse = ApiResponse.complete(response);
        final uploadInit =
            UploadInitResponse.fromJson(response?.response?.data);
        if (isVideoUpload) {
          uploadInitVideoFile = uploadInit;
        } else {
          uploadInitCoverImageFile = uploadInit;
        }
        return true;
      } else {
        uploadInitResponse = ApiResponse.error('error');
        if (isVideoUpload) {
          uploadInitVideoFile = null;
        } else {
          uploadInitCoverImageFile = null;
        }
        return false;
      }
    } catch (e, s) {
      log('uploadInit error: $e', stackTrace: s, name: 'ReelUpload');
      uploadInitResponse = ApiResponse.error('error');
      if (isVideoUpload) {
        uploadInitVideoFile = null;
      } else {
        uploadInitCoverImageFile = null;
      }
      return false;
    }
  }

  /// Returns true when the file lands in S3. On failure returns false so the
  /// caller can abort before registering a video with a missing asset.
  Future<bool> uploadFileToS3({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async {
    // No presigned URL → the init step failed; don't even attempt the PUT
    // (this is what threw "No host specified in URI").
    if (preSignedUrl.isEmpty) return false;
    try {
      ResponseModel? response = await ChannelRepo().uploadVideoToS3(
          onProgress: onProgress,
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl);

      if (response?.isSuccess ?? false) {
        uploadFileToS3Response = ApiResponse.complete(response);
        return true;
      } else {
        uploadFileToS3Response = ApiResponse.error('error');
        return false;
      }
    } catch (e, s) {
      log('uploadFileToS3 error: $e', stackTrace: s, name: 'ReelUpload');
      uploadFileToS3Response = ApiResponse.error('error');
      return false;
    }
  }

  ///UPLOAD VIDEO...
  Future<void> uploadVideo({
    PostVia? postVia,
    required Map<String, dynamic> reqData,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Step: Starting final step → 90%
      onProgress?.call(0.9);

      ResponseModel? response =
      await ChannelRepo().uploadVideo(bodyRequest: reqData);

      if (response?.isSuccess ?? false) {
        onProgress?.call(1.0); // Finish at 100%
        UploadProgressDialog.close();

        commonSnackBar(
          message:
          "Video uploaded successfully. It may take about 5 to 30 minutes to appear on your profile.",
        );

        // Refresh the home feed like message / poll / photo uploads do, so the
        // latest posts load once we land back on the bottom nav.
        Get.find<NavigationHelperController>().shouldRefreshBottomBar.value =
            true;

        // Clear stack and go to bottom nav
        Get.until(
              (route) =>
          Get.currentRoute == RouteHelper.getBottomNavigationBarScreenRoute(),
        );

        await Future.delayed(const Duration(milliseconds: 200));

/*        if (postVia == PostVia.channel) {
          Get.toNamed(
            RouteHelper.getChannelScreenRoute(),
            arguments: {
              ApiKeys.argAccountType: accountTypeGlobal.toUpperCase(),
              ApiKeys.channelId: channelId,
              ApiKeys.authorId: isIndividualUser() ? userId : userId,
            },
          );
        }
        else {
          if (isIndividualUser()) {
            Get.to(() => PersonalProfileSetupNewScreen(
                selectedIndex: (video == Video.short) ? 3 : 4,
                sortBy: SortBy.UnderProgress,
            ));
          }
          if (isBusinessUser()) {
            print('business userr herere..');
            Get.to(() => BusinessOwnProfileScreen(
              selectedIndex: (video == Video.short) ? 4 : 5,
              sortBy: SortBy.UnderProgress,
            ));
          }
        }*/

        videoUploadResponse = ApiResponse.complete(response);
      } else {
        UploadProgressDialog.close();
        videoUploadResponse = ApiResponse.error('error');

        commonSnackBar(
          message: response?.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      UploadProgressDialog.close();
      videoUploadResponse = ApiResponse.error('error');

      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }



  ///UPDATE VIDEO DETAILS...
  Future<void> updateVideoDetails(
      {required String videoId, required Map<String, dynamic> reqData}) async {
    try {
      ResponseModel? response = await ChannelRepo()
          .updateVideoDetails(videoId: videoId, params: reqData);

      if (response.isSuccess) {
        videoUploadResponse = ApiResponse.complete(response);
        commonSnackBar(message: response.message ?? AppStrings.success);
        Get.back();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      videoUploadResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///VIDEO CATEGORIES...
  Future<void> getVideoCategories() async {
    try {
      ResponseModel response = await ChannelRepo().getVideoCategories();

      if (response.isSuccess) {
        videoCategoriesResponse = ApiResponse.complete(response);
        final videoCategoryResponse =
            VideoCategoryResponse.fromJson(response.response?.data);
        videoCategory.value = videoCategoryResponse.data ?? [];
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      videoCategoriesResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///GET VIDEOS DETAILS...
  Future<ShortFeedItem?> getVideosDetails({required String videoId}) async {
    try {
      isVideoDetailsLoading.value = true;
      ResponseModel response =
          await ChannelRepo().getVideoDetails(videoId: videoId);

      if (response.isSuccess) {
        videoDetailsResponse = ApiResponse.complete(response);
        log('response--> ${response.response?.data}');
        final VideoFeedItemDataResponse =
            ShortFeedItem.fromJson(response.response?.data['data']['videos']);
        videoData.value = VideoFeedItemDataResponse;
        return videoData.value;
      } else {
        videoDetailsResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return null;
      }
    } catch (e) {
      log('errrrrr ---> $e');
      videoDetailsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      isVideoDetailsLoading.value = false;
    }
  }
}
