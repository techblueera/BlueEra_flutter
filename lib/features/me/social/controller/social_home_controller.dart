import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/social/model/social_profile_res_model.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialHomeController extends GetxController {
  final isLoading = false.obs;
  final profile = Rxn<SocialProfileResModel>();

  // Contact form controllers
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final isFormValid = false.obs;

  double? selectedLat;
  double? selectedLng;

  @override
  void onInit() {
    super.onInit();
    // fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final res = await SocialProfileRepo().getSocialProfile();
      profile.value = res;
      final contact = res.data?.contact;
      if (contact != null) {
        nameCtrl.text = contact.name ?? '';
        emailCtrl.text = contact.email ?? '';
        phoneCtrl.text = contact.phoneNo ?? '';
        websiteCtrl.text = contact.websiteUrl ?? '';
        addressCtrl.text = contact.location?.name ?? '';
        final coords = contact.location?.coordinates ?? [];
        if (coords.length == 2) {
          selectedLat = coords[0];
          selectedLng = coords[1];
        }
      }
      validateForm();
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void setSelectedLocation(String name, double lat, double lng) {
    addressCtrl.text = name;
    selectedLat = lat;
    selectedLng = lng;
    validateForm();
  }

  void validateForm() {
    final emailError = ValidationMethod.validateEmail(emailCtrl.text);
    final phoneError = ValidationMethod.validatePhone(phoneCtrl.text);
    final nameError = ValidationMethod.validateName(nameCtrl.text);
    final websiteError = ValidationMethod.urlValidation(websiteCtrl.text);
    final addressOk = addressCtrl.text.trim().isNotEmpty;

    isFormValid.value =
        emailError == null &&
        phoneError == null &&
        nameError == null &&
        websiteError == null &&
        addressOk &&
        selectedLat != null &&
        selectedLng != null;
  }

  Future<void> submitContact() async {
    if (!isFormValid.value) {
      commonSnackBar(message: AppStrings.pleaseEnterValidDetails.tr);
      return;
    }
    try {
      isLoading.value = true;
      final body = {
        "name": nameCtrl.text.trim(),
        "websiteUrl": websiteCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "phoneNo": phoneCtrl.text.trim(),
        "location": {
          "name": addressCtrl.text.trim(),
          "type": "Point",
          "coordinates": [selectedLat, selectedLng]
        }
      };
      ResponseModel response =
          await SocialProfileRepo().addSocialContactRepo(reqBody: body);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                "Contact updated successfully");
        await fetchProfile();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
