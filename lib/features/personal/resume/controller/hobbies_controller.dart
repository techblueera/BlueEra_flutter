import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HobbiesController extends GetxController {
  final hobbies = <Map<String, String>>[].obs;
  final hobbyController = TextEditingController();
  final descriptionController = TextEditingController();
  final isValidate = false.obs;
  final isAddHobbyValidate = false.obs;

  final getResumeController = Get.find<ProfilePicController>();
  ApiResponse addHobbiesResponse = ApiResponse.initial('Initial');
  ApiResponse fetchHobbiesResponse = ApiResponse.initial('Initial');
  ApiResponse deleteHobbyResponse = ApiResponse.initial('Initial');

  @override
  void onInit() {
    super.onInit();
    // fetchHobbies();
    hobbyController.addListener(validateForm);
    descriptionController.addListener(validateForm);
  }

  @override
  void onClose() {
    hobbyController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void validateForm() {
    isAddHobbyValidate.value = hobbyController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty;
    isValidate.value =
        hobbies.isNotEmpty && descriptionController.text.isNotEmpty;
  }

  void addHobby() {
    if (hobbyController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty) {
      final hobbyData = {
        "name": hobbyController.text.trim(),
        "description": descriptionController.text.trim()
      };

      // Check if hobby already exists
      bool exists = hobbies.any((hobby) =>
          hobby["name"]?.toLowerCase() == hobbyData["name"]!.toLowerCase());

      if (!exists) {
        hobbies.add(hobbyData);
        hobbyController.clear();
        isAddHobbyValidate.value = false;
        validateForm();
      } else {
        commonSnackBar(message: AppStrings.hobbyAlreadyExists);
      }
    }
  }

  void removeHobbyByName(String name) {
    hobbies.removeWhere(
        (hobby) => hobby["name"]?.toLowerCase() == name.toLowerCase());
    validateForm();
  }

  Future<void> saveHobbies() async {
    try {
      final params = {
        "hobbies": hobbies
            .map((hobby) => {
                  "name":
                      (hobby["name"] ?? hobby["hobby_name"] ?? "").toString(),
                  "description": (hobby["description"] ?? "").toString()
                })
            .toList()
      };
      final res = await ResumeRepo().postHobbies(params: params);
      if (res.isSuccess) {
        addHobbiesResponse = ApiResponse.complete(res);
        // await fetchHobbies(); // Update the hobbies list
        final data = res.response?.data;
        if (data != null && data['hobbies'] != null) {
          hobbies.clear();
          final hobbiesList = data['hobbies'] as List;
          for (var hobby in hobbiesList) {
            hobbies.add({
              "_id": hobby["_id"] ?? "",
              "name": hobby["name"] ?? "",
              "description": hobby["description"] ?? ""
            });
          }
        }

        await getResumeController.getMyResume();
        Get.back();
        commonSnackBar(message: AppStrings.hobbiesAddedSuccess);
      } else {
        addHobbiesResponse =
            ApiResponse.error(res.message ?? AppStrings.hobbiesAddFailed);
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      print("Error in saveHobbies: $e"); // Debug log
      addHobbiesResponse = ApiResponse.error(AppStrings.hobbiesAddFailed.tr);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> deleteHobby(String hobbyId) async {
    try {
      final res = await ResumeRepo().deleteHobby(id: hobbyId);
      if (res.isSuccess) {
        deleteHobbyResponse = ApiResponse.complete(res);
        final data = res.response?.data;

        if (data != null && data['hobbies'] != null) {
          hobbies.clear();
          final hobbiesList = data['hobbies'] as List;
          for (var hobby in hobbiesList) {
            hobbies.add({
              "_id": hobby["_id"] ?? "",
              "name": hobby["name"] ?? "",
              "description": hobby["description"] ?? ""
            });
          }
        }

        validateForm();
        commonSnackBar(message:AppStrings.hobbyDeletedSuccess);
      } else {
        deleteHobbyResponse =
            ApiResponse.error(res.message ?? AppStrings.hobbyDeleteFailed.tr);
        commonSnackBar(message: res.message ?? AppStrings.hobbyDeleteFailed);
      }
    } catch (e) {
      deleteHobbyResponse = ApiResponse.error(AppStrings.deletionFailed.tr);
      commonSnackBar(message: AppStrings.hobbyDeleteFailed);
    }
  }
}
