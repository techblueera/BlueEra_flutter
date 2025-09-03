import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/upload_init_response.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/personal/auth/repo/personal_profile_repo.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class IntroductionVideoController extends GetxController {
  final Rx<File?> selectedVideo = Rx<File?>(null);
  final RxBool isUploading = false.obs;
  final RxBool hasUploadedVideo = false.obs;
  final RxString videoUrl = ''.obs;
  final RxBool isPlaying = false.obs;
  final Rx<VideoPlayerController?> videoPlayerController =
      Rx<VideoPlayerController?>(null);
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;

  @override
  void onInit() {
    super.onInit();
    // Check if there's already an uploaded video
    checkExistingVideo();
  }

  @override
  void onClose() {
    disposeVideoController();
    super.onClose();
  }

  void disposeVideoController() {
    if (videoPlayerController.value != null) {
      videoPlayerController.value!.dispose();
      videoPlayerController.value = null;
    }
  }

  void resetVideo() {
    selectedVideo.value = null;
    disposeVideoController();
  }

  void setSelectedVideo(File file) {
    selectedVideo.value = file;
    // initializeVideoPlayer(file.path);
  }

  Future<void> initializeVideoPlayer(String videoPath) async {
    disposeVideoController();

    final controller = VideoPlayerController.file(File(videoPath));
    videoPlayerController.value = controller;

    await controller.initialize();
    controller.setLooping(true);
    update();
  }

  void toggleVideoPlayback() {
    if (videoPlayerController.value != null) {
      if (isPlaying.value) {
        videoPlayerController.value!.pause();
      } else {
        videoPlayerController.value!.play();
      }
      isPlaying.value = !isPlaying.value;
    }
  }

  Future<void> checkExistingVideo() async {
    try {
      // You would typically fetch this from your API
      // For now, we'll just set it to false
      hasUploadedVideo.value = false;
      // videoUrl.value = '';

      // If there's a video URL, initialize the video player
      if (videoUrl.value.isNotEmpty) {
        await initializeVideoPlayerFromNetwork(videoUrl.value);
        hasUploadedVideo.value = true;
      }
    } catch (e) {
      print('Error checking existing video: $e');
    }
  }

  Future<void> initializeVideoPlayerFromNetwork(String url) async {
    disposeVideoController();

    final controller = VideoPlayerController.network(url);
    videoPlayerController.value = controller;

    await controller.initialize();
    hasUploadedVideo.value = true;

    controller.setLooping(true);
    update();
  }

  ///UPLOAD INTRO VIDEO....
  UploadInitResponse? uploadInitVideoFile;

  Future<void> uploadIntroInit() async {
    if (selectedVideo.value == null) {
      commonSnackBar(message: "No video selected");
      return;
    }
    try {
      isUploading.value = true;

      // 1. VIDEO
      final videoFile = File(selectedVideo.value?.path ?? "");
      final vInfo = getFileInfo(videoFile);
      Map<String, dynamic> queryParams = {
        ApiKeys.fileName: vInfo['fileName'],
        ApiKeys.fileType: vInfo['mimeType']
      };

      ResponseModel? response = await PersonalProfileRepo()
          .uploadIntroVideoInit(queryParams: queryParams);

      if (response?.isSuccess ?? false) {
        uploadInitResponse.value = ApiResponse.complete(response);
        final uploadInit =
            UploadInitResponse.fromJson(response?.response?.data);
        uploadInitVideoFile = uploadInit;
        await uploadFileToS3(
          file: videoFile,
          fileType: vInfo['mimeType']!,
          preSignedUrl: uploadInitVideoFile?.uploadUrl ?? "",
        );
      } else {
        isUploading.value = false;

        uploadInitResponse.value = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isUploading.value = false;

      uploadInitResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> uploadFileToS3(
      {required File file,
      required String fileType,
      required String preSignedUrl}) async {
    try {
      ResponseModel? response = await ChannelRepo().uploadVideoToS3(
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl,
        onProgress: (sent) {
          // videoProgress = sent;
          // totalProgress.value = (videoProgress + coverProgress) / 2;
        },
      );

      if (response?.isSuccess ?? false) {
        uploadIntroVideo(videoLink: uploadInitVideoFile?.publicUrl);
      } else {
        uploadFileToS3Response.value = ApiResponse.error('error');
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isUploading.value = false;

      uploadFileToS3Response.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> uploadIntroVideo({required String? videoLink}) async {
    try {
      ResponseModel response = await PersonalProfileRepo()
          .uploadIntroVideo(videoLink: videoLink ?? "");

      if (response.isSuccess) {
        // Extract video URL from response if available
        if (response.response?.data != null &&
            response.response!.data['data']['introVideo'] != null) {
          videoUrl.value = response.response!.data['data']['introVideo'];
          await initializeVideoPlayerFromNetwork(videoUrl.value);
          logs(" videoUrl.value========== ${videoUrl.value}");
        }

        hasUploadedVideo.value = true;
        commonSnackBar(
            message: response.message ?? 'Video uploaded successfully');
      } else {
        isUploading.value = false;
        commonSnackBar(message: response.message ?? 'Upload failed');
      }
    } catch (e) {
      isUploading.value = false;

      print('Error uploading video: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteIntroVideo() async {
    try {
      isUploading.value = true;

      ResponseModel response =
          await PersonalProfileRepo().deleteIntroVideoRepo();

      if (response.isSuccess) {
        videoUrl.value = "";
        isUploading.value = false;
        resetVideo();
        hasUploadedVideo.value = false;
        Get.back();
        commonSnackBar(
            message: response.message ?? 'Video deleted successfully');
      } else {
        commonSnackBar(message: response.message ?? 'Delete failed');
      }
    } catch (e) {
      print('Error uploading video: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUploading.value = false;
    }
  }
}
