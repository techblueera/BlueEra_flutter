import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AwardsController extends GetxController {
  final ResumeRepo _repo = ResumeRepo();

  // Form controllers
  final titleController = TextEditingController();
  final issuedByController = TextEditingController();
  final descriptionController = TextEditingController();

  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  final awards = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final selectedAward = Rxn<Map<String, dynamic>>();
  RxnString selectedAwardId = RxnString();
  File? selectedFile;
  String? selectedImageUrl;

  @override
  void onInit() {
    // getAllAwardsApi();
    super.onInit();
  }

  @override
  void onClose() {
    titleController.dispose();
    issuedByController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  // Clear form
  void clearForm() {
    titleController.clear();
    issuedByController.clear();
    descriptionController.clear();
    selectedDate.value = null;
    // selectedAttachment.value = null;
    // selectedAttachmentUrl = null;
       selectedFile = null;
    selectedImageUrl = null;
    selectedAward.value = null;
    selectedAwardId.value = null;
  }

  // Set attachment file
  void setAttachment(File? file) {
    // selectedAttachment.value = file;
    // if (file != null) selectedAttachmentUrl = null;
    
    selectedFile = file;
    if (file != null) selectedImageUrl = null;
  }

  // Parse date from map safely
  DateTime? _parseDateMap(dynamic dateMap) {
    if (dateMap == null || dateMap is! Map) return null;
    final y = _parseInt(dateMap['year']);
    final m = _parseInt(dateMap['month']);
    final d = _parseInt(dateMap['date']);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
    return null;
  }

  int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }

  // Fill form for edit - adapted to achievements style date & image
  void fillFormForEdit(Map<String, dynamic> award) {
    selectedAward.value = award;
    selectedAwardId.value = award['_id'] ?? '';

    titleController.text = award['title'] ?? '';
    issuedByController.text = award['issuedBy'] ?? '';
    descriptionController.text = award['description'] ?? '';

    selectedDate.value = _parseDateMap(award['issuedDate']);

    // // Assign image URL instead of file (no file picked yet)
    // selectedAttachment.value = null;
    // selectedAttachmentUrl = award['attachment'] as String?;
    
    selectedFile = null;
    selectedImageUrl = award['attachment'] as String?;
  }
  /// ADD AWARD
  Future<void> addAwardApi() async {
    if (!_validateForm()) return;
    try {
      isLoading.value = true;
      final date = selectedDate.value;
      if (date == null) {
        commonSnackBar(message:AppStrings.selectValidDate);
        return;
      }
      final response = await _repo.addAward(
        title: titleController.text.trim(),
        issuedBy: issuedByController.text.trim(),
        date: date.day,
        month: date.month,
        year: date.year,
        description: descriptionController.text.trim(),
        attachment: selectedFile,
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.response?.data['message'] ??AppStrings.awardAdded.tr);
        clearForm();
        // await getAllAwardsApi();
      } else {
        commonSnackBar(message: response.response?.data['message'] ??AppStrings.awardAddFailed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// UPDATE AWARD
  Future<void> updateAwardApi() async {
    if (!_validateForm()) return;

    final id = selectedAwardId.value;
    if (id == null || id.isEmpty) {
      commonSnackBar(message: AppStrings.awardIdMissing);
      return;
    }

    try {
      isLoading.value = true;
      final date = selectedDate.value;
      if (date == null) {
        commonSnackBar(message:AppStrings.selectValidDate);
        return;
      }

      final response = await _repo.updateAward(
        id: id,
        title: titleController.text.trim(),
        issuedBy: issuedByController.text.trim(),
        date: date.day,
        month: date.month,
        year: date.year,
        description: descriptionController.text.trim(),
        attachment: selectedFile,
        removeAttachment: selectedFile == null && (selectedImageUrl?.isNotEmpty ?? false),
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.response?.data['message'] ?? AppStrings.awardUpdated);
        clearForm();
        selectedAwardId.value = null;
        // await getAllAwardsApi();
      } else {
        commonSnackBar(message: response.response?.data['message'] ?? AppStrings.awardUpdateFailed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// DELETE AWARD
  Future<void> deleteAwardApi(String id) async {
    try {
      isLoading.value = true;
      final response = await _repo.deleteAward(id: id);
      if (response.isSuccess) {
        commonSnackBar(message: response.response?.data['message'] ?? AppStrings.awardDeleted);
        // await getAllAwardsApi();
      } else {
        commonSnackBar(message: response.response?.data['message'] ??AppStrings.awardDeleteFailed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// VALIDATE FORM
  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.awardEnterTitle);
      return false;
    }
    if (issuedByController.text.trim().isEmpty) {
      commonSnackBar(message:AppStrings.awardEnterIssuedBy);
      return false;
    }
    if (selectedDate.value == null) {
      commonSnackBar(message:AppStrings.awardSelectCompleteDate);
      return false;
    }

    final now = DateTime.now();
    if (selectedDate.value!.isAfter(now)) {
      commonSnackBar(message: AppStrings.awardDateFuture);
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.awardEnterDescription);
      return false;
    }

    return true;
  }
}

