// s3_image_uploader.dart

import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';

class S3ImageUploader {
  static final S3ImageUploader _instance = S3ImageUploader._internal();
  factory S3ImageUploader() => _instance;
  S3ImageUploader._internal();

  // ✅ Upload progress — observable
  final Rx<ApiResponse<ResponseModel>> uploadResponse =
      ApiResponse<ResponseModel>.loading().obs;

  final RxDouble overallProgress = 0.0.obs;
  final RxBool   isUploading     = false.obs;
  final RxString currentFileName = ''.obs;

  bool assignPreSignedUrls({
    required List<UploadS3ImageModel> images,
    required List<String> preSignedUrls,
  }) {
    if (images.length != preSignedUrls.length) {
      log('Mismatch: ${images.length} images vs ${preSignedUrls.length} preSignedUrls');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    }

    for (var i = 0; i < images.length; i++) {
      images[i].preSignedUrl = preSignedUrls[i];
    }

    return true;
  }

  // ✅ Upload all images sequentially
  Future<bool> uploadAll(List<UploadS3ImageModel> images) async {
    if (images.isEmpty) return true;

    final totalImages = images.length;
    isUploading.value = true;
    overallProgress.value = 0.0;

    try {
      for (var i = 0; i < totalImages; i++) {
        final image       = images[i];
        final file        = File(image.path);
        final fileType    = image.mimeType;
        final preSignedUrl = image.preSignedUrl ?? '';

        currentFileName.value = file.path.split('/').last;

        final success = await _uploadSingle(
          file:          file,
          fileType:      fileType,
          preSignedUrl:  preSignedUrl,
          onProgress: (progress) {
            final imageFraction   = 0.8 / totalImages;
            final overall = 0.2 + (i * imageFraction) + (progress * imageFraction);
            overallProgress.value = overall.clamp(0.0, 1.0);

            log('Uploading ${file.path}: '
                '${(progress * 100).toStringAsFixed(0)}%, '
                'Overall: ${(overallProgress.value * 100).toStringAsFixed(0)}%');
          },
        );

        // ✅ stop if any image fails
        if (!success) {
          isUploading.value = false;
          return false;
        }
      }

      overallProgress.value = 1.0;
      isUploading.value = false;
      return true;

    } catch (e) {
      isUploading.value = false;
      log('S3ImageUploader: uploadAll failed. $e');
      return false;
    }
  }

  // ✅ Upload single image to S3
  Future<bool> _uploadSingle({
    required File file,
    required String fileType,
    required String preSignedUrl,
    required Function(double progress) onProgress,
  }) async {
    try {
      final response = await ChannelRepo().uploadVideoToS3(
        onProgress:   onProgress,
        file:         file,
        fileType:     fileType,
        preSignedUrl: preSignedUrl,
      );

      if (response?.isSuccess ?? false) {
        uploadResponse.value = ApiResponse.complete(response);
        return true;
      } else {
        uploadResponse.value = ApiResponse.error('error');
        commonSnackBar(message: response?.message ?? AppStrings.somethingWentWrong.tr);
        return false;
      }
    } catch (e) {
      uploadResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      log('S3ImageUploader: _uploadSingle failed. $e');
      return false;
    }
  }

  // ✅ Reset state
  void reset() {
    uploadResponse.value   = ApiResponse.loading();
    overallProgress.value  = 0.0;
    isUploading.value      = false;
    currentFileName.value  = '';
  }
}