import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class QualificationContoller extends GetxController {
  final highestQualification = ''.obs;
  final school = ''.obs;
  final board = ''.obs;
  final year = ''.obs;
  final score = ''.obs;
  final isEducationFormValid = false.obs;
  final educationList = <Map<String, String>>[].obs;
  final RxnString editingId = RxnString();

  final TextEditingController schoolController = TextEditingController();
  final TextEditingController boardController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController scoreController = TextEditingController();
  final getResumeController = Get.find<ProfilePicController>();

  @override
  void onInit() {
    super.onInit();
    // fetchQualficationDetails();
    // getResumeController.getMyResume();
     schoolController.addListener(() {
    school.value = schoolController.text;
    validateEducationForm();
  });

  boardController.addListener(() {
    board.value = boardController.text;
    validateEducationForm();
  });

  yearController.addListener(() {
    year.value = yearController.text;
    validateEducationForm();
  });

  scoreController.addListener(() {
    score.value = scoreController.text;
    validateEducationForm();
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

  void validateEducationForm() {
    isEducationFormValid.value = highestQualification.value.trim().isNotEmpty &&
        school.value.trim().isNotEmpty &&
        board.value.trim().isNotEmpty &&
        year.value.trim().length == 4 &&
        score.value.trim().isNotEmpty;
  }

  void clearEducationFields() {
    highestQualification.value = '';
    school.value = '';
    board.value = '';
    year.value = '';
    score.value = '';
    schoolController.clear();
    boardController.clear();
    yearController.clear();
    scoreController.clear();
  }

  void clearAll() {
    clearEducationFields(); // use the new method
  }

  ApiResponse addEducationResponse = ApiResponse.initial('Initial');

  Future<void> addEducation(Map<String, dynamic> params) async {
    try {
      final res = await ResumeRepo().addEducation(params: params);
      if (res.isSuccess) {
        addEducationResponse = ApiResponse.complete(res);
        await getResumeController.getMyResume();
        Get.back();
        Future.delayed(const Duration(milliseconds: 100), () {
          commonSnackBar(message: "Education added");
        });
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addEducationResponse = ApiResponse.error('Addition failed');
    }
  }



void setEditFieldsFromCard(Map<String, dynamic> item) {
  editingId.value = item['_id'] ?? '';
  
  highestQualification.value = item['title'] ?? '';
  schoolController.text = item['subtitle1'] ?? '';
  school.value = schoolController.text;
  
  boardController.text = item['trailing'] ?? '';
  board.value = boardController.text;
  
  year.value = '';
  if (item['subtitle2'] != null && item['subtitle2'].toString().contains("Passing Year:")) {
    final y = item['subtitle2'].toString().replaceAll("Passing Year:", "").trim();
    yearController.text = y;
    year.value = y;
  }
  
  score.value = '';
  if (item['subtitle3'] != null && item['subtitle3'].toString().contains("Percentage:")) {
    final s = item['subtitle3'].toString().replaceAll("Percentage:", "").trim();
    scoreController.text = s;
    score.value = s;
  }
}

  Future<void> updateEducation(Map<String, dynamic> params) async {
    final id = editingId.value;
    if (id == null || id.isEmpty) return;
    final res = await ResumeRepo().updateEducation(id: id, params: params);
    if (res.isSuccess) {
      // await fetchQualficationDetails();
      editReset();
      Get.back();
      Future.delayed(const Duration(milliseconds: 100), () {
        commonSnackBar(message: "Education updated");
      });
    } else {
      commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
    }
  }

  void editReset() {
    editingId.value = null;
    clearEducationFields(); // <- clean reset after update
  }

  Future<void> deleteEducation(String? id) async {
    if (id != null && id.isNotEmpty) {
      final res = await ResumeRepo().deleteEducation(id: id);
      if (res.isSuccess) {
        await getResumeController.getMyResume();
        clearEducationFields();
        commonSnackBar(message: "Education deleted");
      } else {
        commonSnackBar(message: "Failed to delete education");
      }
    }
  }
}
