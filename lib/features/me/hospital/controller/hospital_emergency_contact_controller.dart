import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_emergency_contact_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_emergency_contact_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalEmergencyContactController extends GetxController {
  // Reject numbers starting with 0, allow 10–11 digits.
  static final RegExp _phoneRegex = RegExp(r'^[1-9]\d{9,10}$');

  final HospitalEmergencyContactRepo _repo = HospitalEmergencyContactRepo();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = ''.obs;
  final data = Rxn<EmergencyContactData>();

  final emergencyController = TextEditingController();
  final appointmentController = TextEditingController();

  final isEmergencyValid = false.obs;
  final isAppointmentValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
    emergencyController.addListener(_validate);
    appointmentController.addListener(_validate);
  }

  void _validate() {
    isEmergencyValid.value =
        _phoneRegex.hasMatch(emergencyController.text.trim());
    isAppointmentValid.value =
        _phoneRegex.hasMatch(appointmentController.text.trim());
  }

  bool get isFormValid => isEmergencyValid.value && isAppointmentValid.value;

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      error.value = '';
      final ResponseModel res = await _repo.getByHospital();
      if (res.isSuccess) {
        final ec = EmergencyContactRes.fromJson(res.response?.data);
        data.value = ec.data;
        if (ec.data != null) {
          emergencyController.text = ec.data?.emergencyNumber ?? '';
          appointmentController.text = ec.data?.appointmentNumber ?? '';
          _validate();
        }
      } else {
        error.value = res.message ?? AppStrings.somethingWentWrong;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submit() async {
    if (!isFormValid) {
      commonSnackBar(message: AppStrings.hospitalCtrlAllFieldsRequiredValid.tr);
      return;
    }
    try {
      isSaving.value = true;
      // Capture create-vs-update intent BEFORE the server response replaces
      // `data.value` — otherwise we'd always read the post-save value.
      final wasCreate = data.value == null;
      final body = {
        "emergencyNumber": emergencyController.text.trim(),
        "appointmentNumber": appointmentController.text.trim(),
        "hospitalId": hospitalIDGlobal,
      };
      final ResponseModel res = await _repo.saveOrUpdate(body: body);
      if (res.isSuccess) {
        data.value = EmergencyContactRes.fromJson(res.response?.data).data;
        commonSnackBar(
            message: wasCreate
                ? AppStrings.hospitalCtrlSavedSuccessfully.tr
                : AppStrings.hospitalCtrlUpdatedSuccessfully.tr);
        Get.back();
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
