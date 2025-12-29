import 'dart:io';

import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AboutUsController extends GetxController {
  final Rxn<File> directorMessageImageFile = Rxn<File>();
  final Rxn<File> historyImageFile = Rxn<File>();
  final Rxn<File> noticeNewsImageFile = Rxn<File>();
  RxString historyText = ''.obs;
  RxString notice_news_messageText = ''.obs;
  RxString directorMessageText = ''.obs;
  RxString departmentDescriptionText = ''.obs;
  RxString courseDescriptionText = ''.obs;
  RxString managementDescriptionText = ''.obs;

  ///DEPARTMENT SCREEN LOGIC
  var selectedImages = <File>[].obs;
  final ImagePicker _picker = ImagePicker();

  // Pick images from gallery or camera
  Future<void> pickImages(ImageSource source) async {
    if (selectedImages.length >= 5) {
      Get.snackbar("Limit Reached", "You can only add up to 5 images.");
      return;
    }

    if (source == ImageSource.gallery) {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      // Only add images up to the limit of 5
      for (var file in pickedFiles) {
        if (selectedImages.length < 5) {
          selectedImages.add(File(file.path));
        }
      }
    } else {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        selectedImages.add(File(pickedFile.path));
      }
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  int maxDepartmentImageUpload = 5;
  final RxList<File> addMoreImages = <File>[].obs;

// Validation Variables
  final isFormValid = false.obs;

  // This function checks all conditions
  void courseValidateForm({
    required String courseName,
    required String admissionProcess,
    required String eligibility,
    required String courseFee,
    required String description,
    required String courseDuration,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = courseName.isNotEmpty &&
        admissionProcess.isNotEmpty &&
        eligibility.isNotEmpty &&
        courseFee.isNotEmpty &&
        courseDuration.isNotEmpty &&
        description.isNotEmpty;
  }

  // This function checks all conditions
  void validateForm({
    required String deptName,
    required String hodName,
    required String staffNames,
    required String description,
    required List images,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = deptName.isNotEmpty &&
        hodName.isNotEmpty &&
        staffNames.isNotEmpty &&
        description.isNotEmpty &&
        images.isNotEmpty;
  }

  void contactUsValidateForm({
    required String branchName,
    required String branchWebsiteUrl,
    required String branchLocation,
    required String departmentRole,
    required String departmentEmailAddress,
    required String departmentPhoneNo,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = branchName.isNotEmpty &&
        branchWebsiteUrl.isNotEmpty &&
        branchLocation.isNotEmpty &&
        departmentRole.isNotEmpty &&
        departmentPhoneNo.isNotEmpty &&
        departmentEmailAddress.isNotEmpty;
  }

  ///Only Department Validation

  void departmentValidateForm({

    required String departmentRole,
    required String departmentEmailAddress,
    required String departmentPhoneNo,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value =
        departmentRole.isNotEmpty &&
        departmentPhoneNo.isNotEmpty &&
        departmentEmailAddress.isNotEmpty;
  }

  ///Only Branch Validation
  void branchValidateForm({
    required String branchName,
    required String branchWebsiteUrl,
    required String branchLocation,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = branchName.isNotEmpty &&
        branchWebsiteUrl.isNotEmpty &&
        branchLocation.isNotEmpty;
  }

  // This function checks all conditions
  void managementValidateForm({
    required String managementName,
    required String profession,
    required String qualification,
    required String message,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = managementName.isNotEmpty &&
        profession.isNotEmpty &&
        qualification.isNotEmpty &&
        message.isNotEmpty;
  }

  ///ADD COURSE...
// Radio button state
  var feeType = 'Yearly'.obs; // Default selection

  // Fee amount
  var feeAmount = ''.obs;

  void setFeeType(String? value) {
    if (value != null) feeType.value = value;
  }

  ///ADD MANAGEMENT....
  static const int maxQualifications = 5;

  var qualifications = <TextEditingController>[].obs;

  void addQualification() {
    if (qualifications.length < maxQualifications) {
      qualifications.add(TextEditingController());
    } else {
      commonSnackBar(
          message: "Limit Reached You can add maximum 5 qualifications");
    }
  }

  void removeQualification(int index) {
    if (qualifications.length > 1) {
      qualifications[index].dispose();
      qualifications.removeAt(index);
    } else {
      commonSnackBar(message: "At least 1 qualification is required");
    }
  }

  bool validateQualifications() {
    for (var controller in qualifications) {
      if (controller.text.trim().isEmpty) {
        commonSnackBar(message: "Qualification field cannot be empty");
        return false;
      }
    }
    return true;
  }


  ///Only Branch Validation
  void noticesNewsValidateForm({
    required String uploadPhoto,
    required String noticeDescription,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = noticeDescription.isNotEmpty &&
        uploadPhoto.isNotEmpty;
  }

  ///Only Gallery Validation
  void addPhotosValidateForm({
    required String uploadPhoto,
    required String title,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = title.isNotEmpty &&
        uploadPhoto.isNotEmpty;
  }
}
