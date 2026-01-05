import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/student_corner_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:get/get.dart';

class StudentCornerController extends GetxController {
  Rx<ApiResponse> getStudentCornerResponse = ApiResponse.initial('Initial').obs;
  var studentCornerId = "".obs; // Store the _id here
// Use RxList for automatic UI updates
  var timeTableList = <StudentCornerItem>[].obs;
  var syllabusList = <StudentCornerItem>[].obs;
  var examScheduleList = <StudentCornerItem>[].obs;
  var resultsList = <StudentCornerItem>[].obs;
  var downloadsList = <StudentCornerItem>[].obs;

  RxString notice_news_titleText = ''.obs;
  RxString notice_news_messageText = ''.obs;
  String initialTitleText = "";
  String initialDescriptionText = "";
  String initialNoticeImageUrl = "";

  // Inside NoticeController
  var originalTitle = "".obs;
  var originalDescription = "".obs;
  var originalImageUrl = "".obs;
  final isFormValid = false.obs;
  final Rxn<File> noticeImageFile = Rxn<File>();
  RxString docUploadName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initStudentCorner();
  }

  clearList() {
    timeTableList.clear();
    syllabusList.clear();
    examScheduleList.clear();
    resultsList.clear();
    downloadsList.clear();
  }

  Future<void> initStudentCorner() async {
    try {
      // 1. Try to Fetch existing section
      ResponseModel getResponse = await SchoolRepo().getStudentCornerRepo();
      clearList();
      StudentCornerResModel studentCornerResModel =
          StudentCornerResModel.fromJson(getResponse.response?.data);
      if (studentCornerResModel.data != null &&
          studentCornerResModel.success == true) {
        // Success: Store existing ID
        studentCornerId.value = studentCornerResModel.data?.id ?? "";
        // assignAll notifies the UI immediately
        timeTableList.assignAll(studentCornerResModel.data?.timeTable ?? []);
        syllabusList.assignAll(studentCornerResModel.data?.syllabus ?? []);
        examScheduleList
            .assignAll(studentCornerResModel.data?.examSchedule ?? []);
        resultsList.assignAll(studentCornerResModel.data?.results ?? []);
        downloadsList.assignAll(studentCornerResModel.data?.downloads ?? []);
        getStudentCornerResponse.value =
            ApiResponse.complete(studentCornerResModel);
        print("Existing ID found: ${studentCornerId.value}");
      } else {
        // 2. Success is false: Hit the POST API to create it
        print("Section not found. Creating new section...");
        await _createNewSection();
      }
    } catch (e) {
      getStudentCornerResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> _createNewSection() async {
    ResponseModel postResponse = await SchoolRepo().createStudentCornerRepo();

    if (postResponse.response?.data != null &&
        postResponse.response?.data['success'] == true) {
      studentCornerId.value = postResponse.response?.data['data']['_id'];
      print("New ID created and stored: ${studentCornerId.value}");
    } else {
      Get.snackbar("Failed", "Could not create student corner section");
    }
  }

  Future<void> createStudentCornerController(
      {required String studentCornerId,
      required Map<String, dynamic> reqParm}) async {
    ResponseModel postResponse = await SchoolRepo()
        .postStudentCornerRepo(studentCornerId: '', reqParm: {});

    if (postResponse.response?.data != null &&
        postResponse.response?.data['success'] == true) {
    } else {
      Get.snackbar("Failed", "Could not create student corner section");
    }
  }

  ///DELETE NOTICE....
  Future<void> deleteSchoolCornerItemController(
      {
      required String studentCornerTYPE,
      required int cornerINDEX}) async {
    try {
      ResponseModel response = await SchoolRepo().deleteStudentCornerRepo(
          cornerIndex: cornerINDEX,
          studentCornerId:   studentCornerId.value ,
          studentCornerType: studentCornerTYPE);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);

        initStudentCorner();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

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

  ///Only Branch Validation
  void noticesNewsValidateForm({
    required String uploadPhoto,
    required String noticeDescription,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = noticeDescription.isNotEmpty && uploadPhoto.isNotEmpty;
  }
}
