import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../repo/resume_repo.dart';

class AdditionalInfoController extends GetxController {
  final ResumeRepo repo = ResumeRepo();
  final RxList<Map<String, dynamic>> additionalInfoList =
      <Map<String, dynamic>>[].obs;

  final getResumeController = Get.find<ProfilePicController>();

  /// Form fields
  final titleController = TextEditingController();
  final infoController = TextEditingController();
  final descController = TextEditingController();
  int? selectedDay, selectedMonth, selectedYear;
  String? selectedImagePath;
  String? editingId;

  final isAddDate = false.obs;
  final isAddPhoto = false.obs;
  final isAddMoreTextBox = false.obs;
  final moreTextController = TextEditingController();

  // Future<void> fetchAdditionalInfos() async {
  //   final res = await repo.fetchAllAdditionalInfo();
  //   if (res.isSuccess && res.response?.data != null) {
  //     final items = (res.response!.data as List<dynamic>).map((e) {
  //       final item = e as Map<String, dynamic>;
  //       return {
  //         '_id': item['_id'],
  //         'title': item['title'] ?? '',
  //         'subtitle1':
  //             formatDate(item['infoDate']), // date shown after title in card
  //         'subtitle2': item['info'] ?? '', // additional description below title
  //         'subtitle3':
  //             item['additionalDesc'] ?? '', // more text box content at last
  //         'document': (item['photoURL'] != null &&
  //                 item['photoURL'].toString().isNotEmpty)
  //             ? [item['photoURL']]
  //             : [],
  //       };
  //     }).toList();
  //     additionalInfoList.assignAll(items);
  //   } else {
  //     additionalInfoList.clear();
  //   }
  // }

  Future<void> updateAdditionalInfo(String id, Map<String, dynamic> inputParams,
      {String? photoPath, Map<String, dynamic>? date}) async {
    final res = await repo.updateAdditionalInfo(
      id,
      inputParams,
      photoPath: photoPath,
      date: date,
    );
    if (res.isSuccess) {
      commonSnackBar(message: "Additional Information updated");
      // await fetchAdditionalInfos();

      await getResumeController.getMyResume();
    } else {
      commonSnackBar(
          message: res.message ?? "Failed to update additional info");
    }
  }

  Future<void> addAdditionalInfo(Map<String, dynamic> inputParams,
      {String? photoPath, Map<String, dynamic>? date}) async {
    final res = await repo.addAdditionalInfo(
      inputParams,
      photoPath: photoPath,
      date: date,
    );
    if (res.isSuccess) {
      commonSnackBar(message: "Additional Information added");
      await getResumeController.getMyResume();
    } else {
      commonSnackBar(message: res.message ?? "Failed to add additional info");
    }
  }

  Future<void> deleteAdditionalInfo(String id) async {
    final res = await repo.deleteAdditionalInfo(id);
    if (res.isSuccess) {
      commonSnackBar(message: "Additional Information deleted");
      // await fetchAdditionalInfos();

      await getResumeController.getMyResume();
    }
  }

  String formatDate(Map? dateMap) {
    if (dateMap == null) return '';
    final d = dateMap['date'];
    final m = dateMap['month'];
    final y = dateMap['year'];
    if (d != null && m != null && y != null) return '$d/$m/$y';
    return '';
  }

  @override
  void onClose() {
    titleController.dispose();
    infoController.dispose();
    descController.dispose();
    moreTextController.dispose();
    super.onClose();
  }

  void clearForm() {
    titleController.clear();
    infoController.clear();
    descController.clear();
    moreTextController.clear();
    selectedDay = null;
    selectedMonth = null;
    selectedYear = null;
    selectedImagePath = null;
    editingId = null;
    isAddDate.value = false;
    isAddPhoto.value = false;
    isAddMoreTextBox.value = false;
  }

  void fillForm(Map<String, dynamic> item) {
    titleController.text = item['title'] ?? '';
    infoController.text = item['subtitle2'] ?? '';
    descController.text = item['subtitle3'] ?? '';
    moreTextController.text = item['subtitle3'] ?? '';

    final dateString = item['subtitle1'] ?? '';
    if (dateString.isNotEmpty) {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        selectedDay = int.tryParse(parts[0]);
        selectedMonth = int.tryParse(parts[1]);
        selectedYear = int.tryParse(parts[2]);
        isAddDate.value = true;
      } else {
        isAddDate.value = false;
      }
    } else {
      isAddDate.value = false;
    }
    final docs = (item['document'] as List<dynamic>?)?.cast<String>();
    selectedImagePath = (docs != null && docs.isNotEmpty) ? docs.first : null;
    isAddPhoto.value = (selectedImagePath ?? '').isNotEmpty;

    isAddMoreTextBox.value = (descController.text.trim().isNotEmpty);
    editingId = item['_id'];
  }
}
