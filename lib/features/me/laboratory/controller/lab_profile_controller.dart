import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabProfileController extends GetxController {
  final LabProfileRepo _repo = LabProfileRepo();

  var isLoading = false.obs;
  var isValid = false.obs;
  var hasExisting = false.obs;
  // RxString labId = "698b225f2c44cc586fa1d5c2".obs;

  final descController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  void validateForm() {
    final text = descController.text.trim();
    isValid.value = text.isNotEmpty && text.length <= 500;
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      ResponseModel res = await _repo.getProfile();
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        final desc = data?['description'];
        descController.text = desc is String ? desc : "";
        hasExisting.value = descController.text.trim().isNotEmpty;
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
      validateForm();
    }
  }

  Future<bool> save() async {
    isLoading.value = true;
    try {
      final payload = {"description": descController.text.trim()};
      ResponseModel res = hasExisting.value
          ? await _repo.putDescription(payload)
          : await _repo.postDescription(payload);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labDescriptionSaved.tr);
        return true;
      } else {
        commonSnackBar(message: res.response?.data['message'] ?? AppStrings.labFailedToSave.tr);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
