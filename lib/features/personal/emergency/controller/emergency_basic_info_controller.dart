import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/emergency/repo/emergency_service_repo.dart';
import 'package:BlueEra/features/personal/emergency/view/emergency_contact_screen.dart';
import 'package:BlueEra/features/personal/emergency/view/emergency_medical_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmergencyBasicInfoController extends GetxController {
  final EmergencyServiceRepo _repo = EmergencyServiceRepo();
  final isSaving = false.obs;
  final isMedicalSaving = false.obs;

  final fullNameController = TextEditingController();
  final mobileController = TextEditingController();
  final alternateController = TextEditingController();
  final emailController = TextEditingController();
  final vehicleController = TextEditingController();
  final allergiesController = TextEditingController();
  final diseaseController = TextEditingController();

  final bloodGroupTypes = ['A', 'B', 'AB', 'O'];
  final bloodGroupSigns = ['+', '-'];
  final selectedBloodGroupType = RxnString();
  final selectedBloodGroupSign = RxnString();

  final isValid = false.obs;
  final isValidMedical = false.obs;

  @override
  void onInit() {
    super.onInit();
    isIndividual() ? userProfessionGlobal : businessNameGlobal;

    logs(
        "userNameGlobal=== ${isIndividual() ? userNameGlobal : businessNameGlobal}");
    logs("userMobileGlobal=== ${userMobileGlobal}");
    fullNameController.text = isIndividual() ? userNameGlobal : businessNameGlobal;
    mobileController.text = userMobileGlobal;
    fullNameController.addListener(_validate);
    mobileController.addListener(_validate);
    alternateController.addListener(_validate);
    emailController.addListener(_validate);
    vehicleController.addListener(_validate);
    selectedBloodGroupType.listen((_) => _validateMedical());
    selectedBloodGroupSign.listen((_) => _validateMedical());
    allergiesController.addListener(_validateMedical);
    diseaseController.addListener(_validateMedical);
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

    // Standard: [State 2L][Dist 2D][Alpha 1-2L][Num 4D]
    // BH Series: [Year 2D][BH][Num 4D][Alpha 1-2L]
    final re =
        RegExp(r'^([A-Z]{2}\d{2}[A-Z]{1,2}\d{4}|(\d{2}BH\d{4}[A-Z]{1,2}))$');

    return re.hasMatch(v);
  }


  String get mergedBloodGroup =>
      '${selectedBloodGroupType.value ?? ''}${selectedBloodGroupSign.value ?? ''}';

  void _validate() {
    final ok = fullNameController.text.trim().isNotEmpty &&
        _isValidPhone(mobileController.text) &&
        (alternateController.text.trim().isEmpty ||
            _isValidPhone(alternateController.text)) &&
        _isValidEmail(emailController.text) &&
        _isValidVehicle(vehicleController.text);
    isValid.value = ok;
  }

  void _validateMedical() {
    final ok = selectedBloodGroupType.value != null &&
        selectedBloodGroupSign.value != null;
    isValidMedical.value = ok;
  }

  Future<void> submit() async {
    if (!isValid.value) {
      commonSnackBar(message: AppStrings.emergencyFillRequiredFields);
      return;
    }

    logs("vehicleController.text=== ${vehicleController.text}");
    if (fullNameController.text.isEmpty) {
      commonSnackBar(message: AppStrings.emergencyFillFullName);
      return;
    }
    else if (mobileController.text.isEmpty) {
      commonSnackBar(message: AppStrings.emergencyFillMobile);
      return;
    }
    else if (alternateController.text.isEmpty) {
      commonSnackBar(message: AppStrings.emergencyFillAlternate);
      return;
    }
    else if (vehicleController.text.isEmpty) {
      commonSnackBar(message: AppStrings.emergencyFillVehicle);
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
      };
      final ResponseModel res = await _repo.submitBasicInfo(body: body);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.emergencySavedBasicInfo);
        Get.to(EmergencyMedicalInfoScreen());
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> submitMedical() async {
    if (!isValidMedical.value) {
      commonSnackBar(message: AppStrings.emergencyFillRequiredFields);
      return;
    }
    try {
      isMedicalSaving.value = true;
      final body = {
        "bloodGroup": mergedBloodGroup,
        "knownAllergies": allergiesController.text.trim(),
        "knownDisease": diseaseController.text.trim(),
      };
      final ResponseModel res = await _repo.submitBasicInfo(body: body);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.emergencySavedMedicalInfo);
        Get.to(EmergencyContactScreen());
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isMedicalSaving.value = false;
    }
  }
}
