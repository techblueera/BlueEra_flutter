import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class MedicalGalleryController extends GetxController {
  var galleryList = <OtherServiceGalleryData>[].obs;
  var isLoading = true.obs;
  var isUploading = false.obs;

  final List<String> categories = [
    AppStrings.medicalGalleryExternalParking.tr,
    AppStrings.medicalGalleryInteriorPhotos.tr,
    AppStrings.medicalGalleryEquipmentPhotos.tr,
    AppStrings.medicalGalleryTeamStaffPhotos.tr,
    AppStrings.medicalGalleryMedicinesProducts.tr,
    AppStrings.medicalGalleryBillingCounter.tr,
  ];

  var selectedCategory = ''.obs;
  var selectedImages = <String>[].obs;
  final int maxImages = 6;

  @override
  void onInit() {
    super.onInit();
    fetchGallery();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // FETCH ALL GALLERY
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchGallery() async {
    try {
      isLoading.value = true;
      galleryList.clear();

      ResponseModel response = await MedicalRepo().fetchMedicalGalleryRepo();

      if (response.isSuccess) {
        OtherServiceGalleryResModel model = OtherServiceGalleryResModel.fromJson(response.response?.data);
        if (model.data != null && model.data!.isNotEmpty) {
          for (var photo in model.data!) {
            if (photo.imageUrls != null && photo.imageUrls!.isNotEmpty) {
              galleryList.add(photo);
            }
          }
        }
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // IMAGE SELECTION
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void onCategoryChanged(String? value) {
    if (value != null) selectedCategory.value = value;
  }

  void addImage(String path) {
    if (selectedImages.length < maxImages) {
      selectedImages.add(path);
    } else {
      commonSnackBar(
          message:
              '${AppStrings.medicalLimitReachedPrefix.tr} $maxImages ${AppStrings.medicalLimitReachedSuffix.tr}');
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  void resetUploadForm() {
    selectedCategory.value = '';
    selectedImages.clear();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // UPLOAD â†’ S3 â†’ CREATE GALLERY
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> uploadAndCreateGallery() async {
    if (selectedCategory.value.isEmpty) {
      commonSnackBar(message: AppStrings.medicalPleaseSelectCategory);
      return;
    }
    if (selectedImages.isEmpty) {
      commonSnackBar(message: AppStrings.medicalPleaseSelectAtLeastOneImage);
      return;
    }

    try {
      isUploading.value = true;
      List<String> uploadedUrls = [];

      // Upload each image to S3
      for (var filePath in selectedImages) {
        UploadResult result = await S3UploadService.uploadFile(File(filePath));
        if (result.isSuccess) {
          uploadedUrls.add(result.url);
        } else {
          commonSnackBar(message: result.message);
          return;
        }
      }

      if (uploadedUrls.isEmpty) {
        commonSnackBar(message: AppStrings.medicalFailedToUploadImages);
        return;
      }

      // POST to gallery API
      Map<String, dynamic> body = {
        'title': selectedCategory.value,
        'imageUrls': uploadedUrls,
      };

      ResponseModel response = await MedicalRepo().createMedicalGalleryRepo(params: body);

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalGalleryUploadedSuccessfully.tr);
        resetUploadForm();
        Get.back();
        fetchGallery();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUploading.value = false;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // DELETE GALLERY IMAGE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> deleteGalleryImage({
    required String galleryId,
    required String imageUrl,
  }) async {
    try {
      ResponseModel response = await MedicalRepo().deleteMedicalGalleryImageRepo(
        galleryId: galleryId,
        params: {'imageUrl': imageUrl},
      );

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.medicalImageDeletedSuccessfully.tr);
        fetchGallery();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // DELETE ENTIRE GALLERY ENTRY
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> deleteGalleryEntry({required String galleryId}) async {
    try {
      ResponseModel response = await MedicalRepo().deleteMedicalGalleryRepo(galleryId: galleryId);

      if (response.isSuccess) {
        galleryList.removeWhere((g) => g.id == galleryId);
        commonSnackBar(message: response.message ?? AppStrings.medicalGalleryDeleted.tr);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
