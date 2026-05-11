import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/others/model/about_organisation_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AboutOrganisationController extends GetxController {
  final OtherRepo _repo = OtherRepo();

  var aboutList = <AboutOrganisationData>[].obs;
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
    getAboutOrganisation();
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedImage.value = null;
  }

  void setFormData(AboutOrganisationData data) {
    titleController.text = data.title ?? "";
    descriptionController.text = data.description ?? "";
    // Image handling would require checking if we want to show existing image or only new selection
    selectedImage.value = null;
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  Future<void> getAboutOrganisation() async {
    isLoading.value = true;
    try {
      final response = await _repo.getAboutOrganisationRepo();
      if (response != null && response.isSuccess) {
        final model = AboutOrganisationModel.fromJson(response.response?.data);
        if (model.success == true && model.data != null) {
          aboutList.assignAll(model.data!);
        }
      } else {
        // Handle error
      }
    } catch (e) {
      print("Error fetching about organisation: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createAboutOrganisation() async {
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
      UploadResult? uploadResult = await S3UploadService.uploadFile(selectedImage.value!);

      if (uploadResult.isSuccess) {
        final body = {
          "imageUrl": uploadResult.url,
          "title": titleController.text,
          "description": descriptionController.text
        };

        final response = await _repo.createAboutOrganisationRepo(body);
        if (response != null && response.isSuccess) {
          commonSnackBar(message: AppStrings.genericCreatedSuccess.tr);
          Get.back(); // Close form/screen
          getAboutOrganisation(); // Refresh list
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

  Future<void> updateAboutOrganisation(String id, {String? existingImageUrl}) async {
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
        UploadResult? uploadResult = await S3UploadService.uploadFile(selectedImage.value!);
        if (uploadResult.isSuccess) {
          imageUrl = uploadResult.url;
        } else {
           commonSnackBar(message: AppStrings.genericImageUploadFailed.tr);
           isLoading.value = false;
           return;
        }
      }

      final body = {
        "imageUrl": imageUrl,
        "title": titleController.text,
        "description": descriptionController.text
      };

      final response = await _repo.updateAboutOrganisationRepo(id, body);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: AppStrings.genericUpdatedSuccess.tr);
        Get.back();
        getAboutOrganisation();
      } else {
        commonSnackBar(message: response?.message ?? AppStrings.labFailedToUpdate.tr);
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAboutOrganisation(String id) async {
    isLoading.value = true;
    try {
      final response = await _repo.deleteAboutOrganisationRepo(id);
      if (response != null && response.isSuccess) {
        commonSnackBar(message: AppStrings.genericDeletedSuccess.tr);
        getAboutOrganisation();
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
