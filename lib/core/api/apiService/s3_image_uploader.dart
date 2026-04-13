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

  // ✅ Upload all images in parallel
  Future<bool> uploadAll(List<UploadS3ImageModel> images) async {
    if (images.isEmpty) return true;

    final totalImages = images.length;
    isUploading.value = true;
    overallProgress.value = 0.2;

    final progressMap = <int, double>{};

    void updateOverall() {
      final total = progressMap.values.fold(0.0, (a, b) => a + b);
      overallProgress.value = (0.2 + (total / totalImages) * 0.8).clamp(0.0, 1.0);
    }

    try {
      final futures = List.generate(totalImages, (i) {
        final image = images[i];
        final file = File(image.path);
        return _uploadSingle(
          file: file,
          fileType: image.mimeType,
          preSignedUrl: image.preSignedUrl ?? '',
          onProgress: (progress) {
            progressMap[i] = progress;
            updateOverall();
          },
        );
      });

      final results = await Future.wait(futures);

      overallProgress.value = 1.0;
      isUploading.value = false;

      return results.every((ok) => ok);
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