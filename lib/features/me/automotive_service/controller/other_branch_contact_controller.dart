import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/automotive_service/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:get/get.dart';

class AutomotiveBranchContactController extends GetxController {
  Rx<ApiResponse> updateSchoolContactInfoResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSchoolContactUsResponse =
      ApiResponse.initial('Initial').obs;

  // Loading state for the submit button
  var isLoading = false.obs;

  // Validation state
  var isFormValid = false.obs;

  // Values to store from location picker
  double? selectedLat;
  double? selectedLng;

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) {
    // Strict Name/Dept Validation: At least 3 chars, letters and spaces preferred
    final nameRegex = RegExp(r"^[a-zA-Z\s\.]{3,50}$");

    // Strict Gmail Validation: Must end with @gmail.com
    final gmailRegex = RegExp(r'^[\w-\.]+@gmail\.com$');

    bool isValid = nameRegex.hasMatch(branchName.trim()) &&
        (website.isEmpty || website.isURL) &&
        address.isNotEmpty &&
        nameRegex.hasMatch(department.trim()) &&
        gmailRegex.hasMatch(email.trim()) &&
        phone.length >= 10;

    isFormValid.value = isValid;
  }

  Future<void> submitBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(message: AppStrings.hotelSelectValidLocation.tr);
      return;
    }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "businessProfileId":
            otherServiceIDGlobal, // Replace with dynamic ID if needed
        "branch": {
          "name": branchName,
          "website": website,
          "location": {
            "name": address,
            "type": "Point",
            "coordinates": [selectedLng, selectedLat]
            // Note: GeoJSON is [Lng, Lat]
          }
        },
        "departments": [
          {
            "department": department,
            "role": department, // Mapping 'department' to 'role' as per your UI
            "email": email,
            "phone": phone
          }
        ]
      };
      ResponseModel response =
          await OtherRepo().createOtherBranchContactRepo(reqParm: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.hotelBranchAddedSuccess.tr);
        await getBranchDetailsController();
        _refreshHomeScreen();
        Get.back();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
      print("Request Body: $body");
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  void _refreshHomeScreen() {
    try {
      Get.find<AutomotiveBusinessProfileFullController>()
          .getBusinessProfileFull(forceRefresh: true);
    } catch (_) {}
  }

  RxList<SchoolContactUsData>? schoolContactUsData =
      <SchoolContactUsData>[].obs;

  String get website =>
      (schoolContactUsData != null && schoolContactUsData!.isNotEmpty)
          ? (schoolContactUsData!.first.branch?.website ?? "")
          : "";

  ///====================API CALLING START==============================
  ///GET BRANCH CONTACT DETAILS...

  Future<void> getBranchDetailsController() async {
    // 1. Check if data is already loaded OR if it's currently loading
    // Logic for AI generation goes here
    // try {
    schoolContactUsData?.clear();
    ResponseModel response = await OtherRepo().getOtherServiceContactRepo();

    SchoolContactUsResModel schoolContactUsModel =
        SchoolContactUsResModel.fromJson(response.response?.data);

    schoolContactUsData?.value = schoolContactUsModel.data ?? [];

    if (response.isSuccess) {
      getSchoolContactUsResponse.value =
          ApiResponse.complete(schoolContactUsModel);
    } else {
      // commonSnackBar(message: AppStrings.somethingWentWrong);
      getSchoolContactUsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
    // } on Exception catch (e) {
    //   logs("ERROR ${e}");
    //   // TODO
    //   getSchoolContactUsResponse.value =
    //       ApiResponse.error(AppStrings.somethingWentWrong);
    // }
  }

  ///Only Department Validation

  void departmentValidateForm({
    required String departmentRole,
    required String departmentEmailAddress,
    required String departmentPhoneNo,
  }) {
    final nameRegex = RegExp(r"^[a-zA-Z\s\.]{3,50}$");
    final gmailRegex = RegExp(r'^[\w-\.]+@gmail\.com$');

    isFormValid.value = nameRegex.hasMatch(departmentRole.trim()) &&
        departmentPhoneNo.length >= 10 &&
        gmailRegex.hasMatch(departmentEmailAddress.trim());
  }

  ///ADD NEW DEPARTMENT CONTACT INFO...
  Future<void> addBranchDepartmentController(
      {required Map<String, dynamic> reqBody, required String branchID}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await OtherRepo()
          .addBranchDepartmentRepo(reqParm: reqBody, branchId: branchID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        await getBranchDetailsController();
        _refreshHomeScreen();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      updateSchoolContactInfoResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///UPDATE CONTACT INFO...
  Future<void> updateBranchContactDetailsController(
      {required Map<String, dynamic> reqBody,
      required String contactID,
      required String branchID}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await OtherRepo().updateSchoolContactRepo(
          reqParm: reqBody, contactID: contactID, branchId: branchID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        updateSchoolContactInfoResponse.value =
            ApiResponse.complete(response.response?.data);
        await getBranchDetailsController();
        _refreshHomeScreen();
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

  ///DELETE BRnach Contact....
  Future<void> deleteSchoolBranchDepartmentController(
      {required String departmentId, required String contactId}) async {
    try {
      ResponseModel response = await OtherRepo().deleteSchoolBranchDeptRepo(
          contactID: contactId, deptID: departmentId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        await getBranchDetailsController();
        _refreshHomeScreen();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  ///DELETE BRanch....
  Future<void> deleteSchoolBranchController({required String contactId}) async {
    try {
      ResponseModel response =
          await OtherRepo().deleteSchoolBranchRepo(contactID: contactId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        await getBranchDetailsController();
        _refreshHomeScreen();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  ///UPDATE CONTACT INFO...
  Future<void> updateBranchContactController(
      {required Map<String, dynamic> reqBody, required String branchId}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await OtherRepo().updateSchoolBranchRepo(
        reqParm: reqBody,
        branchID: branchId,
      );

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        updateSchoolContactInfoResponse.value =
            ApiResponse.complete(response.response?.data);
        await getBranchDetailsController();
        _refreshHomeScreen();
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

  ///Only Branch Validation
  void branchValidateForm({
    required String branchName,
    required String branchWebsiteUrl,
    required String branchLocation,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value = branchName.isNotEmpty &&
        branchWebsiteUrl.isNotEmpty &&
        branchLocation.isNotEmpty;
  }
}
