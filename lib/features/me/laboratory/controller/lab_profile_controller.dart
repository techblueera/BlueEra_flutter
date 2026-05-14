import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Edits the laboratory's free-text `description` field. Creates the
/// profile on first save and updates it thereafter.
class LabProfileController extends GetxController {
  final LabProfileRepo _repo = LabProfileRepo();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isValid = false.obs;

  /// `true` once a profile has been loaded from the server, so [save]
  /// chooses PUT instead of POST.
  final RxBool hasExisting = false.obs;

  final descController = TextEditingController();

  static const int _maxDescLength = 500;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  @override
  void onClose() {
    descController.dispose();
    super.onClose();
  }

  void validateForm() {
    final text = descController.text.trim();
    isValid.value = text.isNotEmpty && text.length <= _maxDescLength;
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getProfile();
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        final desc = data?['description'];
        descController.text = desc is String ? desc : '';
        hasExisting.value = descController.text.trim().isNotEmpty;
      }
    } catch (e) {
      logs("LabProfileController.fetchProfile ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
      validateForm();
    }
  }

  Future<bool> save() async {
    try {
      isSaving.value = true;
      final payload = {"description": descController.text.trim()};
      final ResponseModel res = hasExisting.value
          ? await _repo.putDescription(payload)
          : await _repo.postDescription(payload);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labDescriptionSaved.tr);
        return true;
      }
      commonSnackBar(
          message: res.response?.data['message'] ??
              AppStrings.labFailedToSave.tr);
      return false;
    } catch (e) {
      logs("LabProfileController.save ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
