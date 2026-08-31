import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
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
    fullNameController.text =
        isIndividual() ? userNameGlobal : businessNameGlobal;
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

  /// Both the "is the form complete" gate and the field's own validator read
  /// the SAME rule ([VehicleNumber]) — this used to be a private regex here
  /// that had drifted from the two in [ValidationMethod], so the same plate was
  /// accepted on one screen and rejected on another.
  ///
  /// Required, not optional. This used to accept an EMPTY value, which left the
  /// Next button enabled on a form with no vehicle number — the user tapped it
  /// and got the "fill vehicle" snackbar from [submit] instead of moving on.
  /// [submit] has always treated the field as mandatory, so the gate now agrees
  /// with it.
  bool _isValidVehicle(String value) => VehicleNumber.validate(value) == null;

  /// Field-level validator for the vehicle number text field.
  String? validateVehicleNumber(String? value) => VehicleNumber.validate(value);

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
      commonSnackBar(message: AppStrings.emergencyFillRequiredFields.tr);
      return;
    }

    logs("vehicleController.text=== ${vehicleController.text}");
    if (fullNameController.text.isEmpty) {
      commonSnackBar(message: AppStrings.emergencyFillFullName.tr);
      return;
    } else if (mobileController.text.isEmpty) {
      commonSnackBar(message: AppStrings.emergencyFillMobile.tr);
      return;
    } else if (alternateController.text.isEmpty) {
      commonSnackBar(message: AppStrings.emergencyFillAlternate.tr);
      return;
    } else if (vehicleController.text.isEmpty) {
      commonSnackBar(message: AppStrings.emergencyFillVehicle.tr);
      return;
    }

    try {
      isSaving.value = true;
      final body = {
        "fullName": fullNameController.text.trim(),
        "mobileNumber": mobileController.text.trim(),
        "alternateNumber": alternateController.text.trim(),
        "emailId": emailController.text.trim(),
        // Normalised, not just upper-cased. The field lets the plate be typed
        // with the spaces/dashes people write (`MH 12 AB 1234`), so the raw
        // text would reach the backend in a different shape from every other
        // screen — all of which store `MH12AB1234`. Validation already compares
        // the normalised form, so this stores exactly what was validated.
        "vehicleNumber": VehicleNumber.normalize(vehicleController.text),
      };
      final ResponseModel res = await _repo.submitBasicInfo(body: body);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.emergencySavedBasicInfo.tr);
        Get.to(() => EmergencyMedicalInfoScreen());
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

  Future<void> submitMedical() async {
    if (!isValidMedical.value) {
      commonSnackBar(message: AppStrings.emergencyFillRequiredFields.tr);
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
        commonSnackBar(message: AppStrings.emergencySavedMedicalInfo.tr);
        Get.to(() => EmergencyContactScreen());
      } else {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isMedicalSaving.value = false;
    }
  }
}
