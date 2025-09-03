import 'dart:io';

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

  // Use unified Rx<DateTime?> for date handling
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  final awards = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final selectedAward = Rxn<Map<String, dynamic>>();
  // final selectedAttachment = Rxn<File>();
  RxnString selectedAwardId = RxnString();
  // String? selectedAttachmentUrl; // For prefilled attachment URL
    // Replace Rxn<File> with simple File? variable
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

  /// GET ALL AWARDS
  // Future<void> getAllAwardsApi() async {
  //   try {
  //     isLoading.value = true;
  //     final response = await _repo.getAllAwards(params: {});
  //     if (response.isSuccess) {
  //       final data = response.response?.data;
  //       if (data != null && data['data'] is List) {
  //         awards.value = List<Map<String, dynamic>>.from(data['data']);
  //       }
  //     } else {
  //       awards.clear();
  //       commonSnackBar(message: response.response?.data['message'] ?? "Failed to fetch awards");
  //     }
  //   } catch (e) {
  //     awards.clear();
  //     commonSnackBar(message: "Failed to fetch awards");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  /// ADD AWARD
  Future<void> addAwardApi() async {
    if (!_validateForm()) return;
    try {
      isLoading.value = true;
      final date = selectedDate.value;
      if (date == null) {
        commonSnackBar(message: "Please select a valid date");
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
        commonSnackBar(message: response.response?.data['message'] ?? 'Award added successfully!');
        clearForm();
        // await getAllAwardsApi();
      } else {
        commonSnackBar(message: response.response?.data['message'] ?? "Failed to add award");
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
      commonSnackBar(message: "Award ID missing for update.");
      return;
    }

    try {
      isLoading.value = true;
      final date = selectedDate.value;
      if (date == null) {
        commonSnackBar(message: "Please select a valid date");
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
        commonSnackBar(message: response.response?.data['message'] ?? 'Award updated successfully!');
        clearForm();
        selectedAwardId.value = null;
        // await getAllAwardsApi();
      } else {
        commonSnackBar(message: response.response?.data['message'] ?? "Failed to update award");
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
        commonSnackBar(message: response.response?.data['message'] ?? "Award deleted");
        // await getAllAwardsApi();
      } else {
        commonSnackBar(message: response.response?.data['message'] ?? "Failed to delete award");
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// VALIDATE FORM
  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      commonSnackBar(message: 'Please enter award title');
      return false;
    }
    if (issuedByController.text.trim().isEmpty) {
      commonSnackBar(message: 'Please enter issued by');
      return false;
    }
    if (selectedDate.value == null) {
      commonSnackBar(message: 'Please select complete date');
      return false;
    }

    final now = DateTime.now();
    if (selectedDate.value!.isAfter(now)) {
      commonSnackBar(message: 'Award date cannot be in the future');
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      commonSnackBar(message: 'Please enter description');
      return false;
    }

    return true;
  }
}

