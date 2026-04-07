import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/emergency/repo/emergency_service_repo.dart';
import 'package:BlueEra/features/personal/emergency/view/emergency_privacy_alerts_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmergencyContactsController extends GetxController {
  final EmergencyServiceRepo _repo = EmergencyServiceRepo();
  final isSaving = false.obs;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final relationshipController = TextEditingController();

  final isValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_validate);
    mobileController.addListener(_validate);
    relationshipController.addListener(_validate);
  }

  bool _isValidPhone(String value) {
    final v = value.trim();
    final e164 = RegExp(r'^\+91\d{10}$');
    final local10 = RegExp(r'^\d{10}$');
    return e164.hasMatch(v) || local10.hasMatch(v);
  }

  void _validate() {
    final ok = nameController.text.trim().isNotEmpty &&
        _isValidPhone(mobileController.text) &&
        relationshipController.text.trim().isNotEmpty;
    isValid.value = ok;
  }

  Future<void> submit() async {
    if (!isValid.value) {
      commonSnackBar(message: AppStrings.emergencyFillRequiredFields);
      return;
    }
    try {
      isSaving.value = true;
      final body = {
        "name": nameController.text.trim(),
        "mobileNumber": mobileController.text.trim(),
        "relationship": relationshipController.text.trim(),
      };
      final ResponseModel res = await _repo.submitEmergencyContact(body: body);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.emergencySavedContact);
        Get.to(EmergencyPrivacyAlertsScreen());
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}
