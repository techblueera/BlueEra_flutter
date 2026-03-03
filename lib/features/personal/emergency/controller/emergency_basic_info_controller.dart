import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/emergency/repo/emergency_service_repo.dart';
import 'package:BlueEra/features/personal/emergency/view/emergency_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmergencyBasicInfoController extends GetxController {
  final EmergencyServiceRepo _repo = EmergencyServiceRepo();
  final isSaving = false.obs;

  final fullNameController = TextEditingController();
  final mobileController = TextEditingController();
  final alternateController = TextEditingController();
  final emailController = TextEditingController();
  final vehicleController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final allergiesController = TextEditingController();
  final diseaseController = TextEditingController();

  final isValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    fullNameController.addListener(_validate);
    mobileController.addListener(_validate);
    alternateController.addListener(_validate);
    emailController.addListener(_validate);
    vehicleController.addListener(_validate);
    bloodGroupController.addListener(_validate);
    allergiesController.addListener(_validate);
    diseaseController.addListener(_validate);
  }

  bool _isValidPhone(String value) {
    final v = value.trim();
    final e164 = RegExp(r'^\+91\d{10}$');
    final local10 = RegExp(r'^\d{10}$');
    return e164.hasMatch(v) || local10.hasMatch(v);
  }

  bool _isValidEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return true;
    final re = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return re.hasMatch(v);
  }

  bool _isValidVehicle(String value) {
    final v = value.trim().toUpperCase();
    if (v.isEmpty) return true;
    final re = RegExp(r'^[A-Z]{2}\d{2}[A-Z]{1,2}\d{4}$');
    return re.hasMatch(v);
  }

  bool _isValidBloodGroup(String value) {
    final allowed = {
      'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
    };
    final v = value.trim().toUpperCase();
    return allowed.contains(v);
  }

  void _validate() {
    final ok = fullNameController.text.trim().isNotEmpty &&
        _isValidPhone(mobileController.text) &&
        (alternateController.text.trim().isEmpty ||
            _isValidPhone(alternateController.text)) &&
        _isValidEmail(emailController.text) &&
        _isValidVehicle(vehicleController.text) &&
        _isValidBloodGroup(bloodGroupController.text);
    isValid.value = ok;
  }

  Future<void> submit() async {
    if (!isValid.value) {
      commonSnackBar(message: "Please fill all required fields correctly");
      return;
    }
    try {
      isSaving.value = true;
      final body = {
        "fullName": fullNameController.text.trim(),
        "mobileNumber": mobileController.text.trim(),
        "alternateNumber": alternateController.text.trim(),
        "emailId": emailController.text.trim(),
        "vehicleNumber": vehicleController.text.trim().toUpperCase(),
        "bloodGroup": bloodGroupController.text.trim().toUpperCase(),
        "knownAllergies": allergiesController.text.trim(),
        "knownDisease": diseaseController.text.trim(),
      };
      final ResponseModel res = await _repo.submitBasicInfo(body: body);
      if (res.isSuccess) {
        commonSnackBar(message: "Saved basic info");
        Get.to(EmergencyContactScreen());
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
