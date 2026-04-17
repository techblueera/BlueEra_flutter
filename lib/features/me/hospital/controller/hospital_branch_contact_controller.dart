import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_contact_us_repo.dart';
import 'package:get/get.dart';

class HospitalBranchContactController extends GetxController {
  HospitalContactUsRepo hospitalContactUsRepo = HospitalContactUsRepo();
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

  // Per-field error messages
  var branchNameError = ''.obs;
  var websiteError = ''.obs;
  var addressError = ''.obs;
  var departmentError = ''.obs;
  var emailError = ''.obs;
  var phoneError = ''.obs;

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) {
    // Branch name: at least 3 chars, letters, numbers, spaces, dots allowed
    final nameRegex = RegExp(r'^[a-zA-Z0-9\s\.\-]{3,50}$');
    // Email: must end with @gmail.com
    final gmailRegex = RegExp(r'^[a-zA-Z0-9][\w\-\.]*@gmail\.com$');
    // Website: must start with http:// or https://
    final websiteRegex = RegExp(r'^https?://[\w\-]+(\.[\w\-]+)+.*$', caseSensitive: false);
    // Phone: valid Indian mobile number (starts with 6-9, exactly 10 digits)
    final phoneRegex = RegExp(r'^[6-9][0-9]{9}$');

    // Validate each field
    branchNameError.value = branchName.trim().isEmpty
        ? 'Branch name is required'
        : !nameRegex.hasMatch(branchName.trim())
            ? 'Branch name must be 3-50 characters (letters, numbers, spaces)'
            : '';

    websiteError.value = website.trim().isNotEmpty && !websiteRegex.hasMatch(website.trim())
        ? 'Please enter a valid website URL (e.g. https://example.com)'
        : '';

    addressError.value = address.trim().isEmpty ? 'Location is required' : '';

    departmentError.value = department.trim().isEmpty
        ? 'Department name is required'
        : !nameRegex.hasMatch(department.trim())
            ? 'Department must be 3-50 characters (letters, numbers, spaces)'
            : '';

    emailError.value = email.trim().isEmpty
        ? 'Email is required'
        : !gmailRegex.hasMatch(email.trim())
            ? 'Please enter a valid Gmail address (e.g. name@gmail.com)'
            : '';

    phoneError.value = phone.trim().isEmpty
        ? 'Phone number is required'
        : !phoneRegex.hasMatch(phone.trim())
            ? 'Please enter a valid 10-digit mobile number (starts with 6-9)'
            : '';

    bool isValid = branchNameError.value.isEmpty &&
        websiteError.value.isEmpty &&
        addressError.value.isEmpty &&
        departmentError.value.isEmpty &&
        emailError.value.isEmpty &&
        phoneError.value.isEmpty;

    isFormValid.value = isValid;
  }

  /// Returns the first validation error message, or null if all valid
  String? getFirstError() {
    if (branchNameError.value.isNotEmpty) return branchNameError.value;
    if (websiteError.value.isNotEmpty) return websiteError.value;
    if (addressError.value.isNotEmpty) return addressError.value;
    if (departmentError.value.isNotEmpty) return departmentError.value;
    if (emailError.value.isNotEmpty) return emailError.value;
    if (phoneError.value.isNotEmpty) return phoneError.value;
    return null;
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
      commonSnackBar(message: AppStrings.hospitalCtrlSelectValidLocation.tr);
      return;
    }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "hospitalId": hospitalIDGlobal, // Replace with dynamic ID if needed
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
      ResponseModel response = await hospitalContactUsRepo
          .createSchoolBranchContactRepo(reqParm: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.hospitalCtrlBranchAddedSuccessfully.tr);
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

  RxList<SchoolContactUsData>? schoolContactUsData =
      <SchoolContactUsData>[].obs;

  ///====================API CALLING START==============================
  ///GET BRANCH CONTACT DETAILS...

  Future<void> getBranchDetailsController() async {
    // 1. Check if data is already loaded OR if it's currently loading
    // Logic for AI generation goes here
    try {
      schoolContactUsData?.clear();
      ResponseModel response =
          await hospitalContactUsRepo.getSchoolContactRepo();

      SchoolContactUsResModel schoolContactUsModel =
          SchoolContactUsResModel.fromJson(response.response?.data);

      schoolContactUsData?.value = schoolContactUsModel.data ?? [];

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

  void departmentValidateForm({
    required String departmentRole,
    required String departmentEmailAddress,
    required String departmentPhoneNo,
  }) {
    final nameRegex = RegExp(r'^[a-zA-Z0-9\s\.\-]{3,50}$');
    final gmailRegex = RegExp(r'^[a-zA-Z0-9][\w\-\.]*@gmail\.com$');
    final phoneRegex = RegExp(r'^[6-9][0-9]{9}$');

    isFormValid.value = nameRegex.hasMatch(departmentRole.trim()) &&
        phoneRegex.hasMatch(departmentPhoneNo.trim()) &&
        gmailRegex.hasMatch(departmentEmailAddress.trim());
  }

  ///ADD NEW DEPARTMENT CONTACT INFO...
  Future<void> addBranchDepartmentController(
      {required Map<String, dynamic> reqBody, required String branchID}) async {
    // 1. Check if data is already loaded OR if it's currently loading

    // Logic for AI generation goes here
    try {
      ResponseModel response = await hospitalContactUsRepo
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
      ResponseModel response =
          await hospitalContactUsRepo.updateSchoolContactRepo(
              reqParm: reqBody, contactID: contactID, branchId: branchID);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data["message"] ?? AppStrings.successful);
        updateSchoolContactInfoResponse.value =
            ApiResponse.complete(response.response?.data);
        await getBranchDetailsController();
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
      ResponseModel response =
          await hospitalContactUsRepo.deleteSchoolBranchDeptRepo(
              contactID: contactId, deptID: departmentId);

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
      ResponseModel response = await hospitalContactUsRepo
          .deleteSchoolBranchRepo(contactID: contactId);

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
      ResponseModel response =
          await hospitalContactUsRepo.updateSchoolBranchRepo(
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
