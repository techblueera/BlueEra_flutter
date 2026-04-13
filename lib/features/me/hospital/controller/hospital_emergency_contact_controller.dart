import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_emergency_contact_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_emergency_contact_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalEmergencyContactController extends GetxController {
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
    // Reject numbers starting with 0, and allow 10 to 11 digits
    final phone = RegExp(r'^[1-9]\d{9,10}$');
    isEmergencyValid.value = phone.hasMatch(emergencyController.text.trim());
    isAppointmentValid.value =
        phone.hasMatch(appointmentController.text.trim());
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
      final body = {
        "emergencyNumber": emergencyController.text.trim(),
        "appointmentNumber": appointmentController.text.trim(),
        "hospitalId": hospitalIDGlobal,
      };
      final ResponseModel res = await _repo.saveOrUpdate(body: body);
      if (res.isSuccess) {
        final ec = EmergencyContactRes.fromJson(res.response?.data);
        data.value = ec.data;
        commonSnackBar(
            message: data.value == null
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
