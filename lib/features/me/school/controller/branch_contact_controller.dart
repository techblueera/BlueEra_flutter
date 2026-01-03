import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_new_res_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BranchContactController extends GetxController {
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
    // Basic validation logic
    bool isValid = branchName.isNotEmpty &&
        website.isURL &&
        address.isNotEmpty &&
        department.isNotEmpty &&
        email.isEmail &&
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
      commonSnackBar(
          message: "Please select a valid location from the search.");
      return;
    }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "schoolId": schoolIDGlobal, // Replace with dynamic ID if needed
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
          await SchoolRepo().createSchoolBranchContactRepo(reqParm: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                "Branch details added successfully");
      await  getBranchDetailsController();
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

  RxList<SchoolContactUsData>? schoolContactUsData = <SchoolContactUsData>[].obs;

  ///====================API CALLING START==============================
  ///GET BRANCH CONTACT DETAILS...

  Future<void> getBranchDetailsController() async {
    // 1. Check if data is already loaded OR if it's currently loading
    // Logic for AI generation goes here
    try {
      schoolContactUsData?.clear();
      ResponseModel response = await SchoolRepo().getSchoolContactRepo();

      SchoolContactUsResModel schoolContactUsModel =
      SchoolContactUsResModel.fromJson(response.response?.data);

      schoolContactUsData?.value =
          schoolContactUsModel.data ?? [];

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
  ///ADD NEW DEPARTMENT CONTACT INFO...
  Future<void> addBranchDepartmentController({required Map<String,dynamic> reqBody,required String branchID}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().addBranchDepartmentRepo(
          reqParm: reqBody,
         branchId: branchID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
            response.response?.data["message"] ?? AppStrings.successful);

      await  getBranchDetailsController();
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
  Future<void> updateBranchContactDetailsController({required Map<String,dynamic> reqBody,required String contactID,required String branchID}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().updateSchoolContactRepo(
          reqParm: reqBody,
          contactID: contactID, branchId: branchID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        updateSchoolContactInfoResponse.value =
            ApiResponse.complete(response.response?.data);
        await  getBranchDetailsController();

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
      {required String departmentId,required String contactId}) async {
    try {
      ResponseModel response = await SchoolRepo()
          .deleteSchoolBranchDeptRepo(contactID:contactId ,deptID: departmentId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
            response.response?.data['message'] ?? AppStrings.successful);
        await  getBranchDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  ///DELETE BRanch....
  Future<void> deleteSchoolBranchController(
      {required String contactId}) async {
    try {
      ResponseModel response = await SchoolRepo()
          .deleteSchoolBranchRepo(contactID:contactId );

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
            response.response?.data['message'] ?? AppStrings.successful);
        await  getBranchDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }

  ///UPDATE CONTACT INFO...
  Future<void> updateBranchContactController({required Map<String,dynamic> reqBody,required String branchId}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().updateSchoolBranchRepo(
          reqParm: reqBody,
        branchID: branchId, );

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
            response.response?.data["message"] ?? AppStrings.successful);
        updateSchoolContactInfoResponse.value =
            ApiResponse.complete(response.response?.data);
        await  getBranchDetailsController();

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
