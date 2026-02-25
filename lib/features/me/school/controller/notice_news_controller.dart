import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/notice_news_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/upload_init_response.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:get/get.dart';

class NoticeController extends GetxController {
  Rx<ApiResponse> getNoticeNewsResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addNoticeNewsResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deleteNoticeNewsResponse = ApiResponse.initial('Initial').obs;
  RxString notice_news_titleText = ''.obs;
  RxString notice_news_messageText = ''.obs;
  RxString notice_news_id = ''.obs;
  final isFormValid = false.obs;
  final Rxn<File> noticeImageFile = Rxn<File>();

  String initialTitleText = "";
  String initialDescriptionText = "";
  String initialNoticeImageUrl = "";

  ///GET BRANCH CONTACT DETAILS...
  RxList<NoticeNewsData> noticeNewsDataList = <NoticeNewsData>[].obs;

  Future<void> getSchoolNoticeNewsController() async {
    noticeNewsDataList.clear();
    try {
      ResponseModel response = await SchoolRepo().getSchoolNoticesRepo();
      NoticeNewsModel noticeNewsModel =
          NoticeNewsModel.fromJson(response.response?.data);
      noticeNewsDataList.value = noticeNewsModel.data ?? [];
      if (response.isSuccess) {
        getNoticeNewsResponse.value = ApiResponse.complete(noticeNewsModel);
      } else {
        // commonSnackBar(message: AppStrings.somethingWentWrong);
        getNoticeNewsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      getNoticeNewsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///CREATE NEWS / NOTICE....

  UploadInitResponse uploadInit = UploadInitResponse();
  final isUploading = false.obs;

  Future<void> uploadNewsDocDocInit({bool? isEdit = false}) async {
    if (noticeImageFile.value == null) {
      commonSnackBar(message: AppStrings.noImageSelected);
      return;
    }
    try {
      isUploading.value = true;
      final imageFile = File(noticeImageFile.value?.path ?? "");
      final vInfo = getFileInfo(imageFile);
      Map<String, dynamic> queryParams = {
        ApiKeys.fileName: vInfo['fileName'],
        ApiKeys.fileType: vInfo['mimeType']
      };

      ResponseModel? response =
          await SchoolRepo().uploadEducationDocRepo(queryParams: queryParams);

      if (response?.isSuccess ?? false) {
        uploadInit = UploadInitResponse.fromJson(response?.response?.data);
        await uploadFileToS3(
          file: imageFile,
          fileType: vInfo['mimeType']!,
          preSignedUrl: uploadInit.uploadUrl ?? "",
          apiCallFrom: (isEdit ?? false) ? "EDIT" : "ADD",
        );
      } else {
        isUploading.value = false;

        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isUploading.value = false;

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
        ///call api
        if (apiCallFrom == "ADD") {
          addSchoolNoticeNewsController();
        } else if (apiCallFrom == "EDIT") {
          updateSchoolNoticeNewsController(isPhotoUpdate: true);
        }
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isUploading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> addSchoolNoticeNewsController() async {
    try {
      final reqDATA = {
        ApiKeys.schoolId: schoolIDGlobal,
        ApiKeys.uploadPhoto: uploadInit.publicUrl,
        ApiKeys.title: notice_news_titleText.value,
        ApiKeys.description: notice_news_messageText.value,
      };
      ResponseModel response =
          await SchoolRepo().addSchoolNoticesRepo(reqBODY: reqDATA);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        addNoticeNewsResponse.value =
            ApiResponse.complete(response.response?.data);
        getSchoolNoticeNewsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        addNoticeNewsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      addNoticeNewsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> updateSchoolNoticeNewsController(
      {bool isPhotoUpdate = false}) async {
    try {
      final reqDATA = {
        if (isPhotoUpdate) ApiKeys.uploadPhoto: uploadInit.publicUrl,
        ApiKeys.title: notice_news_titleText.value,
        ApiKeys.description: notice_news_messageText.value,
      };
      ResponseModel response = await SchoolRepo()
          .editSchoolNoticesRepo(reqBODY: reqDATA, noticeID: notice_news_id.value);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        addNoticeNewsResponse.value =
            ApiResponse.complete(response.response?.data);
        getSchoolNoticeNewsController();
        notice_news_id.value="";

      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        addNoticeNewsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      addNoticeNewsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///DELETE NOTICE....
  Future<void> deleteSchoolNoticeNewsController(
      {required String noticeId}) async {
    try {
      ResponseModel response =
          await SchoolRepo().deleteSchoolNoticesRepo(noticeID: noticeId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        deleteNoticeNewsResponse.value =
            ApiResponse.complete(response.response?.data);
        getSchoolNoticeNewsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        deleteNoticeNewsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      deleteNoticeNewsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
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
    bool isDescChanged = notice_news_messageText.value != originalDescription.value;

    // Checking if image changed (either new file picked or initial image removed)
    bool isImageChanged = noticeImageFile.value != null ||
        initialNoticeImageUrl != originalImageUrl.value;

    return isTitleChanged || isDescChanged || isImageChanged;
  }
}
