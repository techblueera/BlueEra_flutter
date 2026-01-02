import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/institution_fetch_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/view/category/school_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SchoolController extends GetxController {
  final Rxn<File> directorMessageImageFile = Rxn<File>();
  final Rxn<File> historyImageFile = Rxn<File>();
  final Rxn<File> noticeNewsImageFile = Rxn<File>();
  RxString historyText = ''.obs;
  RxString notice_news_messageText = ''.obs;
  RxString directorMessageText = ''.obs;
  RxString departmentDescriptionText = ''.obs;
  RxString courseDescriptionText = ''.obs;

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



  ///ADD COURSE...
// Radio button state
  var feeType = 'Yearly'.obs; // Default selection

  // Fee amount
  var feeAmount = ''.obs;

  void setFeeType(String? value) {
    if (value != null) feeType.value = value;
  }



  ///Only Gallery Validation
  void addPhotosValidateForm({
    required String uploadPhoto,
    required String title,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = title.isNotEmpty && uploadPhoto.isNotEmpty;
  }

  ///GENERATE VIA AI SCHOOL DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  final fullSchoolAddressController = TextEditingController();

  clearAiGenerateFiled() {
    searchController.clear();
    websiteController.clear();
    fullSchoolAddressController.clear();
  }

  @override
  void onClose() {
    searchController.dispose();
    websiteController.dispose();
    fullSchoolAddressController.dispose();
    super.onClose();
  }

  Rx<InstitutionFetchModel>? institutionFetchModel =
      InstitutionFetchModel().obs;
  Rx<ApiResponse> generateSchoolViaAIResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createSchoolResponse = ApiResponse.initial('Initial').obs;

  Future<void> aiInstitutionFetchDetailsController() async {
    String school = searchController.text;
    String website = websiteController.text;
    String fullSchoolAddress = fullSchoolAddressController.text;
    // Logic for AI generation goes here
    Get.back();
    try {
      ResponseModel response =
          await SchoolRepo().aiInstitutionFetchDetailsRepo(reqBody: {
            "name": "Parul University",
            "url": "https://paruluniversity.ac.in",
            "address": "Private university in Gujarat"
          });
      // ResponseModel response =
      //     await SchoolRepo().aiInstitutionFetchDetailsRepo(reqBody: {
      //   ApiKeys.name: school,
      //   ApiKeys.url: website,
      //   ApiKeys.address: fullSchoolAddress,
      // });
      if (response.isSuccess) {
        final data = response.response?.data;
        institutionFetchModel?.value = InstitutionFetchModel.fromJson(data);
        generateSchoolViaAIResponse.value =
            ApiResponse.complete(institutionFetchModel);
        Get.to(SchoolPreviewScreen());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        generateSchoolViaAIResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      // TODO
      generateSchoolViaAIResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> createSchoolController() async {
    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().createSchoolRepo(
          reqBody: (institutionFetchModel?.value.data ?? {}));
      if (response.isSuccess) {
        commonSnackBar(message: "School create successfully");
        createSchoolResponse.value =
            ApiResponse.complete(institutionFetchModel);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        createSchoolResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      // TODO
      createSchoolResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
}
