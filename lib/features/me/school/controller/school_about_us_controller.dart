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
  Rx<ApiResponse> updateSchoolContactInfoResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSchoolContactUsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> visionMissionResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> managementTrustResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;
  RxString visionMissionText = ''.obs;
  RxString historyText = ''.obs;
  RxString directorMessageText = ''.obs;
  RxString managementDescriptionText = ''.obs;

  final Rxn<File> historyImageFile = Rxn<File>();
  final Rxn<File> directorMessageImageFile = Rxn<File>();
  final Rxn<File> managementProfileImageFile = Rxn<File>();
  final isFormValid = false.obs;
  final isUploading = false.obs;

  // Initial values (to check if data changed)
  String initialDirectText = "";
  String initialDirectImageUrl = "";

  String initialManagementProfileImageUrl = "";

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
      ResponseModel response = await SchoolRepo().getSchoolContactRepo();
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

  ///UPDATE CONTACT INFO...
  Future<void> updateBranchContactDetailsController() async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().updateSchoolContactRepo(
          reqParm: {"contactInfo": schoolContactUsData?.value.contactInfo}, contactID: schoolContactUsData?.value.id??"");

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
            response.response?.data["message"] ?? AppStrings.successful);
        updateSchoolContactInfoResponse.value =
            ApiResponse.complete(response.response?.data);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        updateSchoolContactInfoResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      updateSchoolContactInfoResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> getSchoolAboutUsController() async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response =
          await SchoolRepo().getSchoolAboutUsRepo(schoolID: schoolIDGlobal);
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
      commonSnackBar(message: AppStrings.noImageSelected);
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
        uploadInit = UploadInitResponse.fromJson(response?.response?.data);
        await uploadFileToS3(
          file: imageFile,
          apiCallFrom: "HistoryDoc",
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
      required String apiCallFrom,
      required String preSignedUrl}) async {
    try {
      ResponseModel? response = await ChannelRepo().uploadVideoToS3(
        file: file,
        fileType: fileType,
        preSignedUrl: preSignedUrl,
        onProgress: (sent) {},
      );

      if (response?.isSuccess ?? false) {
        if (apiCallFrom == "HistoryDoc") {
          await updateHistoryController();
        } else if (apiCallFrom == "PrincipalDoc") {
          await updateDirectMessageController();
        }
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
            ApiKeys.history: historyText.value,
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

  ///UPLOAD PRINCIPAL DIRECT MESSAGE...

  UploadInitResponse uploadDirectMessageInit = UploadInitResponse();

  Future<void> uploadDirectMessageDocInit() async {
    if (directorMessageImageFile.value == null) {
      commonSnackBar(message: AppStrings.noImageSelected);
      return;
    }
    try {
      isUploading.value = true;
      // 1. VIDEO
      final imageFile = File(directorMessageImageFile.value?.path ?? "");
      final vInfo = getFileInfo(imageFile);
      Map<String, dynamic> queryParams = {
        ApiKeys.fileName: vInfo['fileName'],
        ApiKeys.fileType: vInfo['mimeType']
      };

      ResponseModel? response =
          await SchoolRepo().uploadEducationDocRepo(queryParams: queryParams);

      if (response?.isSuccess ?? false) {
        uploadInitResponse.value = ApiResponse.complete(response);
        uploadDirectMessageInit =
            UploadInitResponse.fromJson(response?.response?.data);
        await uploadFileToS3(
          file: imageFile,
          apiCallFrom: "PrincipalDoc",
          fileType: vInfo['mimeType']!,
          preSignedUrl: uploadDirectMessageInit.uploadUrl ?? "",
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

  Future<void> updateDirectMessageController() async {
    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().updateSchoolAboutUsRepo(
          aboutUsID: aboutUsData?.value.id ?? "",
          reqBODY: {
            ApiKeys.photo: uploadDirectMessageInit.publicUrl,
            ApiKeys.message: directorMessageText.value,
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

  ///UPLOAD PRINCIPAL DIRECT MESSAGE...

  UploadInitResponse uploadManagementInit = UploadInitResponse();

  Future<void> uploadManagementDocInit({
    required String name,
    required String bio,
    required String position,
    required String managementId,
    required List<String> qualificationList,
  }) async {
    if (managementProfileImageFile.value == null) {
      commonSnackBar(message: AppStrings.noImageSelected);
      return;
    }

    try {
      isUploading.value = true;
      // 1. IMAGE
      final imageFile = File(managementProfileImageFile.value?.path ?? "");
      final vInfo = getFileInfo(imageFile);
      Map<String, dynamic> queryParams = {
        ApiKeys.fileName: vInfo['fileName'],
        ApiKeys.fileType: vInfo['mimeType']
      };

      ResponseModel? response =
          await SchoolRepo().uploadEducationDocRepo(queryParams: queryParams);

      if (response?.isSuccess ?? false) {
        uploadInitResponse.value = ApiResponse.complete(response);
        uploadDirectMessageInit =
            UploadInitResponse.fromJson(response?.response?.data);

        try {
          ResponseModel? response = await ChannelRepo().uploadVideoToS3(
            file: imageFile,
            fileType: vInfo['mimeType']!,
            preSignedUrl: uploadDirectMessageInit.uploadUrl ?? "",
            onProgress: (sent) {},
          );

          if (response?.isSuccess ?? false) {
            aboutUsData?.value.management?.add(Management(
                qualification: qualifications.map((item) => item.text).toList(),
                name: name,
                bio: bio,
                photo: uploadDirectMessageInit.publicUrl,
                position: position));
            addManagementTrustController();
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
    required List<TextEditingController> qualification,
    required String message,
    required String profileImg,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = managementName.isNotEmpty &&
        profession.isNotEmpty &&
        qualification.isNotEmpty &&
        profileImg.isNotEmpty &&
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

    // If you want to enable button ONLY if text is not empty AND (Text changed OR Image changed)
    isFormValid.value = historyText.value.trim().isNotEmpty &&
        (isTextChanged || historyImageFile.value != null);
  }

  // Logic to check if user changed anything
  void validateDirectMessageForm() {
    bool isTextChanged =
        directorMessageText.value.trim() != initialDirectText.trim();

    // If you want to enable button ONLY if text is not empty AND (Text changed OR Image changed)
    isFormValid.value = directorMessageText.value.trim().isNotEmpty &&
        (isTextChanged || directorMessageImageFile.value != null);
  }

  ///Only Department Validation

  void departmentValidateForm({
    required String departmentRole,
    required String departmentEmailAddress,
    required String departmentPhoneNo,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = departmentRole.isNotEmpty &&
        departmentPhoneNo.isNotEmpty &&
        departmentEmailAddress.isNotEmpty;
  }
}
