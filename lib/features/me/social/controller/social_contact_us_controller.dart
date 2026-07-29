import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/social/model/social_contact_us_res_model.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:get/get.dart';

class SocialContactUsController extends GetxController {
  // Observables
  var isLoading = true.obs;
  var contactUsData = Rxn<SocialContactUsResModel>();

  @override
  void onInit() {
    super.onInit();
  }

  fetchHomeData() async {
    try {
      isLoading(true);

      // call repo
      ResponseModel responseModel =
          await SocialProfileRepo().getSocialContactByIdRepo();

      if (responseModel.isSuccess) {
        contactUsData.value =
            SocialContactUsResModel.fromJson(responseModel.response?.data);
      }
    } finally {
      isLoading(false);
    }
  }

  // Validation state
  var isFormValid = false.obs;

  // Values to store from location picker
  double? selectedLat;
  double? selectedLng;

  // Per-field error messages
  var nameError = ''.obs;
  var websiteError = ''.obs;
  var addressError = ''.obs;
  var emailError = ''.obs;
  var phoneError = ''.obs;

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String email,
    required String phone,
  }) {
    // Name: at least 3 chars, letters, numbers, spaces allowed
    final nameRegex = RegExp(r'^[a-zA-Z0-9\s\.\-]{3,50}$');
    // Email: must end with @gmail.com
    final gmailRegex = RegExp(r'^[a-zA-Z0-9][\w\-\.]*@gmail\.com$');
    // Website: must start with http:// or https://
    final websiteRegex = RegExp(r'^https?://[\w\-]+(\.[\w\-]+)+.*$', caseSensitive: false);
    // Phone: strip +91 prefix then validate 10-digit Indian mobile (starts with 6-9)
    String cleanPhone = phone.trim().replaceFirst(RegExp(r'^\+91\s?'), '');
    final phoneRegex = RegExp(r'^[6-9][0-9]{9}$');

    nameError.value = branchName.trim().isEmpty
        ? AppStrings.fullNameRequired.tr
        : !nameRegex.hasMatch(branchName.trim())
            ? AppStrings.nameLengthRule.tr
            : '';

    websiteError.value = website.trim().isNotEmpty && !websiteRegex.hasMatch(website.trim())
        ? AppStrings.enterValidWebsiteUrl.tr
        : website.trim().isEmpty
            ? AppStrings.websiteUrlRequired.tr
            : '';

    addressError.value = address.trim().isEmpty ? AppStrings.locationRequired.tr : '';

    emailError.value = email.trim().isEmpty
        ? AppStrings.validationEmailRequired.tr
        : !gmailRegex.hasMatch(email.trim())
            ? AppStrings.enterValidGmail.tr
            : '';

    phoneError.value = phone.trim().isEmpty
        ? AppStrings.phoneNumberRequired.tr
        : !phoneRegex.hasMatch(cleanPhone)
            ? AppStrings.enterValidMobileNumber.tr
            : '';

    bool isValid = nameError.value.isEmpty &&
        websiteError.value.isEmpty &&
        addressError.value.isEmpty &&
        emailError.value.isEmpty &&
        phoneError.value.isEmpty;

    isFormValid.value = isValid;
  }

  /// Returns first validation error message, or null if all valid
  String? getFirstError() {
    if (nameError.value.isNotEmpty) return nameError.value;
    if (websiteError.value.isNotEmpty) return websiteError.value;
    if (emailError.value.isNotEmpty) return emailError.value;
    if (phoneError.value.isNotEmpty) return phoneError.value;
    if (addressError.value.isNotEmpty) return addressError.value;
    return null;
  }

  Future<void> submitBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(
          message: AppStrings.selectValidLocationFromSearch.tr);
      return;
    }

    try {
      isLoading.value = true;

      // Prepare Request Body
      Map<String, dynamic> body = {
        "name": branchName,
        "websiteUrl": website,
        "email": email,
        "phoneNo": phone,
        "location": {
          "name": address,
          "type": "Point",
          "coordinates": [selectedLat, selectedLng]
        }
      };

      ResponseModel response =
          await SocialProfileRepo().addSocialContactRepo(reqBody: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                "Branch details added successfully");
        Get.back();
        fetchHomeData();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      }
      print("Request Body: $body");
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
