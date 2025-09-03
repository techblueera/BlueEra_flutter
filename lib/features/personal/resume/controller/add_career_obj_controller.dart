import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CareerObjectiveController extends GetxController {
  final ResumeRepo _repo = ResumeRepo();
  final careerObjective = ''.obs;
  final maxLength = 200;
  final careerObjectiveController = TextEditingController();

  @override
  void onInit() {
    // TODO: implement onInit
    careerObjectiveController.addListener(() {
      careerObjective.value = careerObjectiveController.text;
    });
    // getCareerObjectiveApi();
    super.onInit();
  }

  @override
  void onClose() {
    careerObjectiveController.dispose();
    super.onClose();
  }

  // Future<void> getCareerObjectiveApi() async {
  //   try {
  //     final response = await _repo.getCareerObjective();
  //     if (response.isSuccess) {
  //       final getCareerObjectiveData = response.response!.data;
  //       String newObj = "";
  //       if (getCareerObjectiveData is Map &&
  //           getCareerObjectiveData[ApiKeys.careerObjective] != null) {
  //         newObj = getCareerObjectiveData[ApiKeys.careerObjective];
  //       } else if (getCareerObjectiveData is String) {
  //         newObj = getCareerObjectiveData;
  //       }

  //       _lastCareerObjective = newObj;
  //       careerObjective.value = newObj;
  //       if (getCareerObjectiveData is Map &&
  //           getCareerObjectiveData[ApiKeys.careerObjective] != null) {
  //         careerObjective.value =
  //             getCareerObjectiveData[ApiKeys.careerObjective];
  //       } else if (getCareerObjectiveData is String) {
  //         careerObjective.value = getCareerObjectiveData;
  //       }
  //     }
  //   } catch (e) {
  //     print("ERROR: $e");
  //   }
  // }

  Future<void> addCareerObjectiveApi() async {
    final params = {ApiKeys.careerObjective: careerObjectiveController.text};
    try {
      final response = await _repo.addCareerObjective(params: params);
      if (response.isSuccess) {
        commonSnackBar(
            message:
                "${response.response?.data['message'] ?? "Career Objective added successfully"}");
        // await getCareerObjectiveApi();
      } else {
        commonSnackBar(
            message:
                "${response.response?.data['message'] ?? AppStrings.somethingWentWrong}");
      }
    } catch (e) {
      // Handle error, show message
    }
  }

  Future<void> updateCareerObjectiveApi() async {
    final params = {ApiKeys.careerObjective: careerObjectiveController.text};
    try {
      final response = await _repo.updateCareerObjective(params: params);
      if (response.isSuccess) {
        commonSnackBar(
            message:
                "${response.response?.data['message'] ?? "Career Objective updated successfully"}");
        // await getCareerObjectiveApi();
      } else {
        commonSnackBar(
            message:
                "${response.response?.data['message'] ?? AppStrings.somethingWentWrong}");
      }
    } catch (e) {
      // Handle error, show message
    }
  }

  Future<void> deleteCareerObjectiveApi() async {
    try {
      final response = await _repo.deleteCareerObjective();
      if (response.isSuccess) {
        commonSnackBar(
            message:
                "${response.response?.data['message'] ?? AppStrings.success}");
        careerObjective.value = '';
      } else {
        commonSnackBar(
            message:
                "${response.response?.data['message'] ?? AppStrings.somethingWentWrong}");
      }
    } catch (e) {
      // Handle error if needed
    }
  }
}
