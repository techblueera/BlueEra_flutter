import 'dart:io';

import 'package:BlueEra/core/api/apiService/s3_image_uploader.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';

class EarnProfileController extends GetxController {
  RxBool isCreatingProfile = false.obs;

  final _uploader = S3ImageUploader();

  /// Create earn profile via API, then upload logo + gallery to S3 in parallel.
  Future<bool> createEarnProfile({
    required String serviceName,
    required File serviceLogo,
    required String profileType,
    required String address,
    required double lat,
    required double lng,
    String? foodType,
    String? houseNumber,
    String? alternatePhoneNumber,
    bool homeDelivery = false,
    bool monthlyPayment = false,
    List<File>? galleryImages,
  }) async {
    isCreatingProfile.value = true;

    try {
      // Build all images list (logo first, then gallery)
      final allImages = <UploadS3ImageModel>[];

      allImages.add(UploadS3ImageModel(
        path: serviceLogo.path,
        mimeType: lookupMimeType(serviceLogo.path) ?? 'image/jpeg',
      ));

      if (galleryImages != null) {
        for (final img in galleryImages) {
          allImages.add(UploadS3ImageModel(
            path: img.path,
            mimeType: lookupMimeType(img.path) ?? 'image/jpeg',
          ));
        }
      }

      // Build logo and gallery content types separately
      final logoImage = allImages.first;
      final galleryImagesList = allImages.length > 1
          ? allImages.sublist(1)
          : <UploadS3ImageModel>[];

      final Map<String, dynamic> params = {
        'serviceName': serviceName,
        'profileType': profileType,
        'address': address,
        'lat': lat,
        'lng': lng,
        'homeDelivery': homeDelivery,
        'serviceLogo': logoImage.mimeType,
        if (galleryImagesList.isNotEmpty)
          'galleryImages': galleryImagesList.map((e) => e.mimeType).toList(),
      };

      if (foodType != null) params['foodType'] = foodType;
      if (houseNumber != null && houseNumber.isNotEmpty) {
        params['houseNumber'] = houseNumber;
      }
      if (alternatePhoneNumber != null && alternatePhoneNumber.isNotEmpty) {
        params['alternatePhoneNumber'] = alternatePhoneNumber;
      }
      if (monthlyPayment) params['monthlyPayment'] = monthlyPayment;

      // Step 1: Call API to create profile and get pre-signed URLs
      final response =
          await EarnProfileRepo().createEarnProfileRepo(params: params);

      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }

      // Step 2: Extract pre-signed URLs from response
      final data = response.response?.data;
      final uploadUrls = data?['uploadUrls'];
      final List<String> preSignedUrls = [];

      // Logo URL
      final logoUrl = uploadUrls?['serviceLogo'];
      if (logoUrl is String && logoUrl.isNotEmpty) {
        preSignedUrls.add(logoUrl);
      }

      // Gallery URLs
      final galleryUrls = uploadUrls?['galleryImages'];
      if (galleryUrls is List) {
        preSignedUrls.addAll(List<String>.from(galleryUrls));
      }

      if (preSignedUrls.isEmpty) {
        commonSnackBar(message: 'Profile created successfully!');
        await _refreshProfile();
        return true;
      }

      // Step 3: Assign pre-signed URLs to images
      final assigned =
          _uploader.assignPreSignedUrls(
            images: allImages,
            preSignedUrls: preSignedUrls,
          );

      if (!assigned) return false;

      // Step 4: Upload all images in parallel with progress dialog
      UploadProgressDialog.show(initialProgress: 0.2, title: 'Uploading images...');

      final uploadSuccess = await _uploader.uploadAll(allImages);

      UploadProgressDialog.close();

      if (uploadSuccess) {
        commonSnackBar(message: 'Profile created successfully!');
        await _refreshProfile();
        return true;
      } else {
        commonSnackBar(message: 'Profile created but some images failed to upload');
        await _refreshProfile();
        return true;
      }
    } catch (e) {
      UploadProgressDialog.close();
      debugPrint('EarnProfileController.createEarnProfile error: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isCreatingProfile.value = false;
      _uploader.reset();
    }
  }

  /// Refresh personal profile so earnProfileType gets updated in the dashboard.
  Future<void> _refreshProfile() async {
    try {
      final controller = Get.find<ViewPersonalDetailsController>();
      await controller.viewPersonalProfile();
    } catch (_) {}
  }
}
