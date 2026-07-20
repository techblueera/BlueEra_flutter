import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_course_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class CourseController extends GetxController {
  var coursesList = <SchoolCourseData>[].obs;
  var isLoading = false.obs;
  var isMoreLoading = false.obs;
  int currentPage = 1;
  bool hasNext = false;

  @override
  void onInit() {
    fetchCourses();
    super.onInit();
  }

  Future<void> fetchCourses({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      isLoading.value = true;
    } else {
      isMoreLoading.value = true;
    }

    try {
      ResponseModel response = await SchoolRepo().getSchoolCourseRepo(reqBODY: {
        "schoolId": schoolIDGlobal,
        "page": currentPage,
        "limit": "10",
      });

      if (isRefresh) coursesList.clear();
      if (response.isSuccess) {
        var data = SchoolCourseResModel.fromJson(response.response?.data);
        if (isRefresh) {
          coursesList.assignAll(data.data ?? []);
        } else {
          coursesList.addAll(data.data ?? []);
        }
        hasNext = data.pagination?.hasNext ?? false;
      }
    } finally {
      isLoading.value = false;
      isMoreLoading.value = false;
    }
  }

  void loadMore() {
    if (hasNext && !isMoreLoading.value) {
      currentPage++;
      fetchCourses();
    }
  }

  Future<void> deleteCourse(String id) async {}

  ///DELETE NOTICE....
  Future<void> deleteSchoolDepartmentController(
      {required String courseID}) async {
    try {
      // Call delete API
      coursesList.removeWhere((element) => element.id == courseID);
      Get.back(); // Close dialog
      commonSnackBar(message: "Course deleted successfully");
      ResponseModel response =
          await SchoolRepo().deleteSchoolCourseRepo(courseId: courseID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        await fetchCourses(isRefresh: true);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  // Observables
  var courseDescriptionText = "".obs;
  var feeType = "Yearly".obs; // Default to Yearly
  var isFormValid = false.obs;
  var isUploading = false.obs;

  // Image upload state
  final Rxn<File> courseImageFile = Rxn<File>();
  final RxString courseImageUrl = ''.obs;
  final RxBool isImageUpdated = false.obs;

  // Change Detection Snapshots
  Map<String, dynamic> originalCourseData = {};

  void setFeeType(String? value) {
    if (value != null) {
      feeType.value = value;
      // Trigger validation whenever fee type changes
      // _runValidationTrigger();
    }
  }

  // Validation Logic
  void courseValidateForm({
    required String courseName,
    required String courseDuration,
    required String courseFee,
    required String eligibility,
    required String admissionProcess,
    required String description,
    bool isEdit = false,
  }) {
    bool basicValid = courseName.isNotEmpty &&
        courseDuration.isNotEmpty &&
        courseFee.isNotEmpty &&
        eligibility.isNotEmpty &&
        admissionProcess.isNotEmpty &&
        description.isNotEmpty &&
        courseImageUrl.value.isNotEmpty;

    if (!isEdit) {
      isFormValid.value = basicValid;
    } else {
      // Edit Mode: Must be valid AND different from original
      bool hasChanged = courseName != originalCourseData['name'] ||
          courseDuration != originalCourseData['duration'] ||
          courseFee != originalCourseData['feeValue'] ||
          feeType.value != originalCourseData['feeType'] ||
          eligibility != originalCourseData['eligibility'] ||
          admissionProcess != originalCourseData['admissionProcess'] ||
          description != originalCourseData['description'];

      isFormValid.value = basicValid && hasChanged;
    }
  }

  // API Call Logic
  Future<void> submitCourse({
    required String name,
    required String admission,
    required String eligibility,
    required String feeValue,
    required String duration,
    bool isEdit = false,
    String? courseId,
  }) async {
    try {
      isUploading.value = true;

      // 1. Convert the fee string to an integer
      int feeAsInt =
          int.tryParse(feeValue.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      // 2. Structure the courseFees object as per API requirements
      Map<String, dynamic> fees = {
        "monthly": feeType.value == "Monthly" ? feeAsInt : 0,
        "yearly": feeType.value == "Yearly" ? feeAsInt : 0,
      };

      // 3. If the image was updated, upload the local file to S3 first.
      String imageUrl = courseImageUrl.value;
      if (isImageUpdated.value && courseImageFile.value != null) {
        final result =
            await S3UploadService.uploadFile(courseImageFile.value!);
        if (!result.isSuccess) {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          return;
        }
        imageUrl = result.url;
        courseImageUrl.value = imageUrl;
      }

      Map<String, dynamic> reqParm = {
        "name": name,
        "admissionProcess": admission,
        "eligibility": eligibility,
        "courseFees": fees,
        "duration": duration,
        "description": courseDescriptionText.value,
        "image": imageUrl,
        if (isEdit == false) "schoolId": schoolIDGlobal
      };
      ResponseModel response = isEdit
          ? await SchoolRepo().updateSchoolCourseRepo(
              courseId: courseId ?? "", reqBODY: reqParm)
          : await SchoolRepo().addSchoolCourseRepo(reqBODY: reqParm);
      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        await fetchCourses(isRefresh: true);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("Error submitting course: $e");
    } finally {
      isUploading.value = false;
    }
  }
}
