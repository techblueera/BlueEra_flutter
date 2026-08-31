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
    final e164 = RegExp(r'^\+91[6-9]\d{9}$');
    final local10 = RegExp(r'^[6-9]\d{9}$');
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
      commonSnackBar(message: AppStrings.emergencyFillRequiredFields.tr);
      return;
    }
    try {
      isSaving.value = true;
      final body = {
        "name": nameController.text.trim(),
        "contactNo": mobileController.text.trim(),
        "relationship": relationshipController.text.trim(),
      };
      final ResponseModel res = await _repo.submitEmergencyContact(body: body);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.emergencySavedContact.tr);
        Get.to(() => EmergencyPrivacyAlertsScreen());
      } else {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isSaving.value = false;
    }
  }
}
