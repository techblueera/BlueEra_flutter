import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/get_hotel_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

/// Branch / reception contact management for a hotel:
/// list, create, update and delete reception contacts.
class HotelBranchContactController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final Rx<ApiResponse> getHotelContactUsResponse =
      ApiResponse.initial('Initial').obs;
  final Rx<GetHotelContactUsResModel> hotelContactUsData =
      GetHotelContactUsResModel().obs;

  final RxBool isLoading = false.obs;
  final RxBool isFormValid = false.obs;

  /// Coordinates set by the location-picker on the branch form.
  double? selectedLat;
  double? selectedLng;

  // ---- Validation ------------------------------------------------------------

  /// Full-form validation for the branch-details form
  /// (`hotel_branch_details_form_screen`).
  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String email,
    required String phone,
  }) {
    final isGmail = email.trim().toLowerCase().endsWith("@gmail.com");
    final isRepetitive =
        phone.isNotEmpty && phone.split('').every((c) => c == phone[0]);
    final isPhoneValid = phone.length == 10 &&
        RegExp(r'^[0-9]+$').hasMatch(phone) &&
        !isRepetitive;
    final isWebsiteValid = website.isEmpty || GetUtils.isURL(website);
    final isAddressValid = address.isNotEmpty;

    isFormValid.value =
        isAddressValid && isGmail && isPhoneValid && isWebsiteValid;
  }

  /// Lighter validation used by the department-only form.
  void departmentValidateForm({
    required String departmentRole,
    required String departmentEmailAddress,
    required String departmentAddress,
    required String departmentPhoneNo,
  }) {
    isFormValid.value = departmentPhoneNo.isNotEmpty &&
        departmentAddress.isNotEmpty &&
        departmentEmailAddress.isNotEmpty;
  }

  /// Branch-only validation (no email/phone fields).
  void branchValidateForm({
    required String branchName,
    required String branchWebsiteUrl,
    required String branchLocation,
  }) {
    isFormValid.value = branchName.isNotEmpty &&
        branchWebsiteUrl.isNotEmpty &&
        branchLocation.isNotEmpty;
  }

  // ---- Reads -----------------------------------------------------------------

  Future<void> getBranchDetailsController() async {
    try {
      final ResponseModel response = await _repo.getAllHotelContactsRepo();
      hotelContactUsData.value =
          GetHotelContactUsResModel.fromJson(response.response?.data);

      if (response.isSuccess) {
        getHotelContactUsResponse.value =
            ApiResponse.complete(hotelContactUsData.value);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getHotelContactUsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("HotelBranchContactController.getBranchDetails ERROR $e");
      getHotelContactUsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  // ---- Writes ----------------------------------------------------------------

  Future<void> submitBranchDetails({
    required String website,
    required String address,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(message: AppStrings.hotelSelectValidLocation.tr);
      return;
    }
    await _submitContact(
      body: _receptionBody(
          email: email, phone: phone, address: address, website: website),
      isUpdate: false,
      successMessage: AppStrings.hotelBranchAddedSuccess.tr,
    );
  }

  Future<void> updateBranchDetails({
    required String website,
    required String address,
    required String email,
    required String phone,
    required String contactID,
  }) async {
    await _submitContact(
      body: _receptionBody(
          email: email, phone: phone, address: address, website: website),
      isUpdate: true,
      contactId: contactID,
      successMessage: AppStrings.hotelBranchUpdatedSuccess.tr,
    );
  }

  /// Generic contact update path also used by the branch-only screen.
  Future<void> updateBranchContactController({
    required Map<String, dynamic> reqBody,
    required String branchId,
  }) async {
    try {
      final ResponseModel response = await _repo.updateHotelContactRepo(
        reqBody: reqBody,
        id: branchId,
      );
      _handleContactWriteResponse(response);
    } on Exception catch (e) {
      logs("HotelBranchContactController.updateBranchContact ERROR $e");
    }
  }

  Future<void> deleteHotelBranchDepartmentController({
    required String departmentId,
  }) async {
    try {
      final ResponseModel response =
          await _repo.deleteHotelContactRepo(departmentId);
      _handleContactWriteResponse(response);
    } on Exception catch (e) {
      logs("HotelBranchContactController.deleteBranchDepartment ERROR $e");
    }
  }

  // ---- Shared helpers --------------------------------------------------------

  Map<String, dynamic> _receptionBody({
    required String email,
    required String phone,
    required String address,
    required String website,
  }) =>
      {
        "type": "reception",
        "email": email,
        "phone": phone,
        "address": address,
        "website": website,
      };

  Future<void> _submitContact({
    required Map<String, dynamic> body,
    required bool isUpdate,
    required String successMessage,
    String? contactId,
  }) async {
    try {
      isLoading.value = true;
      final ResponseModel response = isUpdate
          ? await _repo.updateHotelContactRepo(reqBody: body, id: contactId!)
          : await _repo.addHotelContactRepo(reqBody: body);

      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ?? successMessage);
        Get.back();
        await getBranchDetailsController();
        _refreshHotelHome();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("HotelBranchContactController._submitContact ERROR $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleContactWriteResponse(ResponseModel response) {
    if (response.isSuccess) {
      Get.back();
      commonSnackBar(
          message: response.response?.data["message"] ?? AppStrings.successful);
      getBranchDetailsController();
    } else {
      commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
    }
  }

  void _refreshHotelHome() {
    try {
      Get.find<HotelDetailController>().loadHotelData();
    } catch (_) {}
  }
}
