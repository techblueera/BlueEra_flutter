import 'package:BlueEra/core/api/model/get_resume_data_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EducationController extends GetxController {
  final qualification = ''.obs;
  final school = ''.obs;
  final board = ''.obs;
  final year = ''.obs;
  final score = ''.obs;
  final isFormValid = false.obs;
  final educationList = <Map<String, String>>[].obs;

  RxnString editingId = RxnString();

  // Define TextEditingController for form fields
  final schoolController = TextEditingController();
  final boardController = TextEditingController();
  final yearController = TextEditingController();
  final scoreController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    // Listen and update reactive variables on controller text change for validation
    schoolController.addListener(() {
      school.value = schoolController.text;
      validate();
    });
    boardController.addListener(() {
      board.value = boardController.text;
      validate();
    });
    yearController.addListener(() {
      year.value = yearController.text;
      validate();
    });
    scoreController.addListener(() {
      score.value = scoreController.text;
      validate();
    });
  }

  @override
  void onClose() {
    schoolController.dispose();
    boardController.dispose();
    yearController.dispose();
    scoreController.dispose();
    super.onClose();
  }

  void validate() {
    isFormValid.value = qualification.value.trim().isNotEmpty &&
        school.value.trim().isNotEmpty &&
        board.value.trim().isNotEmpty &&
        year.value.trim().length == 4 &&
        score.value.trim().isNotEmpty;
  }

  void clearAll() {
    qualification.value = '';
    school.value = '';
    board.value = '';
    year.value = '';
    score.value = '';
    editingId.value = null;
    schoolController.clear();
    boardController.clear();
    yearController.clear();
    scoreController.clear();
    validate();
  }

  void setEducationListFromModel(List<Education>? education) {
    educationList.clear();

    if (education == null || education.isEmpty) {
      return;
    }

    for (final edu in education) {
      final hasData = (edu.highestQualification != null &&
              edu.highestQualification!.trim().isNotEmpty) ||
          (edu.schoolOrCollegeName != null &&
              edu.schoolOrCollegeName!.trim().isNotEmpty);

      if (!hasData) {
        continue;
      }

      educationList.add({
        'title': edu.passingYear != null && edu.passingYear!.isNotEmpty
            ? "Passed Out: ${edu.passingYear}"
            : '',
        'subtitle1': edu.highestQualification ?? '',
        'subtitle2': edu.boardName ?? '',
        'subtitle3': edu.percentage != null && edu.percentage!.isNotEmpty
            ? "Percentage: ${edu.percentage}"
            : '',
        'trailing': edu.schoolOrCollegeName ?? '',
        '_id': edu.id ?? '',
      });
    }
  }

  void setEditFieldsFromCard(Map<String, dynamic> item) {
    editingId.value = item['_id'] ?? '';

    qualification.value = item['subtitle1'] ?? '';

    schoolController.text = item['trailing'] ?? '';
    school.value = schoolController.text;

    boardController.text = item['subtitle2'] ?? '';
    board.value = boardController.text;
    if (item['title'] != null &&
        item['title'].toString().contains("Passed Out:")) {
      final rawYear =
          item['title'].toString().replaceAll("Passed Out:", "").trim();
      yearController.text = rawYear;
      year.value = rawYear;
    } else {
      yearController.text = '';
      year.value = '';
    }
    if (item['subtitle3'] != null &&
        item['subtitle3'].toString().contains("Percentage:")) {
      final rawScore =
          item['subtitle3'].toString().replaceAll("Percentage:", "").trim();

      final cleanedScore = rawScore.endsWith('%')
          ? rawScore.substring(0, rawScore.length - 1).trim()
          : rawScore;

      scoreController.text = cleanedScore;
      score.value = cleanedScore;
    } else {
      scoreController.text = '';
      score.value = '';
    }
  }

  Future<void> deleteEducation(String id) async {
    final res = await ResumeRepo().deleteEducation(id: id);
    if (res.isSuccess) {
      educationList.removeWhere((element) => element['_id'] == id);
      if (editingId.value == id) {
        clearAll();
      }

      editingId.value = null;
      await callAPIGetResume();

      commonSnackBar(message: AppStrings.educationDeleted);
    } else {
      commonSnackBar(message: res.message ?? AppStrings.educationDeleteFailed);
    }
  }

  Future<void> saveEducation(Map<String, dynamic> params) async {
    if (!isFormValid.value) return;

    if (editingId.value == null) {
      // Add education
      final res = await ResumeRepo().addEducation(params: params);
      if (res.isSuccess) {
        // await fetchEducationDetails();
        clearAll();
        Get.back();
        await callAPIGetResume();

        commonSnackBar(message: AppStrings.educationAdded);
      } else {
        commonSnackBar(message: res.message ?? AppStrings.educationAddError);
      }
    } else {
      // Update education
      final res = await ResumeRepo()
          .updateEducation(id: editingId.value!, params: params);
      if (res.isSuccess) {
        // await fetchEducationDetails();
        clearAll();
        editingId.value = null;
        Get.back();
        await callAPIGetResume();

        commonSnackBar(message: AppStrings.educationUpdated);
      } else {
        commonSnackBar(message: res.message ?? AppStrings.educationUpdateError);
      }
    }
  }
}
