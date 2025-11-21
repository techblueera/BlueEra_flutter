import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/response_model.dart';

class AchievementsController extends GetxController {
  final ResumeRepo _repo = ResumeRepo();

  final RxList<Map<String, dynamic>> achievementsList =
      <Map<String, dynamic>>[].obs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final courseController = TextEditingController();
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  File? selectedFile;
  String? selectedImageUrl;
  final isLoading = false.obs;

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    courseController.dispose();
    super.onClose();
  }
  Future<ResponseModel> addAchievement() async {
    isLoading.value = true;
    try {
      final date = selectedDate.value;
      if (date == null) {
        commonSnackBar(message:AppStrings.pleaseSelectDate);
        return ResponseModel();
      }

      final res = await _repo.addAchievement(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          date: date.day,
          month: date.month,
          year: date.year,
          attachment: selectedFile);

      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ??
                AppStrings.achievementAddedSuccess.tr);
        // await fetchAchievements();
        clearForm();
      } else {
        commonSnackBar(message: res.message ?? AppStrings.achievementAddFailed.tr);
      }
      return res;
    } catch (e) {
      commonSnackBar(message: AppStrings.genericError);
      return ResponseModel();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAchievement(String id) async {
    isLoading.value = true;
    try {


      final date = selectedDate.value;
      if (date == null) {
        commonSnackBar(message: AppStrings.pleaseSelectDate);
        return;
      }

      final res = await _repo.updateAchievement(
        id: id,
        title: titleController.text,
        description: descriptionController.text,
        date: date.day,
        month: date.month,
        year: date.year,
        attachment: selectedFile,
      );

      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.achievementUpdateSuccess);
        // await fetchAchievements();
        clearForm();
      } else {
        commonSnackBar(message: res.message ?? AppStrings.achievementUpdateFailed.tr);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.genericError);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAchievement(String id,int index) async {
    isLoading.value = true;
    try {
      final res = await _repo.deleteAchievement(id: id);
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? AppStrings.achievementDeleteSuccess.tr);
        // await fetchAchievements();
        achievementsList.removeAt(index);

      } else {
        commonSnackBar(message: res.message ?? AppStrings.achievementDeleteFailed.tr);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.genericError);
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    courseController.clear();
    selectedDate.value = null;
    selectedFile = null;
  }

  void fillForm(Map<String, dynamic> item) {
    titleController.text = item['title'] ?? '';
    descriptionController.text = item['subtitle2'] ?? '';
    final dateMap = item['achieveDate'];
    if (dateMap != null && dateMap is Map<String, dynamic>) {
      final int? year = dateMap['year'] is int
          ? dateMap['year']
          : int.tryParse(dateMap['year']?.toString() ?? "");
      final int? month = dateMap['month'] is int
          ? dateMap['month']
          : int.tryParse(dateMap['month']?.toString() ?? "");
      final int? day = dateMap['date'] is int
          ? dateMap['date']
          : int.tryParse(dateMap['date']?.toString() ?? "");
      if (year != null && month != null && day != null) {
        selectedDate.value = DateTime(year, month, day);
      }
    }
    selectedFile = null;
    selectedImageUrl = null;
    if (item['document'] != null &&
        item['document'] is List &&
        (item['document'] as List).isNotEmpty) {
      final docItem = (item['document'] as List).first;
      if (docItem is String && docItem.isNotEmpty) {
        selectedImageUrl = docItem;
      }
    }
  }
}
