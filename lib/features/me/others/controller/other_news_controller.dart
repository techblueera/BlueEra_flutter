import 'dart:io';

import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/others/model/other_news_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherNewsController extends GetxController {
  final OtherRepo _repo = OtherRepo();

  var aboutList = <OtherNewsData>[].obs;
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
    getNewsRepo();
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedImage.value = null;
  }

  void setFormData(OtherNewsData data) {
    titleController.text = data.title ?? "";
    descriptionController.text = data.description ?? "";
    // Image handling would require checking if we want to show existing image or only new selection
    selectedImage.value = null;
  }

  Future<void> pickImage(BuildContext context) async {
    final String? path = await SelectProfilePictureDialog.showLogoDialog(
        context, "Upload Picture");
    if (path != null && path.isNotEmpty) {
      selectedImage.value = File(path);
    }
  }

  Future<void> getNewsRepo() async {
    isLoading.value = true;
    try {
      final response = await _repo.getNewsRepo();
      if (response != null && response.isSuccess) {
        final model = OtherNewsModel.fromJson(response.response?.healthCareData);
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

  Future<void> createNewsRepo() async {
    if (selectedImage.value == null) {
      commonSnackBar(message: "Please select an image");
      return;
    }
    if (titleController.text.isEmpty) {
      commonSnackBar(message: "Please enter title");
      return;
    }
    if (descriptionController.text.isEmpty) {
      commonSnackBar(message: "Please enter news");
      return;
    }

    isLoading.value = true;
    try {
      UploadResult? uploadResult =
          await S3UploadService.uploadFile(selectedImage.value!);

      if (uploadResult.isSuccess) {
        final body = {
          "imageUrl": uploadResult.url,
          "title": titleController.text,
          "news": descriptionController.text
        };

        final response = await _repo.createNewsRepo(body);
        if (response != null && response.isSuccess) {
          commonSnackBar(message: "Created successfully");
          Get.back(); // Close form/screen
          getNewsRepo(); // Refresh list
        } else {
          commonSnackBar(message: response?.message ?? "Failed to create");
        }
      } else {
        commonSnackBar(message: "Image upload failed");
      }
    } catch (e) {
      commonSnackBar(message: "Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateNewsRepo(String id,
      {String? existingImageUrl}) async {
    if (titleController.text.isEmpty) {
      commonSnackBar(message: "Please enter title");
      return;
    }
    if (descriptionController.text.isEmpty) {
      commonSnackBar(message: "Please enter news");
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
          commonSnackBar(message: "Image upload failed");
          isLoading.value = false;
          return;
        }
      }

      final body = {
        "imageUrl": imageUrl,
        "title": titleController.text,
        "news": descriptionController.text
      };

      final response = await _repo.updateNewsRepo(id, body);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: "Updated successfully");
        Get.back();
        getNewsRepo();
      } else {
        commonSnackBar(message: response?.message ?? "Failed to update");
      }
    } catch (e) {
      commonSnackBar(message: "Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteNewsRepo(String id) async {
    isLoading.value = true;
    try {
      final response = await _repo.deleteNewsRepo(id);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: "Deleted successfully");
        getNewsRepo();
      } else {
        commonSnackBar(message: response?.message ?? "Failed to delete");
      }
    } catch (e) {
      commonSnackBar(message: "Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
