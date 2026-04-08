import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_vision_mission_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_vision_mission_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalVisionMissionController extends GetxController {
  final HospitalVisionMissionRepo _repo = HospitalVisionMissionRepo();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = ''.obs;
  final descriptionTest = ''.obs;
  final data = Rxn<VisionMissionData>();
  final visionController = TextEditingController();
  final int maxLen = 2000;

  HospitalVisionMissionController();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      error.value = '';
      final ResponseModel res = await _repo.getByHospital();
      if (res.isSuccess) {
        final VisionMissionRes vm = VisionMissionRes.fromJson(res.response?.data);
        data.value = vm.data;
        visionController.text = vm.data?.visionAndMission ?? '';
      } else {
        error.value = res.message ?? AppStrings.somethingWentWrong;
        commonSnackBar(message: error.value);
      }
    } catch (e) {
      error.value = e.toString();
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  bool validate() {
    final text = visionController.text.trim();
    if (text.isEmpty) {
      commonSnackBar(message: AppStrings.hospitalCtrlVisionMissionRequired.tr);
      return false;
    }
    if (text.length > maxLen) {
      commonSnackBar(message: AppStrings.hospitalCtrlMaxLengthChars.trParams({'count': '$maxLen'}));
      return false;
    }
    return true;
  }

  Future<void> saveOrUpdate() async {
    if (!validate()) return;
    try {
      isSaving.value = true;
      final body = {
        "visionAndMission": visionController.text.trim(),
        "hospitalId": hospitalIDGlobal,
      };

      if (data.value == null || (data.value?.id?.isEmpty ?? true)) {
        final ResponseModel res = await _repo.create(body: body);
        if (res.isSuccess) {
          final VisionMissionRes vm = VisionMissionRes.fromJson(res.response?.data);
          data.value = vm.data;
          commonSnackBar(message: AppStrings.hospitalCtrlSavedSuccessfully.tr);
        } else {
          commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        }
      } else {
        final ResponseModel res = await _repo.update(id: data.value!.id!, body: {"visionAndMission": body["visionAndMission"]});
        if (res.isSuccess) {
          final VisionMissionRes vm = VisionMissionRes.fromJson(res.response?.data);
          data.value = vm.data;
          commonSnackBar(message: AppStrings.hospitalCtrlUpdatedSuccessfully.tr);
        } else {
          commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}
