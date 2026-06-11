import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/emergency/repo/emergency_service_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/emergency_profile_model.dart';

/// Drives the "edit emergency contact" form and the
/// `PUT emergency-service/emergency-contacts/{id}` call.
class EmergencyContactEditController extends GetxController {
  EmergencyContactEditController(this.contact);

  final EmergencyContacts contact;
  final EmergencyServiceRepo _repo = EmergencyServiceRepo();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final relationshipController = TextEditingController();

  final isSaving = false.obs;
  final isValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController.text = contact.name ?? '';
    mobileController.text = contact.mobileNumber ?? '';
    relationshipController.text = contact.relationship ?? '';

    nameController.addListener(_validate);
    mobileController.addListener(_validate);
    relationshipController.addListener(_validate);
    _validate();
  }

  bool _isValidPhone(String value) {
    final v = value.trim();
    final e164 = RegExp(r'^\+91[6-9]\d{9}$');
    final local10 = RegExp(r'^[6-9]\d{9}$');
    return e164.hasMatch(v) || local10.hasMatch(v);
  }

  void _validate() {
    isValid.value = nameController.text.trim().isNotEmpty &&
        _isValidPhone(mobileController.text) &&
        relationshipController.text.trim().isNotEmpty;
  }

  Future<void> submit() async {
    if (!isValid.value) {
      commonSnackBar(message: AppStrings.emergencyFillRequiredFields.tr);
      return;
    }
    final id = contact.sId;
    if (id == null || id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    try {
      isSaving.value = true;
      final body = {
        "_id": contact.sId,
        "name": nameController.text.trim(),
        "contactNo": mobileController.text.trim(),
        "relationship": relationshipController.text.trim(),
        "userId": contact.userId ?? userId,
        "createdAt": contact.createdAt,
        "updatedAt": contact.updatedAt,
      };
      final ResponseModel res =
          await _repo.updateEmergencyContact(id: id, body: body);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.updatedSuccessfully.tr);
        Get.back(result: true);
      } else {
        commonSnackBar(message: res.message ?? AppStrings.updateFailed.tr);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    mobileController.dispose();
    relationshipController.dispose();
    super.onClose();
  }
}
