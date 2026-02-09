import 'dart:io';
import 'package:BlueEra/core/api/model/academic_calender_res_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';

class AcademicCalenderController extends GetxController {
  Rx<ApiResponse> getAcademicCalenderResponse =
      ApiResponse.initial('Initial').obs;
  RxString notice_news_titleText = ''.obs;
  RxString notice_news_messageText = ''.obs;
  RxString notice_news_id = ''.obs;
  RxString docUploadName = ''.obs;
  final isFormValid = false.obs;
  final Rxn<File> noticeImageFile = Rxn<File>();

  String initialTitleText = "";
  String initialDescriptionText = "";
  String initialNoticeImageUrl = "";
  ///GET BRANCH CONTACT DETAILS...
  RxList<AcademicCalenderData> noticeNewsDataList =
      <AcademicCalenderData>[].obs;

  Future<void> getSchoolNoticeNewsController() async {
    noticeNewsDataList.clear();
    try {
      ResponseModel response =
          await SchoolRepo().getEducationServiceAcademicsRepo();
      AcademicCalenderResModel noticeNewsModel =
          AcademicCalenderResModel.fromJson(response.response?.data);
      noticeNewsDataList.value = noticeNewsModel.data ?? [];
      if (response.isSuccess) {
        getAcademicCalenderResponse.value =
            ApiResponse.complete(noticeNewsModel);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getAcademicCalenderResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      getAcademicCalenderResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///CREATE NEWS / NOTICE....

  Future<void> addAcademicCalenderController() async {
    try {
      UploadResult result = await S3UploadService.uploadFile(
          File(noticeImageFile.value?.path ?? ""));
      final reqDATA = {
        ApiKeys.schoolId: schoolIDGlobal,
        ApiKeys.fileUrl: result.url,
        ApiKeys.title: notice_news_titleText.value,
        ApiKeys.description: notice_news_messageText.value,
      };
      ResponseModel response =
          await SchoolRepo().addEducationServiceAcademicsRepo(reqBODY: reqDATA);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);

        getSchoolNoticeNewsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
    }
  }

  Future<void> updateAcademicCalenderController(
      {bool isPhotoUpdate = false}) async {
    try {
      UploadResult? result;
      if (isPhotoUpdate) {
        result = await S3UploadService.uploadFile(
            File(noticeImageFile.value?.path ?? ""));
      }

      final reqDATA = {
        if (isPhotoUpdate) ApiKeys.fileUrl: result?.url,
        ApiKeys.title: notice_news_titleText.value,
        ApiKeys.description: notice_news_messageText.value,
      };
      ResponseModel response = await SchoolRepo()
          .editEducationServiceAcademicsRepo(
              reqBODY: reqDATA, noticeID: notice_news_id.value);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);

        getSchoolNoticeNewsController();
        notice_news_id.value = "";
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
    }
  }

  ///DELETE NOTICE....
  Future<void> deleteSchoolNoticeNewsController(
      {required String noticeId}) async {
    try {
      ResponseModel response = await SchoolRepo()
          .deleteEducationServiceAcademicsRepo(noticeID: noticeId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);

        getSchoolNoticeNewsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  ///Only Branch Validation
  void noticesNewsValidateForm({
    required String uploadPhoto,
    required String noticeDescription,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = noticeDescription.isNotEmpty && uploadPhoto.isNotEmpty;
  }

  // Inside NoticeController
  var originalTitle = "".obs;
  var originalDescription = "".obs;
  var originalImageUrl = "".obs;

// Method to check if something changed
  bool hasChanges() {
    bool isTitleChanged = notice_news_titleText.value != originalTitle.value;
    bool isDescChanged =
        notice_news_messageText.value != originalDescription.value;

    // Checking if image changed (either new file picked or initial image removed)
    bool isImageChanged = noticeImageFile.value != null ||
        initialNoticeImageUrl != originalImageUrl.value;

    return isTitleChanged || isDescChanged || isImageChanged;
  }
}
