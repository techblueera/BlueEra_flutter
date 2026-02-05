import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/model/certification_model.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CertificationsController extends GetxController {
  final ResumeRepo _repo = ResumeRepo();

  final titleController = TextEditingController();
  final issuingOrgController = TextEditingController();
  int? selectedDay, selectedMonth, selectedYear;

  final certifications =
      <Map<String, dynamic>>[].obs; // Store list of maps directly
  final RxList<Map<String, dynamic>> certificationsList =
      <Map<String, dynamic>>[].obs;

  final isLoading = false.obs;
  final selectedCertification = Rxn<Certification>();
  final selectedAttachment = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    // getAllCertifications();
  }

  @override
  void onClose() {
    titleController.dispose();
    issuingOrgController.dispose();
    super.onClose();
  }

  void clearForm() {
    titleController.clear();
    issuingOrgController.clear();
    selectedAttachment.value = null;
    selectedCertification.value = null;
  }

  void setAttachment(File? file) {
    selectedAttachment.value = file;
  }

  void fillFormForEdit(Certification certification) {
    selectedCertification.value = certification;
    titleController.text = certification.title;
    issuingOrgController.text = certification.issuingOrg;
  }

  Future<void> addCertification(Map<String, dynamic> params,
      {String? photoPath}) async {
    final res =
        await _repo.addCertification(params: params, photoPath: photoPath);
    if (res.isSuccess) {
      commonSnackBar(message: AppStrings.certificationAdded);
      await callAPIGetResume();

      // await getAllCertifications();
    } else {
      commonSnackBar(message: res.message ??AppStrings.certificationAddFailed);
    }
  }

  Future<void> updateCertification(String id, Map<String, dynamic> params,
      {String? photoPath}) async {
    final res = await _repo.updateCertification(
        id: id, params: params, photoPath: photoPath);
    if (res.isSuccess) {
      commonSnackBar(message: AppStrings.certificationUpdated);
     await callAPIGetResume();
      // await getAllCertifications();
    } else {
      commonSnackBar(message: res.message ?? AppStrings.certificationUpdateFailed);
    }
  }

  Future<void> deleteCertification(String id,int index) async {
    final res = await _repo.deleteCertification(id: id);
    if (res.isSuccess) {
      commonSnackBar(message: AppStrings.certificationDeleted);
      certificationsList.removeAt(index);
      await callAPIGetResume();

      // await getAllCertifications();
    } else {
      commonSnackBar(message: res.message ?? AppStrings.certificationDeleteFailed);
    }
  }

  String formatMonthYear(Map? dateMap) {
    if (dateMap == null) return '';
    final m = dateMap['month'];
    final y = dateMap['year'];
    if (m == null || y == null) return '';
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final monthName = (m is int && m >= 1 && m <= 12)
        ? months[m]
        : (int.tryParse(m.toString()) != null &&
                int.parse(m.toString()) >= 1 &&
                int.parse(m.toString()) <= 12)
            ? months[int.parse(m.toString())]
            : '';
    return monthName.isNotEmpty ? '$monthName $y' : '$m/$y';
  }


  void fillForm(Map<String, dynamic> item) {
    titleController.text = item['title'] ?? '';
    issuingOrgController.text = item['issuingOrg'] ?? '';
    // handle date (ensure item['certificateDate'] exists as a Map)
    final dateMap = item['certificateDate'];
    if (dateMap != null && dateMap is Map) {
      selectedDay = _safeInt(dateMap['date']);
      selectedMonth = _safeInt(dateMap['month']);
      selectedYear = _safeInt(dateMap['year']);
    } else {
      selectedDay = selectedMonth = selectedYear = null;
    }
    // handle image
    final docs = (item['document'] as List<dynamic>?)?.cast<String>();
    selectedAttachment.value =
        (docs != null && docs.isNotEmpty) ? File(docs.first) : null;
  }

// helper function
  int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
