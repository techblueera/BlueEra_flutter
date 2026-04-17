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
      if (historyController.text.trim().isEmpty) {
        commonSnackBar(message: 'Please enter history description');
      } else {
        commonSnackBar(message: 'Please enter a valid history description (only punctuation/spaces are not allowed)');
      }
      return;
    }
    try {
      isSaving.value = true;
      String imageUrl = initialImageUrl;
      if (selectedImage.value != null) {
        final UploadResult? uploadResult =
            await S3UploadService.uploadFile(selectedImage.value!);
        if (uploadResult != null && uploadResult.isSuccess) {
          imageUrl = uploadResult.url;
        } else {
          commonSnackBar(
              message: uploadResult?.message ?? AppStrings.somethingWentWrong);
          isSaving.value = false;
          return;
        }
      }
      final body = {
        "history": historyController.text.trim(),
        "imageUrl": imageUrl,
        "hospitalId": hospitalIDGlobal,
      };
      if (data.value == null || (data.value?.id?.isEmpty ?? true)) {
        final ResponseModel res = await _repo.create(body: body);
        if (res.isSuccess) {
          final HospitalHistoryRes hr =
              HospitalHistoryRes.fromJson(res.response?.data);
          data.value = hr.data;
          initialImageUrl = hr.data?.imageUrl ?? '';
          commonSnackBar(message: AppStrings.hospitalCtrlSaved.tr);
          Get.back();
        } else {
          commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        }
      } else {
        final ResponseModel res =
            await _repo.update(id: data.value!.id!, body: body);
        if (res.isSuccess) {
          final HospitalHistoryRes hr =
              HospitalHistoryRes.fromJson(res.response?.data);
          data.value = hr.data;
          initialImageUrl = hr.data?.imageUrl ?? '';
          commonSnackBar(message: AppStrings.hospitalCtrlUpdated.tr);
          Get.back();
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
