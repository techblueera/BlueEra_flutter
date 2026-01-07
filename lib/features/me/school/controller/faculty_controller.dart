import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/get_faculty_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';

class FacultyController extends GetxController {
  var isFormValid = false.obs;
  var qualifications = <String>[].obs;
  var facultyProfile = "".obs; // Holds URL or File Path
  var facultyProfileImageFile = Rxn<File>();
  var faculty_short_bio_text = "".obs;
  var isLoading = false.obs;

  // Validation Logic
  void validateFacultyForm({
    required String name,
    required String email,
    required String phone,
    required String posController,
    required String profile,
    // Add original data here to compare if "Modified"
    FacultyData? originalData,
  }) {
    bool basicValid = name.isNotEmpty &&
        email.contains("@") &&
        phone.length >= 10 &&
        posController.isNotEmpty &&
        profile.isNotEmpty;

    // Logic: Enable if valid AND (if edit mode, check if data changed)
    isFormValid.value = basicValid;
  }

  void addQualification(String val) {
    if (!qualifications.contains(val)) {
      qualifications.add(val);
    }
  }

  // // Loading & Validation State
  // var isLoading = false.obs;
  // var isFormValid = false.obs;

  // Dynamic Lists for the Form
  // var qualifications = <String>[].obs;
  var researchInterests = <String>[].obs;
  var publications = <Map<String, dynamic>>[].obs;

  // RxString faculty_short_bio_text = ''.obs;
  //
  // final Rxn<File> facultyProfileImageFile = Rxn<File>();
  // RxString facultyProfile = ''.obs;
  final isImageUpdated = false.obs;
  String initialFacultyProfileImageUrl = "";

  var profiles = <FacultyData>[].obs;
  var currentPage = 1;
  var hasNext = false.obs;

  @override
  void onInit() {
    fetchProfiles();
    super.onInit();
  }

  Rx<ApiResponse> getAllFacultyResponse = ApiResponse.initial('Initial').obs;

  Future<void> fetchProfiles({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      profiles.clear();
    }

    isLoading(true);
    try {
      // Replace with your actual API URL
      ResponseModel response = await SchoolRepo().getAllFacultyRepo(
        reqParm: {
          ApiKeys.schoolId: schoolIDGlobal,
          ApiKeys.page: currentPage,
          ApiKeys.limit: 20,
        },
      );
      GetFacultyResModel getFacultyResModel =
          GetFacultyResModel.fromJson(response.response?.data);
      if (response.isSuccess) {
        getAllFacultyResponse.value = ApiResponse.complete(getFacultyResModel);
        profiles.value = getFacultyResModel.data ?? [];

        hasNext.value = getFacultyResModel.pagination?.hasNext ?? false;
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getAllFacultyResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getAllFacultyResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
      commonSnackBar(message: e.toString());
    } finally {
      isLoading(false);
    }
  }

  ///DELETE NOTICE....
  Future<void> deleteFacultyProfileController({
    required String facultyID,
  }) async {
    try {
      ResponseModel response =
          await SchoolRepo().deleteFacultyRepo(facultyId: facultyID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        profiles.clear();

        await fetchProfiles(isRefresh: true);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  void addInterest(String val) => researchInterests.add(val);

  void removeQualification(int index) => qualifications.removeAt(index);

  Future<void> submitFacultyData({
    required String name,
    required String position,
    required String bio,
    required String email,
    required String phone,
    required int expYears,
    required String expDetails,
    bool isEdit = false,
    bool isImageEdit = true,
    String? docId,
  }) async {
    try {
      isLoading.value = true;
      UploadResult? result;
      if (isImageEdit) {
        result = await S3UploadService.uploadFile(
            File(facultyProfileImageFile.value?.path ?? ""));
      }

      // Constructing the nested JSON payload
      Map<String, dynamic> body = {
        "school": schoolIDGlobal,
        "name": name,
        "position": position,
        "qualifications": qualifications.toList(),
        "experience": {"years": expYears, "details": expDetails},
        "email": email,
        "phone": phone,
        if (isImageUpdated.value) "photo": result?.url,
        "bio": bio,

      };

      if (isEdit) {
        if (result?.isSuccess??false) {
          ResponseModel response = await SchoolRepo().editFacultyRepo(
            reqParm: body,
            facultyId: docId ?? "",
          );

          if (response.isSuccess) {
            Get.back();
            commonSnackBar(
                message: response.response?.data['message'] ??
                    AppStrings.successful);
            profiles.clear();

            await fetchProfiles(isRefresh: true);
          } else {
            commonSnackBar(message: AppStrings.somethingWentWrong);
          }
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      } else {
        if (result?.isSuccess??false) {
          ResponseModel response = await SchoolRepo().addFacultyRepo(
            reqParm: body,
          );

          if (response.isSuccess) {
            Get.back();
            commonSnackBar(
                message: response.response?.data['message'] ??
                    AppStrings.successful);
            profiles.clear();

            await fetchProfiles(isRefresh: true);
          } else {
            commonSnackBar(message: AppStrings.somethingWentWrong);
          }
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      }

      // Return after success
    } catch (e) {
      commonSnackBar(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
