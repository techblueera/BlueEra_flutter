import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
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
    // Seed from the already-loaded resume data. getMyResume() may have run
    // (in CreateResumeScreen.initState) before this controller was registered,
    // in which case _updateSkillsController skipped us. Pull the latest skills
    // straight from the resume model so we are correct as soon as we exist.
    _seedFromResumeData();
    super.onInit();
  }

  void _seedFromResumeData() {
    try {
      if (!Get.isRegistered<ProfilePicController>()) return;
      final resumeData = Get.find<ProfilePicController>().getResumeData.value;
      setSkillsFromModel(resumeData.skills);
    } catch (e) {
      print('Error seeding SkillsController from resume data: $e');
    }
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


  void setSkillsFromModel(List<dynamic>? skills) {
    skillsList.clear();
    if (skills != null && skills.isNotEmpty) {
      final parsed = skills
          .map((e) {
            if (e is String) return e;
            if (e is Map) {
              return (e['skill'] ?? e['name'] ?? '').toString();
            }
            return e?.toString() ?? '';
          })
          .where((e) => e.trim().isNotEmpty)
          .toList();
      skillsList.addAll(parsed);
    }
    validateForm();
  }

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