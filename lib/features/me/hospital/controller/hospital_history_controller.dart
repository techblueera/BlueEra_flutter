import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_history_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_history_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalHistoryController extends GetxController {
  final HospitalHistoryRepo _repo = HospitalHistoryRepo();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isFormValid = false.obs;
  final error = ''.obs;
  final data = Rxn<HospitalHistoryData>();
  final historyController = TextEditingController();
  final selectedImage = Rxn<File>();
  String initialImageUrl = '';
  final int maxLen = 3000;
  HospitalHistoryController();

  @override
  void onInit() {
    super.onInit();
    historyController.addListener(validate);
    fetch();
  }

  @override
  void onClose() {
    historyController.removeListener(validate);
    historyController.dispose();
    super.onClose();
  }

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      error.value = '';
      final ResponseModel res = await _repo.get();
      if (res.isSuccess) {
        final HospitalHistoryRes hr =
            HospitalHistoryRes.fromJson(res.response?.data);
        data.value = hr.data;
        historyController.text = hr.data?.history ?? '';
        initialImageUrl = hr.data?.imageUrl ?? '';
        validate();
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

  void validate() {
    final text = historyController.text.trim();
    bool hasValidChars = RegExp(r'[a-zA-Z0-9]').hasMatch(text);
    isFormValid.value = text.isNotEmpty && text.length <= maxLen && hasValidChars;
  }

  Future<void> saveOrUpdate() async {
    validate();
    if (!isFormValid.value) {
      commonSnackBar(
          message: historyController.text.trim().isEmpty
              ? 'Please enter history description'
              : 'Please enter a valid history description (only punctuation/spaces are not allowed)');
      return;
    }
    try {
      isSaving.value = true;
      final imageUrl = await _resolveImageUrl();
      if (imageUrl == null) return; // upload failed, snackbar already shown

      final body = {
        "history": historyController.text.trim(),
        "imageUrl": imageUrl,
        "hospitalId": hospitalIDGlobal,
      };

      final existingId = data.value?.id;
      final isCreate = existingId == null || existingId.isEmpty;
      final ResponseModel res = isCreate
          ? await _repo.create(body: body)
          : await _repo.update(id: existingId, body: body);

      if (res.isSuccess) {
        final hr = HospitalHistoryRes.fromJson(res.response?.data);
        data.value = hr.data;
        initialImageUrl = hr.data?.imageUrl ?? '';
        commonSnackBar(
            message: isCreate
                ? AppStrings.hospitalCtrlSaved.tr
                : AppStrings.hospitalCtrlUpdated.tr);
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

  /// Uploads [selectedImage] if the user picked a new one; otherwise returns
  /// the existing URL. Returns `null` (and shows a snackbar) on upload failure
  /// so the caller can abort save.
  Future<String?> _resolveImageUrl() async {
    if (selectedImage.value == null) return initialImageUrl;
    final uploadResult = await S3UploadService.uploadFile(selectedImage.value!);
    if (uploadResult.isSuccess) return uploadResult.url;
    commonSnackBar(
        message: uploadResult.message);
    isSaving.value = false;
    return null;
  }
}
