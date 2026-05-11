import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/others/model/other_downloads_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherDownloadsController extends GetxController {
  final OtherRepo _repo = OtherRepo();

  var aboutList = <OtherDownloadsData>[].obs;
  var isLoading = false.obs;

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  var title = "".obs;
  var description = "".obs;
  Rx<File?> selectedImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    getDownloadsController();
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedImage.value = null;
  }

  void setFormData(OtherDownloadsData data) {
    titleController.text = data.title ?? "";
    descriptionController.text = data.description ?? "";
    // Image handling would require checking if we want to show existing image or only new selection
    selectedImage.value = null;
  }

  Future<void> pickImage(BuildContext context) async {
    final String? path = await SelectProfilePictureDialog.showLogoDialog(
        context, AppStrings.otherUploadPicture.tr);
    if (path != null && path.isNotEmpty) {
      selectedImage.value = File(path);
    }
  }

  Future<void> getDownloadsController() async {
    isLoading.value = true;
    try {
      final response = await _repo.getDownloadsRepo();
      if (response != null && response.isSuccess) {
        final model = OtherDownloadsModel.fromJson(response.response?.data);
        if (model.success == true && model.data != null) {
          aboutList.assignAll(model.data!);
        }
      } else {
        // Handle error
      }
    } catch (e) {
      print("Error fetching blogs: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createDownloadsController() async {
    if (selectedImage.value == null) {
      commonSnackBar(message: AppStrings.otherPleaseSelectImage.tr);
      return;
    }
    if (titleController.text.isEmpty) {
      commonSnackBar(message: AppStrings.otherPleaseEnterTitle.tr);
      return;
    }
    if (descriptionController.text.isEmpty) {
      commonSnackBar(message: AppStrings.otherPleaseEnterDescription.tr);
      return;
    }

    isLoading.value = true;
    try {
      UploadResult? uploadResult =
          await S3UploadService.uploadFile(selectedImage.value!);

      if (uploadResult.isSuccess) {
        final body = {
          "downloadUrl": uploadResult.url,
          "title": titleController.text,
          "description": descriptionController.text
        };

        final response = await _repo.createDownloadsRepo(body);
        if (response != null && response.isSuccess) {
          commonSnackBar(message: AppStrings.genericCreatedSuccess.tr);
          Get.back(); // Close form/screen
          getDownloadsController(); // Refresh list
        } else {
          commonSnackBar(message: response?.message ?? AppStrings.labFailedToCreate.tr);
        }
      } else {
        commonSnackBar(message: AppStrings.genericImageUploadFailed.tr);
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDownloadsController(String id,
      {String? existingImageUrl}) async {
    if (titleController.text.isEmpty) {
      commonSnackBar(message: AppStrings.otherPleaseEnterTitle.tr);
      return;
    }
    if (descriptionController.text.isEmpty) {
      commonSnackBar(message: AppStrings.otherPleaseEnterDescription.tr);
      return;
    }

    isLoading.value = true;
    try {
      String? imageUrl = existingImageUrl;

      if (selectedImage.value != null) {
        UploadResult? uploadResult =
            await S3UploadService.uploadFile(selectedImage.value!);
        if (uploadResult.isSuccess) {
          imageUrl = uploadResult.url;
        } else {
          commonSnackBar(message: AppStrings.genericImageUploadFailed.tr);
          isLoading.value = false;
          return;
        }
      }

      final body = {
        "downloadUrl": imageUrl,
        "title": titleController.text,
        "description": descriptionController.text
      };

      final response = await _repo.updateDownloadsRepo(id, body);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: AppStrings.genericUpdatedSuccess.tr);
        Get.back();
        getDownloadsController();
      } else {
        commonSnackBar(message: response?.message ?? AppStrings.labFailedToUpdate.tr);
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDownloadsController(String id) async {
    isLoading.value = true;
    try {
      final response = await _repo.deleteDownloadsRepo(id);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: AppStrings.genericDeletedSuccess.tr);
        getDownloadsController();
      } else {
        commonSnackBar(message: response?.message ?? AppStrings.labFailedToDelete.tr);
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
    }
  }
}
