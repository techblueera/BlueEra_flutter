import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_about_us_model.dart';
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/api/model/school_quick_info_field.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
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
  // Principal / director's display name — sent as `principalMessage.name`
  // on the About-Us update. Managed alongside the message text so both
  // fields can be edited from the same screen.
  RxString directorName = ''.obs;
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

  // Dropdown suggestions served by GET /schools/options — cached in memory
  // for the lifetime of the controller.
  final RxList<String> boardOptions = <String>[].obs;
  final RxList<String> mediumOptions = <String>[].obs;
  final isSchoolOptionsLoading = false.obs;

  // Polymorphic Quick Info state — populated by GET /schools/:id/quick-info.
  // `quickInfoFields` and `quickInfoCategory` drive which inputs render;
  // `quickInfoValues` is the raw saved payload keyed by field.key (so it can
  // hold `boards: [...]`, `coursesOffered: [...]`, `numberOfStudents: 900`
  // etc. without a per-category typed model).
  // See lib/docs/SCHOOL_QUICK_INFO_UI_INTEGRATION.md.
  final RxList<QuickInfoField> quickInfoFields = <QuickInfoField>[].obs;
  final Rxn<String> quickInfoCategory = Rxn<String>();
  final RxMap<String, dynamic> quickInfoValues = <String, dynamic>{}.obs;

  // Initial values (to check if data changed)
  String initialDirectText = "";
  String initialDirectImageUrl = "";
  String initialDirectName = "";

  String initialManagementProfileImageUrl = "";

  String initialHistoryText = "";
  String initialHistoryImageUrl = "";
  RxString managementProfile = ''.obs;

  final isImageUpdated = false.obs;

  ///GET ABOUT US......
  Rx<AboutUsData>? aboutUsData = AboutUsData().obs;
  Rx<SchoolDetailsData>? schoolDetailsData = SchoolDetailsData().obs;

  void _triggerSubFetches(String? schoolID, {bool skipQuickInfoFetch = false}) {
    if (schoolID == null || schoolID.isEmpty) return;

    // Fetch sub-details using the specific school's ID
    getSchoolAboutUsController(schoolID: schoolID);
    getSchoolBranchController(schoolID: schoolID);
    getSchoolCoursesController(schoolID: schoolID);
    getSchoolCampusLifeController(schoolID: schoolID);
    // Discover reads quick-info from the main /schools/:id response
    // (see DiscoverSchoolQuickInfoCard) and doesn't need the dedicated
    // /schools/:id/quick-info round-trip. Owner "me" screens leave the
    // flag off so their form/summary keeps using the authoritative
    // endpoint.
    if (!skipQuickInfoFetch) {
      fetchSchoolQuickInfo(schoolID: schoolID);
    }
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
      {String? schoolID,
      String? ownerID,
      bool skipQuickInfoFetch = false}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      isDetailLoading.value = true;
      ResponseModel response =
          await SchoolRepo().getSchoolByIDRepo(schoolID: schoolID);

      if (response.isSuccess) {
        SchoolDetailsResModel schoolAboutUsModel =
            SchoolDetailsResModel.fromJson(response.response?.data);

        // Accept the direct fetch only when it resolved a real school (has an
        // id). The by-id endpoint can answer success with a null OR an empty
        // data object when the supplied id is actually a Business/Owner ID
        // (e.g. from a deep link) that doesn't exist in the Education service —
        // in that case fall through to the ownerID fallback below instead of
        // binding the UI to an empty school.
        if (schoolAboutUsModel.data?.id != null) {
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
          _triggerSubFetches(newData.id,
              skipQuickInfoFetch: skipQuickInfoFetch);
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

          if (schoolAboutUsModel.data?.id != null) {
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
            _triggerSubFetches(newData.id,
                skipQuickInfoFetch: skipQuickInfoFetch);
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
                ApiKeys.name: directorName.value,
                ApiKeys.message: directorMessageText.value,
              },
              "schoolId": schoolIDGlobal
            });
      } else {
        response = await SchoolRepo().updateSchoolAboutUsRepo(
            aboutUsID: aboutUsData?.value.id ?? "",
            reqBODY: {
              "principalMessage": {
                ApiKeys.name: directorName.value,
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

  ///FETCH SCHOOL DROPDOWN OPTIONS (boards & mediums of instruction)....
  ///
  ///Backed by `GET /schools/options`. Cached in memory — subsequent calls
  ///return immediately unless [forceRefresh] is passed.
  Future<void> fetchSchoolOptions({bool forceRefresh = false}) async {
    if (!forceRefresh && boardOptions.isNotEmpty && mediumOptions.isNotEmpty) {
      return;
    }
    try {
      isSchoolOptionsLoading.value = true;
      final res = await SchoolRepo().getSchoolOptionsRepo();
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        final boards = data?['boards'];
        final mediums = data?['mediumsOfInstruction'];
        if (boards is List) {
          boardOptions.assignAll(boards.map((e) => e.toString()));
        }
        if (mediums is List) {
          mediumOptions.assignAll(mediums.map((e) => e.toString()));
        }
      }
    } catch (e) {
      logs("ERROR fetchSchoolOptions: $e");
    } finally {
      isSchoolOptionsLoading.value = false;
    }
  }

  // In-memory cache for `GET /schools/options?category=<X>`. The response
  // is static reference data so we hold it for the controller's lifetime.
  final Map<String, List<QuickInfoField>> _fieldsByCategoryCache = {};

  /// Fetch the ordered descriptor list for a category from
  /// `GET /schools/options?category=<X>` (doc §4). Cached per-category
  /// on first call. Returns `null` when the endpoint fails or the
  /// response shape is unexpected; caller falls back to whatever the
  /// per-listing endpoint returned.
  Future<List<QuickInfoField>?> _fetchFieldsForCategory(String category) async {
    final cached = _fieldsByCategoryCache[category];
    if (cached != null) {
      logs("_fetchFieldsForCategory: cache hit for '$category' "
          "(${cached.length} fields)");
      return cached;
    }
    try {
      logs("_fetchFieldsForCategory: GET /schools/options?category='$category'");
      final res =
          await SchoolRepo().getSchoolOptionsByCategoryRepo(category: category);
      if (!res.isSuccess) {
        logs("_fetchFieldsForCategory: HTTP failed for '$category'");
        return null;
      }
      final data = res.response?.data['data'];
      final fieldsRaw = data is Map ? data['fields'] : null;
      if (fieldsRaw is! List) {
        logs("_fetchFieldsForCategory: '$category' returned no `data.fields`"
            " list; body=${res.response?.data}");
        return null;
      }
      final list = fieldsRaw
          .map((e) => QuickInfoField.fromJson(e))
          .where((f) => f.key.isNotEmpty)
          .toList(growable: false);
      _fieldsByCategoryCache[category] = list;
      logs("_fetchFieldsForCategory: '$category' → ${list.length} fields "
          "${list.map((f) => f.key).toList()}");
      return list;
    } catch (e) {
      logs("ERROR _fetchFieldsForCategory('$category'): $e");
      return null;
    }
  }

  /// Read the listing's category from the permanently-registered business
  /// profile controller. Business categories are nested three levels deep
  /// (type_of_business → category_details → sub_category_details) and only
  /// **one** of those three levels lines up with the six categories in the
  /// education-service doc — which one varies per listing. `Convent
  /// School`, for example, sits in `sub_category_details.name` but the
  /// education service expects `School Education` (its parent).
  ///
  /// So instead of picking a fixed level, we walk all three candidates
  /// from most-specific to least and return the first one that resolves
  /// to a known whitelist key. If none resolve, we still return the most
  /// specific non-empty value so the backend gets *something* to match
  /// against tolerantly (doc §4).
  String? _businessCategoryFallback() {
    if (!Get.isRegistered<ViewBusinessDetailsController>()) return null;
    final data = Get.find<ViewBusinessDetailsController>()
        .businessProfileDetails
        .value
        ?.data;
    if (data == null) return null;

    final candidates = <String>[
      if ((data.subCategoryDetails?.name ?? '').trim().isNotEmpty)
        data.subCategoryDetails!.name!.trim(),
      if ((data.categoryDetails?.name ?? '').trim().isNotEmpty)
        data.categoryDetails!.name!.trim(),
      if ((data.typeOfBusiness ?? '').trim().isNotEmpty)
        data.typeOfBusiness!.trim(),
    ];

    // Prefer the first candidate that resolves to one of the doc's six
    // canonical categories — that's the one the education-service will
    // actually recognise.
    for (final c in candidates) {
      if (resolveQuickInfoCategoryKey(c) != null) return c;
    }
    // Nothing resolves — fall back to the most-specific value so at least
    // we're sending real data the backend can attempt to match.
    return candidates.isEmpty ? null : candidates.first;
  }

  ///GET SCHOOL QUICK INFO....
  ///
  ///Response carries three things: `data` (the saved values, polymorphic by
  ///category), `category` (the listing's category string), and `fields` (an
  ///ordered list of [QuickInfoField] descriptors telling us what to render).
  ///The typed mirrors on [schoolDetailsData] are still populated for anywhere
  ///reading `.boards` / `.mediumOfInstruction` / `.numberOfStudents` etc. —
  ///new UI should read [quickInfoValues] instead.
  Future<void> fetchSchoolQuickInfo({String? schoolID}) async {
    try {
      isQuickInfoLoading.value = true;
      final res = await SchoolRepo().getSchoolQuickInfoRepo(schoolID: schoolID);
      if (res.isSuccess) {
        final body = res.response?.data;
        final data = body?['data'];
        final category = body?['category']?.toString();
        final fieldsRaw = body?['fields'];

        // Category source order: the per-listing API's own `category`
        // field first, then the business profile's own category tree.
        // Both sources can carry a value the education-service can't
        // recognise (e.g. `"Convent School"` — a school sub-type that's
        // not one of the doc's six categories), so we prefer whichever
        // candidate actually resolves against the whitelist before
        // falling back to raw strings.
        final apiCategory =
            (category != null && category.isNotEmpty) ? category : null;
        final businessCategory = _businessCategoryFallback();
        final candidates = <String>[
          if (apiCategory != null) apiCategory,
          if (businessCategory != null) businessCategory,
        ];
        String? effectiveCategory;
        for (final c in candidates) {
          if (resolveQuickInfoCategoryKey(c) != null) {
            effectiveCategory = c;
            break;
          }
        }
        // Nothing resolved — keep whatever the sources gave us so the
        // backend can attempt its own tolerant match.
        effectiveCategory ??= candidates.isEmpty ? null : candidates.first;
        quickInfoCategory.value = effectiveCategory;

        // Field descriptors: prefer the dedicated per-category options
        // endpoint (`GET /schools/options?category=<X>`, doc §4) because
        // it always returns the *correct* field set for the category.
        // The `fields` array embedded in this response is a nice-to-have
        // but is documented (doc §6) to return **every** field when the
        // listing has no category — that's the "extra Sports/Professional
        // fields on a School" bug we keep hitting.
        //
        // We always attempt the options endpoint whenever we have *any*
        // category string, even one we don't recognise locally, because
        // the backend does tolerant matching on its side (doc §4: casing,
        // spacing and punctuation ignored + short aliases). If it comes
        // back with a smaller field set than the per-listing response,
        // we prefer it; otherwise we fall back to the whitelist filter.
        final resolvedKey = resolveQuickInfoCategoryKey(effectiveCategory);
        List<QuickInfoField>? categoryFields;
        if (effectiveCategory != null && effectiveCategory.isNotEmpty) {
          // Prefer the canonical whitelist key when we have one (avoids
          // pinging the endpoint with slight variations like "college"
          // and getting a cache miss each time); fall back to the raw
          // category otherwise.
          final query = resolvedKey ?? effectiveCategory;
          categoryFields = await _fetchFieldsForCategory(query);
        }

        if (categoryFields != null && categoryFields.isNotEmpty) {
          // Options endpoint answered — use its descriptors as-is. If we
          // also have a whitelist for this category, re-filter to guard
          // against a future backend regression that returns extras.
          if (resolvedKey != null) {
            final allowed = kQuickInfoFieldsByCategory[resolvedKey]!;
            final byKey = {for (final f in categoryFields) f.key: f};
            final ordered = <QuickInfoField>[
              for (final key in allowed)
                if (byKey.containsKey(key)) byKey[key]!,
            ];
            // If the whitelist filter yielded nothing (backend/whitelist
            // disagreement) keep the backend's list rather than emptying
            // the form.
            quickInfoFields.assignAll(
                ordered.isNotEmpty ? ordered : categoryFields);
          } else {
            quickInfoFields.assignAll(categoryFields);
          }
        } else {
          // Fallback 1: use whatever the per-listing endpoint sent…
          final parsed = fieldsRaw is List
              ? fieldsRaw
                  .map((e) => QuickInfoField.fromJson(e))
                  .where((f) => f.key.isNotEmpty)
                  .toList()
              : <QuickInfoField>[];
          // Fallback 2: filter that by the hardcoded whitelist so a
          // known-category listing never renders another category's
          // inputs even if both API paths misbehaved.
          if (resolvedKey != null) {
            final allowed = kQuickInfoFieldsByCategory[resolvedKey]!;
            final byKey = {for (final f in parsed) f.key: f};
            quickInfoFields.assignAll([
              for (final key in allowed)
                if (byKey.containsKey(key)) byKey[key]!,
            ]);
          } else {
            quickInfoFields.assignAll(parsed);
          }
        }

        logs("QuickInfo fields resolved: category='$effectiveCategory' "
            "resolvedKey='$resolvedKey' "
            "fromOptionsEndpoint=${categoryFields != null} "
            "count=${quickInfoFields.length} "
            "keys=${quickInfoFields.map((f) => f.key).toList()}");

        if (data is Map) {
          quickInfoValues.assignAll(Map<String, dynamic>.from(data));
        } else {
          quickInfoValues.clear();
        }

        // Legacy typed mirrors — kept for compatibility with existing readers
        // on [schoolDetailsData]. Safe to drop once every consumer has moved
        // to [quickInfoValues].
        if (data is Map && schoolDetailsData?.value != null) {
          schoolDetailsData!.value.classRange = data['classRange']?.toString();
          final boardVal = data['board'];
          schoolDetailsData!.value.boards = boardVal is List
              ? boardVal.map((e) => e.toString()).toList()
              : (boardVal is String && boardVal.isNotEmpty
                  ? [boardVal]
                  : <String>[]);
          final medium = data['mediumOfInstruction'];
          schoolDetailsData!.value.mediumOfInstruction = medium is List
              ? medium.map((e) => e.toString()).toList()
              : (medium is String && medium.isNotEmpty ? [medium] : <String>[]);
          schoolDetailsData!.value.fees =
              data['fees'] is num ? (data['fees'] as num).toInt() : null;
          schoolDetailsData!.value.numberOfStudents =
              data['numberOfStudents'] is num
                  ? (data['numberOfStudents'] as num).toInt()
                  : null;
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
  ///
  ///Dynamic partial save — send whichever field.key/value pairs the form
  ///produced. Backend merges onto stored `quickInfo` (see doc §7).
  Future<bool> updateSchoolQuickInfoValues(Map<String, dynamic> values) async {
    try {
      isQuickInfoSaving.value = true;
      final res = await SchoolRepo().updateSchoolQuickInfoRepo(reqBODY: values);
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? AppStrings.successful);
        await fetchSchoolQuickInfo();
        return true;
      }
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } catch (e) {
      logs("ERROR updateSchoolQuickInfoValues: $e");
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
            message: res.response?.data['message'] ?? AppStrings.successful);
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
