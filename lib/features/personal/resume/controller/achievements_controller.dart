import 'dart:io';

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
  void onInit() {
    super.onInit();
    // fetchAchievements();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    courseController.dispose();
    super.onClose();
  }

  // Future<void> fetchAchievements() async {
  //   isLoading.value = true;
  //   try {
  //     final res = await _repo.getAllAchievements(params: {});
  //     if (res.isSuccess && res.response?.data != null) {
  //       final rawList = res.response!.data as List<dynamic>;
  //       achievementsList.assignAll(
  //         rawList.map((e) {
  //           final item = e as Map<String, dynamic>;
  //           final dateMap = item['achieveDate'] as Map<String, dynamic>?;
  //           String formattedDate = "";
  //           if (dateMap != null) {
  //             final months = [
  //               '',
  //               'January',
  //               'February',
  //               'March',
  //               'April',
  //               'May',
  //               'June',
  //               'July',
  //               'August',
  //               'September',
  //               'October',
  //               'November',
  //               'December'
  //             ];
  //             final int? month = dateMap['month'] is int
  //                 ? dateMap['month']
  //                 : int.tryParse(dateMap['month']?.toString() ?? "");
  //             final int? year = dateMap['year'] is int
  //                 ? dateMap['year']
  //                 : int.tryParse(dateMap['year']?.toString() ?? "");
  //             if (month != null && year != null) {
  //               formattedDate = months[month] + " " + year.toString();
  //             }
  //           }
  //           return {
  //             '_id': item['_id'],
  //             'title': item['title'] ?? '',
  //             'subtitle1': formattedDate,
  //             'subtitle2': item['description'] ?? '',
  //             'document':
  //                 item['attachment'] != null ? [item['attachment']] : [],
  //             'achieveDate': item['achieveDate'],
  //           };
  //         }).toList(),
  //       );
  //     } else {
  //       achievementsList.clear();
  //     }
  //   } catch (e) {
  //     achievementsList.clear();
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

// Future<void> getAchievementById(String id) async {
//   isLoading.value = true;
//   try {
//     final res = await _repo.getAchievementById(id: id, params: {});
//     if (res.isSuccess && res.response?.data != null) {
//       final data = res.response!.data as Map<String, dynamic>;

//       titleController.text = data['title'] ?? '';
//       descriptionController.text = data['description'] ?? '';

//       final dateMap = data['achieveDate'] as Map<String, dynamic>?;
//       if (dateMap != null) {
//         final year = dateMap['year'] is int ? dateMap['year'] : int.tryParse(dateMap['year']?.toString() ?? "");
//         final month = dateMap['month'] is int ? dateMap['month'] : int.tryParse(dateMap['month']?.toString() ?? "");
//         final day = dateMap['date'] is int ? dateMap['date'] : int.tryParse(dateMap['date']?.toString() ?? "");
//         if (year != null && month != null && day != null) {
//           selectedDate.value = DateTime(year, month, day);
//         }
//       }

//       selectedImageUrl = data['attachment'] as String?;
//       selectedFile = null; // no local file picked yet
//     }
//   } finally {
//     isLoading.value = false;
//   }
// }
  Future<ResponseModel> addAchievement() async {
    isLoading.value = true;
    try {
      final date = selectedDate.value;
      if (date == null) {
        commonSnackBar(message: "Please select date");
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
                "Achievement added successfully");
        // await fetchAchievements();
        clearForm();
      } else {
        commonSnackBar(message: res.message ?? "Failed to add achievement");
      }
      return res;
    } catch (e) {
      commonSnackBar(message: "An error occurred");
      return ResponseModel();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAchievement(String id) async {
    isLoading.value = true;
    try {
      print("Updating achievement with:");
      print("Title: ${titleController.text}");
      print("Description: ${descriptionController.text}");
      print("Date: ${selectedDate.value}");
      print("Has file: ${selectedFile != null}");

      final date = selectedDate.value;
      if (date == null) {
        commonSnackBar(message: "Please select date");
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
        commonSnackBar(message: "Achievement updated successfully");
        // await fetchAchievements();
        clearForm();
      } else {
        commonSnackBar(message: res.message ?? "Failed to update achievement");
      }
    } catch (e) {
      commonSnackBar(message: "An error occurred");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAchievement(String id) async {
    isLoading.value = true;
    try {
      final res = await _repo.deleteAchievement(id: id);
      if (res.isSuccess) {
        commonSnackBar(
            message: res.response?.data['message'] ?? "Achievement deleted");
        // await fetchAchievements();
      } else {
        commonSnackBar(message: res.message ?? "Failed to delete achievement");
      }
    } catch (e) {
      commonSnackBar(message: "An error occurred");
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
