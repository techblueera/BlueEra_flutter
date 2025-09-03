import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SkillsController extends GetxController {
  final ResumeRepo _repo = ResumeRepo();
  final skillsList = <String>[].obs;
  final skillController = TextEditingController();
  final isValidate = false.obs;

  @override
  void onInit() {
    skillController.addListener(validateForm);
    super.onInit();
  }

  @override
  void onClose() {
    skillController.dispose();
    super.onClose();
  }

  void validateForm() {
    isValidate.value = skillsList.isNotEmpty;
  }

  void addSkill(String skill) {
    if (skill.isNotEmpty && !skillsList.contains(skill)) {
      skillsList.add(skill);
      skillController.clear();
      validateForm();
    }
  }

  void removeSkill(String skill) {
    skillsList.remove(skill);
    validateForm();
  }


  void setSkillsFromModel(List<String>? skills) {
    skillsList.clear();
    if (skills != null && skills.isNotEmpty) {
      skillsList.addAll(skills.whereType<String>());
    }
    print("List of skills is⭐⭐⭐⭐⭐ ${skillsList}");
    validateForm();
  }
  // Future<void> getSkillsApi() async {
  //   try {
  //     final response = await _repo.getSkills();
  //     if (response.isSuccess) {
  //       final getSkillsData = response.response!.data;
  //       skillsList.clear();

  //       if (getSkillsData is Map && getSkillsData[ApiKeys.skills] != null) {
  //         final skills = getSkillsData[ApiKeys.skills];
  //         if (skills is List) {
  //           skillsList.addAll(skills.cast<String>());
  //         }
  //       }
  //       validateForm();
  //     }
  //   } catch (e) {
  //     print("ERROR: $e");
  //   }
  // }

  Future<void> addSkillsApi() async {
    final params = {ApiKeys.skills: skillsList.toList()};
    try {
      final response = await _repo.addSkills(params: params);
      if (response.isSuccess) {
        commonSnackBar(message: "${response.response?.data['message'] ?? AppStrings.success}");
        Get.back();
      } else {
        commonSnackBar(message: "${response.response?.data['message'] ?? AppStrings.somethingWentWrong}");
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> deleteSkillsApi(String skillToDelete) async {
    try {
      final response = await _repo.deleteSkills(skill: skillToDelete);
      if (response.isSuccess) {
        commonSnackBar(message: "${response.response?.data['message'] ?? AppStrings.success}");

        skillsList.removeWhere((skill) => skill == skillToDelete);

        validateForm();
      } else {
        commonSnackBar(message: "${response.response?.data['message'] ?? AppStrings.somethingWentWrong}");
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }


  Future<void> saveSkills() async {
    if (skillsList.isNotEmpty) {
      await addSkillsApi();
    }
  }

}