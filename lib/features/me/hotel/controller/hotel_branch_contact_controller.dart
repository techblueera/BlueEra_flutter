import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/get_hotel_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:get/get.dart';

class HotelBranchContactController extends GetxController {
  Rx<ApiResponse> getHotelContactUsResponse =
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
    bool isValid =
        // branchName.isNotEmpty &&
        // website.isURL &&
        address.isNotEmpty &&
            // department.isNotEmpty &&
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
        "type": "reception",
        "email": email,
        "phone": phone,
        "address": address
      };

      ResponseModel response =
          await HotelServiceRepo().addHotelContactRepo(reqBody: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                "Branch details added successfully");
        Get.back();
        await getBranchDetailsController();
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



  Future<void> updateBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
    required String contactID,
  }) async {
    // if (selectedLat == null || selectedLng == null) {
    //   commonSnackBar(
    //       message: "Please select a valid location from the search.");
    //   return;
    // }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "type": "reception",
        "email": email,
        "phone": phone,
        "address": address
      };

      ResponseModel response =
          await HotelServiceRepo().updateHotelContactRepo(reqBody: body, id: contactID);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                "Branch details update successfully");
        Get.back();
        await getBranchDetailsController();
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

  Rx<GetHotelContactUsResModel>? hotelContactUsData =
      GetHotelContactUsResModel().obs;

  ///====================API CALLING START==============================
  ///GET BRANCH CONTACT DETAILS...

  Future<void> getBranchDetailsController() async {
    // 1. Check if data is already loaded OR if it's currently loading
    // Logic for AI generation goes here
    try {
      // schoolContactUsData=null;
      ResponseModel response =
          await HotelServiceRepo().getAllHotelContactsRepo();

      hotelContactUsData?.value =
          GetHotelContactUsResModel.fromJson(response.response?.data);

      if (response.isSuccess) {
        getHotelContactUsResponse.value =
            ApiResponse.complete(hotelContactUsData?.value);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getHotelContactUsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      getHotelContactUsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///Only Department Validation

  void departmentValidateForm({
    required String departmentRole,
    required String departmentEmailAddress,
    required String departmentAddress,
    required String departmentPhoneNo,
  }) {
    // Condition: All text fields not empty AND at least 1 image
    isFormValid.value =
        // departmentRole.isNotEmpty &&
        departmentPhoneNo.isNotEmpty &&
        departmentAddress.isNotEmpty &&
        departmentEmailAddress.isNotEmpty;
  }

  ///ADD NEW DEPARTMENT CONTACT INFO...
  Future<void> addBranchDepartmentController(
      {required Map<String, dynamic> reqBody, required String branchID}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo()
          .addBranchDepartmentRepo(reqParm: reqBody, branchId: branchID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);

        await getBranchDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
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
      ResponseModel response = await SchoolRepo().updateSchoolContactRepo(
          reqParm: reqBody, contactID: contactID, branchId: branchID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        await getBranchDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
    }
  }

  ///DELETE BRnach Contact....
  Future<void> deleteHotelBranchDepartmentController(
      {required String departmentId,}) async {
    try {
      ResponseModel response = await HotelServiceRepo().deleteHotelContactRepo(
         departmentId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        await getBranchDetailsController();
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
          await SchoolRepo().deleteSchoolBranchRepo(contactID: contactId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        await getBranchDetailsController();
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
      ResponseModel response = await SchoolRepo().updateSchoolBranchRepo(
        reqParm: reqBody,
        branchID: branchId,
      );

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        await getBranchDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
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
