import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_about_us_model.dart';
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/upload_init_response.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolAboutUsController extends GetxController {
  Rx<ApiResponse> getAboutUsSchoolResponse = ApiResponse.initial('Initial').obs;

  Rx<ApiResponse> visionMissionResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> managementTrustResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadInitResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> uploadFileToS3Response = ApiResponse.initial('Initial').obs;
  RxString visionMissionText = ''.obs;
  RxString historyText = ''.obs;
  RxString directorMessageText = ''.obs;
  RxString managementDescriptionText = ''.obs;
  final isDirectorImageUpdate = false.obs;

  final Rxn<File> historyImageFile = Rxn<File>();
  final Rxn<File> directorMessageImageFile = Rxn<File>();
  RxString directorProfile = ''.obs;

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
  Rx<SchoolDetailsData>? schoolDetailsData = SchoolDetailsData().obs;

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
      aboutUsData?.refresh();
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      getAboutUsSchoolResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  uploadSchoolLogoOrBannerImage(
      {required File uploadFile, required String uploadVia}) async {
    try {
      UploadResult? result = await S3UploadService.uploadFile(uploadFile);
      if (result.isSuccess) {
        ResponseModel response =
            await SchoolRepo().updateSchoolInfoRepo(reqBODY: {
          uploadVia: result.url,
        });
        if (response.isSuccess) {
          commonSnackBar(message: response.response?.data['message']);
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);

      // TODO
    }
  }

  Future<void> getSchoolByIdController() async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().getSchoolByIDRepo();

      SchoolDetailsResModel schoolAboutUsModel =
          SchoolDetailsResModel.fromJson(response.response?.data);
      schoolDetailsData?.value = schoolAboutUsModel.data ?? SchoolDetailsData();
      schoolDetailsData?.refresh();
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
        await getSchoolByIdController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        visionMissionResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
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
            "history": {
              ApiKeys.history: historyText.value,
              ApiKeys.photo: uploadInit.publicUrl ?? ""
            }
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
    } on Exception {
      // TODO
      visionMissionResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///ADD MANAGEMENT TRUST
  Future<void> addManagementTrustController({
    required String name,
    required String bio,
    required String position,
    required String managementId,
    required List<String> qualificationList,
  }) async {
    // Logic for AI generation goes here
    try {
      if (managementProfileImageFile.value == null) {
        commonSnackBar(message: AppStrings.noImageSelected);
        return;
      }

      UploadResult? result;
      result = await S3UploadService.uploadFile(
          File(managementProfileImageFile.value?.path ?? ""));
      if (result.isSuccess) {
        ResponseModel response = await SchoolRepo().createSchoolManagementRepo(
          reqBODY: {
            "name": name,
            "position": position,
            "photo": result.url,
            "bio": bio,
            "qualification": qualificationList
          },
          aboutUsID: aboutUsData?.value.id ?? "",
        );

        if (response.isSuccess) {
          Get.back();
          commonSnackBar(
              message:
                  response.response?.data["message"] ?? AppStrings.successful);
          managementTrustResponse.value =
              ApiResponse.complete(response.response?.data);
          updateAboutInfo();
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          managementTrustResponse.value =
              ApiResponse.error(AppStrings.somethingWentWrong);
        }
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        managementTrustResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      // TODO
      managementTrustResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///EDIT MANAGEMENT TRUST
  Future<void> editManagementTrustController({
    required int currentIndex,
    required String name,
    required String bio,
    required String position,
    required String managementId,
    required List<String> qualificationList,
  }) async {
    // Logic for AI generation goes here
    try {
      if (isImageUpdated.value) {
        if (managementProfileImageFile.value == null) {
          commonSnackBar(message: AppStrings.noImageSelected);
          return;
        }
      }
      ResponseModel response;

      if (isImageUpdated.value) {
        UploadResult? result;
        result = await S3UploadService.uploadFile(
            File(managementProfileImageFile.value?.path ?? ""));
        response = await SchoolRepo().updateSchoolManagementAboutUsRepo(
          reqBODY: {
            "name": name,
            "position": position,
            "photo": result.url,
            "bio": bio,
            "qualification": qualificationList
          },
          aboutUsID: aboutUsData?.value.id ?? "",
          managementIndex: currentIndex,
        );
      } else {
        response = await SchoolRepo().updateSchoolManagementAboutUsRepo(
          reqBODY: {
            "name": name,
            "position": position,
            "bio": bio,
            "qualification": qualificationList
          },
          aboutUsID: aboutUsData?.value.id ?? "",
          managementIndex: currentIndex,
        );
      }

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        managementTrustResponse.value =
            ApiResponse.complete(response.response?.data);
        updateAboutInfo();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        managementTrustResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
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
      UploadResult? result;
      if (isDirectorImageUpdate.value) {
        result = await S3UploadService.uploadFile(
            File(directorMessageImageFile.value?.path ?? ""));
      }
      ResponseModel response;
      if (result?.isSuccess ?? false) {
        response = await SchoolRepo().updateSchoolAboutUsRepo(
            aboutUsID: aboutUsData?.value.id ?? "",
            reqBODY: {
              "principalMessage": {
                ApiKeys.photo: result?.url,
                ApiKeys.message: directorMessageText.value,
              }
            });
      } else {
        response = await SchoolRepo().updateSchoolAboutUsRepo(
            aboutUsID: aboutUsData?.value.id ?? "",
            reqBODY: {
              "principalMessage": {
                ApiKeys.message: directorMessageText.value,
              }
            });
      }

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        updateAboutInfo();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        visionMissionResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      // TODO
      visionMissionResponse.value =
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

  updateAboutInfo() async {
    final schoolAboutUsController = Get.find<SchoolAboutUsController>();

    await schoolAboutUsController.getSchoolAboutUsController();
    await schoolAboutUsController.getSchoolByIdController();
  }
}
