import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_about_us_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/upload_init_response.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolAboutUsController extends GetxController {
  Rx<ApiResponse> getAboutUsSchoolResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSchoolContactUsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> visionMissionResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> managementTrustResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;
  RxString visionMissionText = ''.obs;
  RxString historyText = ''.obs;
  RxString managementDescriptionText = ''.obs;

  final Rxn<File> historyImageFile = Rxn<File>();
  final isFormValid = false.obs;
  final isUploading = false.obs;

  // Initial values (to check if data changed)
  String initialHistoryText = "";
  String initialHistoryImageUrl = "";
  RxString managementProfile = ''.obs;

  final isImageUpdated = false.obs;

  ///GET ABOUT US......
  Rx<AboutUsData>? aboutUsData = AboutUsData().obs;
  Rx<SchoolContactUsData>? schoolContactUsData = SchoolContactUsData().obs;

  ///====================API CALLING START==============================
  ///GET BRANCH CONTACT DETAILS...

  Future<void> getBranchDetailsController() async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo()
          .getSchoolContactRepo();
      SchoolContactUsModel schoolContactUsModel =
          SchoolContactUsModel.fromJson(response.response?.data);
      schoolContactUsData?.value =
          schoolContactUsModel.data ?? SchoolContactUsData();
      if (response.isSuccess) {
        getSchoolContactUsResponse.value =
            ApiResponse.complete(schoolContactUsModel);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getSchoolContactUsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      getSchoolContactUsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> getSchoolAboutUsController() async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo()
          .getSchoolAboutUsRepo(schoolID: schoolIDGlobal);
      SchoolAboutUsModel schoolAboutUsModel =
          SchoolAboutUsModel.fromJson(response.response?.data);
      aboutUsData?.value = schoolAboutUsModel.data ?? AboutUsData();
      if (response.isSuccess) {
        getAboutUsSchoolResponse.value =
            ApiResponse.complete(schoolAboutUsModel);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getAboutUsSchoolResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      getAboutUsSchoolResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> updateVisionMissionController(
      {required String visionMissionText}) async {
    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().updateSchoolAboutUsRepo(
          aboutUsID: aboutUsData?.value.id ?? "",
          reqBODY: {ApiKeys.visionAndMission: visionMissionText});

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        visionMissionResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      // TODO
      visionMissionResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///UPDATE History Info....
  UploadInitResponse uploadInit = UploadInitResponse();

  Future<void> uploadEductionHistoryDocInit() async {
    if (historyImageFile.value == null) {
      commonSnackBar(message: AppStrings.noVideoSelected);
      return;
    }
    try {
      isUploading.value = true;

      // 1. VIDEO
      final imageFile = File(historyImageFile.value?.path ?? "");
      final vInfo = getFileInfo(imageFile);
      Map<String, dynamic> queryParams = {
        ApiKeys.fileName: vInfo['fileName'],
        ApiKeys.fileType: vInfo['mimeType']
      };

      ResponseModel? response =
          await SchoolRepo().uploadEducationDocRepo(queryParams: queryParams);

      if (response?.isSuccess ?? false) {
        uploadInitResponse.value = ApiResponse.complete(response);
        UploadInitResponse uploadInit =
            UploadInitResponse.fromJson(response?.response?.data);
        await uploadFileToS3(
          file: imageFile,
          fileType: vInfo['mimeType']!,
          preSignedUrl: uploadInit.uploadUrl ?? "",
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
        onProgress: (sent) {},
      );

      if (response?.isSuccess ?? false) {
        updateHistoryController();
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

  Future<void> updateHistoryController() async {
    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().updateSchoolAboutUsRepo(
          aboutUsID: aboutUsData?.value.id ?? "",
          reqBODY: {
            ApiKeys.history: historyText,
            ApiKeys.photo: uploadInit.publicUrl ?? ""
          });

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        visionMissionResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      // TODO
      visionMissionResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///ADD MANAGEMENT TRUST
  Future<void> addManagementTrustController() async {
    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().updateSchoolAboutUsRepo(
        reqBODY: {ApiKeys.management: aboutUsData?.value.management},
        aboutUsID: aboutUsData?.value.id ?? "",
      );

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        managementTrustResponse.value =
            ApiResponse.complete(response.response?.data);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        managementTrustResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      // TODO
      managementTrustResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///====================API CALLING END==============================
  ///VALIDATION....

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

  ///UPDATE VISION AND MISSION....
  ///Only Branch Validation
  void noticesNewsValidateForm({
    required String uploadPhoto,
    required String noticeDescription,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = noticeDescription.isNotEmpty && uploadPhoto.isNotEmpty;
  }

  // Logic to check if user changed anything
  void validateHistoryForm() {
    bool isTextChanged = historyText.value.trim() != initialHistoryText.trim();

    // Check if image changed (either new file picked or existing image removed)
    bool isImageChanged = historyImageFile.value != null ||
        (initialHistoryImageUrl.isNotEmpty &&
            historyImageFile.value == null &&
            initialHistoryText.isNotEmpty);

    // If you want to enable button ONLY if text is not empty AND (Text changed OR Image changed)
    isFormValid.value = historyText.value.trim().isNotEmpty &&
        (isTextChanged || historyImageFile.value != null);
  }
}
