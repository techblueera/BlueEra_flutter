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
import 'package:BlueEra/core/constants/regular_expression.dart';

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
  final isDetailLoading = false.obs;

  final isQuickInfoLoading = false.obs;
  final isQuickInfoSaving = false.obs;
  final isTimingsLoading = false.obs;
  final isTimingsSaving = false.obs;

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

  void _triggerSubFetches(String? schoolID) {
    if (schoolID == null || schoolID.isEmpty) return;

    // Fetch sub-details using the specific school's ID
    getSchoolAboutUsController(schoolID: schoolID);
    getSchoolBranchController(schoolID: schoolID);
    getSchoolCoursesController(schoolID: schoolID);
    getSchoolCampusLifeController(schoolID: schoolID);
    fetchSchoolQuickInfo(schoolID: schoolID);
    fetchSchoolTimings(schoolID: schoolID);

    schoolDetailsData?.refresh();
  }

  Future<void> getSchoolAboutUsController({String? schoolID}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo()
          .getSchoolAboutUsRepo(schoolID: schoolID ?? schoolIDGlobal);
      SchoolAboutUsModel schoolAboutUsModel =
          SchoolAboutUsModel.fromJson(response.response?.data);
      aboutUsData?.value = schoolAboutUsModel.data ?? AboutUsData();
      if (response.isSuccess) {
        getAboutUsSchoolResponse.value =
            ApiResponse.complete(schoolAboutUsModel);
        // Sync to schoolDetailsData for UI consistency
        if (schoolDetailsData?.value != null && aboutUsData?.value != null) {
          schoolDetailsData!.value.aboutId =
              AboutId.fromJson(aboutUsData!.value.toJson());
          schoolDetailsData?.refresh();
        }
      } else {
        if (response.response?.data['message'] ==
            "About section not found for this school") {
          // Handle new schools gracefully
          aboutUsData?.value = AboutUsData();
          getAboutUsSchoolResponse.value = ApiResponse.complete(
              SchoolAboutUsModel(data: aboutUsData?.value));
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          getAboutUsSchoolResponse.value =
              ApiResponse.error(AppStrings.somethingWentWrong);
        }
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

  Future<void> getSchoolByIdController(
      {String? schoolID, String? ownerID}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      isDetailLoading.value = true;
      ResponseModel response =
          await SchoolRepo().getSchoolByIDRepo(schoolID: schoolID);

      if (response.isSuccess) {
        SchoolDetailsResModel schoolAboutUsModel =
            SchoolDetailsResModel.fromJson(response.response?.data);

        // If the API returns success but data is null, it means the ID was likely
        // a Business ID that doesn't exist in the Education service.
        if (schoolAboutUsModel.data != null) {
          final oldData = schoolDetailsData?.value;
          final newData = schoolAboutUsModel.data!;

          logs("DEBUG: Direct Fetch Success for ID: $schoolID");

          // Defensive merge: Preserve existing data if new response is missing it
          if ((newData.name == null || newData.name!.isEmpty) &&
              oldData?.name != null) {
            newData.name = oldData?.name;
          }
          if ((newData.logo == null || newData.logo!.isEmpty) &&
              oldData?.logo != null) {
            newData.logo = oldData?.logo;
          }
          if (newData.establishmentYear == null &&
              oldData?.establishmentYear != null) {
            newData.establishmentYear = oldData?.establishmentYear;
          }

          schoolDetailsData?.value = newData;
          schoolDetailsData?.refresh();

          // Fetch sub-details using the confirmed ID
          _triggerSubFetches(newData.id);
          return; // Exit successfully
        }
      }

      // If we reach here, either the direct fetch failed or it returned null data.
      // We attempt the fallback using ownerID.
      if (ownerID != null) {
        logs("DEBUG: Attempting Fallback for OwnerID: $ownerID");
        ResponseModel fallbackResponse =
            await SchoolRepo().getSchoolByUserIDRepo(userID: ownerID);

        if (fallbackResponse.isSuccess) {
          SchoolDetailsResModel schoolAboutUsModel =
              SchoolDetailsResModel.fromJson(fallbackResponse.response?.data);

          if (schoolAboutUsModel.data != null) {
            final oldData = schoolDetailsData?.value;
            final newData = schoolAboutUsModel.data!;

            logs("DEBUG: Fallback Success. Correct School ID: ${newData.id}");

            // Defensive merge for fallback path
            if ((newData.name == null || newData.name!.isEmpty) &&
                oldData?.name != null) {
              newData.name = oldData?.name;
            }
            if ((newData.logo == null || newData.logo!.isEmpty) &&
                oldData?.logo != null) {
              newData.logo = oldData?.logo;
            }
            if (newData.establishmentYear == null &&
                oldData?.establishmentYear != null) {
              newData.establishmentYear = oldData?.establishmentYear;
            }

            schoolDetailsData?.value = newData;
            schoolDetailsData?.refresh();

            // Fetch sub-details using the CORRECTED School ID
            _triggerSubFetches(newData.id);
          }
        }
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      getAboutUsSchoolResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<void> getSchoolBranchController({String? schoolID}) async {
    try {
      ResponseModel response = await SchoolRepo()
          .getSchoolBranchRepo(schoolID: schoolID ?? schoolIDGlobal);
      if (response.isSuccess && schoolDetailsData?.value != null) {
        // Update contacts in schoolDetailsData
        final List<dynamic> contactsJson =
            response.response?.data['data'] ?? [];
        schoolDetailsData!.value.contacts =
            contactsJson.map((v) => Contacts.fromJson(v)).toList();
        schoolDetailsData?.refresh();
      }
    } catch (e) {
      logs("ERROR IN BRANCH FETCH: $e");
    }
  }

  Future<void> getSchoolCoursesController({String? schoolID}) async {
    try {
      ResponseModel response = await SchoolRepo()
          .getSchoolCoursesRepo(schoolID: schoolID ?? schoolIDGlobal);
      if (response.isSuccess && schoolDetailsData?.value != null) {
        // Update courses in schoolDetailsData
        final List<dynamic> coursesJson = response.response?.data['data'] ?? [];
        schoolDetailsData!.value.courses =
            coursesJson.map((v) => Courses.fromJson(v)).toList();
        schoolDetailsData?.refresh();
      }
    } catch (e) {
      logs("ERROR IN COURSES FETCH: $e");
    }
  }

  Future<void> getSchoolCampusLifeController({String? schoolID}) async {
    try {
      ResponseModel response = await SchoolRepo()
          .getAllCampusLifeRepo(schoolID: schoolID ?? schoolIDGlobal);
      if (response.isSuccess && schoolDetailsData?.value != null) {
        final List<dynamic> categoriesJson =
            response.response?.data['data'] ?? [];

        final List<String> extractedUrls = [];

        for (final category in categoriesJson) {
          final subcategories = (category['subcategories'] as List?) ?? [];
          for (final sub in subcategories) {
            final entries = (sub['entries'] as List?) ?? [];
            for (final entry in entries) {
              final images = (entry['images'] as List?) ?? [];
              for (final img in images) {
                final url = (img is String)
                    ? img
                    : (img['url'] ??
                            img['image'] ??
                            img['uploadPhoto'] ??
                            img['photo'] ??
                            '')
                        .toString()
                        .trim();
                if (url.isNotEmpty) extractedUrls.add(url);
              }
            }
          }
        }

        // Store flattened URLs in galleryPhotos so CampusPhotoGallery can display them
        schoolDetailsData!.value.galleryPhotos = [
          ...?schoolDetailsData!.value.galleryPhotos,
          ...extractedUrls,
        ];
        // Remove duplicates
        schoolDetailsData!.value.galleryPhotos =
            schoolDetailsData!.value.galleryPhotos?.toSet().toList();
        schoolDetailsData?.refresh();
      }
    } catch (e) {
      logs("ERROR IN CAMPUS LIFE FETCH: $e");
    }
  }

  Future<void> updateVisionMissionController(
      {required String visionMissionText}) async {
    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().updateSchoolAboutUsRepo(
          aboutUsID: aboutUsData?.value.id ?? "",
          reqBODY: {
            ApiKeys.visionAndMission: visionMissionText,
            "schoolId": schoolIDGlobal
          });

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
            },
            "schoolId": schoolIDGlobal
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
              },
              "schoolId": schoolIDGlobal
            });
      } else {
        response = await SchoolRepo().updateSchoolAboutUsRepo(
            aboutUsID: aboutUsData?.value.id ?? "",
            reqBODY: {
              "principalMessage": {
                ApiKeys.message: directorMessageText.value,
              },
              "schoolId": schoolIDGlobal
            });
      }

      if (response.isSuccess) {
        isDirectorImageUpdate.value = false;
        directorMessageImageFile.value = null;
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
    final nameErr = ValidationMethod.validateName(managementName);
    final posErr = ValidationMethod.validatePosition(profession);
    final descErr = ValidationMethod.validateDescription(message);

    bool qualificationsOk = qualification.isNotEmpty;
    for (var controller in qualification) {
      if (controller.text.trim().isEmpty) {
        qualificationsOk = false;
        break;
      }
    }

    isFormValid.value = nameErr == null &&
        posErr == null &&
        descErr == null &&
        qualificationsOk &&
        profileImg.isNotEmpty;
  }

  ///UPDATE VISION AND MISSION....
  ///Only Branch Validation
  void noticesNewsValidateForm({
    required String uploadPhoto,
    required String noticeDescription,
  }) {
    // Message should be required, photo is optional
    isFormValid.value = noticeDescription.isNotEmpty;
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

  ///GET SCHOOL QUICK INFO....
  Future<void> fetchSchoolQuickInfo({String? schoolID}) async {
    try {
      isQuickInfoLoading.value = true;
      final res =
          await SchoolRepo().getSchoolQuickInfoRepo(schoolID: schoolID);
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        if (data != null && schoolDetailsData?.value != null) {
          schoolDetailsData!.value.classRange = data['classRange'];
          schoolDetailsData!.value.studentTeacherRatio =
              data['studentTeacherRatio'];
          final medium = data['mediumOfInstruction'];
          schoolDetailsData!.value.mediumOfInstruction = medium is List
              ? medium.map((e) => e.toString()).toList()
              : (medium is String && medium.isNotEmpty
                  ? [medium]
                  : <String>[]);
          schoolDetailsData!.value.fees =
              data['fees'] is num ? (data['fees'] as num).toInt() : null;
          schoolDetailsData?.refresh();
        }
      }
    } catch (e) {
      logs("ERROR fetchSchoolQuickInfo: $e");
    } finally {
      isQuickInfoLoading.value = false;
    }
  }

  ///UPDATE SCHOOL QUICK INFO....
  Future<bool> updateSchoolQuickInfo({
    required String classRange,
    required String studentTeacherRatio,
    required List<String> mediumOfInstruction,
    required int fees,
  }) async {
    try {
      isQuickInfoSaving.value = true;
      final res = await SchoolRepo().updateSchoolQuickInfoRepo(reqBODY: {
        'classRange': classRange,
        'studentTeacherRatio': studentTeacherRatio,
        'mediumOfInstruction': mediumOfInstruction,
        'fees': fees,
      });
      if (res.isSuccess) {
        commonSnackBar(
            message:
                res.response?.data['message'] ?? AppStrings.successful);
        await fetchSchoolQuickInfo();
        return true;
      }
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      logs("ERROR updateSchoolQuickInfo: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isQuickInfoSaving.value = false;
    }
  }

  ///GET SCHOOL TIMINGS....
  Future<void> fetchSchoolTimings({String? schoolID}) async {
    try {
      isTimingsLoading.value = true;
      final res = await SchoolRepo().getSchoolTimingsRepo(schoolID: schoolID);
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        if (schoolDetailsData?.value != null) {
          schoolDetailsData!.value.availability =
              data.map((v) => Availability.fromJson(v)).toList();
          schoolDetailsData?.refresh();
        }
      }
    } catch (e) {
      logs("ERROR fetchSchoolTimings: $e");
    } finally {
      isTimingsLoading.value = false;
    }
  }

  ///UPDATE SCHOOL TIMINGS....
  Future<bool> updateSchoolTimings(List<Availability> slots) async {
    try {
      isTimingsSaving.value = true;
      final payload = slots.map((s) {
        final open = s.isOpen ?? false;
        return open
            ? {
                'day': s.day,
                'isOpen': true,
                'openTime': s.openTime,
                'closeTime': s.closeTime,
              }
            : {'day': s.day, 'isOpen': false};
      }).toList();
      final res = await SchoolRepo().updateSchoolTimingsRepo(reqBODY: {
        'schoolTimings': payload,
      });
      if (res.isSuccess) {
        commonSnackBar(
            message:
                res.response?.data['message'] ?? AppStrings.successful);
        await fetchSchoolTimings();
        return true;
      }
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      logs("ERROR updateSchoolTimings: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isTimingsSaving.value = false;
    }
  }
}
