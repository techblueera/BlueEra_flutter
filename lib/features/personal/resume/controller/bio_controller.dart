import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BioController extends GetxController {
  final bio = ''.obs;

  final educationList = <Map<String, String>>[].obs;
  final workExperienceList = <Map<String, String>>[].obs;

  final maxLength = 200;

  /// TextEdidtingControllers

  final bioController = TextEditingController();

  @override
  void onInit() {
    bio.value = bioController.text;
    super.onInit();
  }

  @override
  void onClose() {
    bioController.dispose();
    super.onClose();
  }

  void addBioToEducationList(String bioText) {
    educationList.clear();
    educationList.add({
      'title': bioText,
      // 'subtitle1': bioText,
    });
  }

  void clearBioFields() {
    bioController.clear();
    bio.value = '';
  }

  ApiResponse updateBioResponse = ApiResponse.initial('Initial');


Future<void> addBio(Map<String, dynamic> params) async {
  try {
    final res = await ResumeRepo().addBio(params: params);
    if (res.isSuccess) {
      addBioToEducationList(params[ApiKeys.bio]);
      Get.back();
      Future.delayed(const Duration(milliseconds: 100), () {
        commonSnackBar(message: AppStrings.bioAdded);
      });
    } else {
      commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
    }
  } catch (e) {
    commonSnackBar(message:AppStrings.bioAddFailed);
  }
}

Future<void> updateBio(Map<String, dynamic> params) async {
  try {
    final res = await ResumeRepo().updateBio(params: params);
    if (res.isSuccess) {
      addBioToEducationList(params[ApiKeys.bio]);
      Get.back();
      Future.delayed(const Duration(milliseconds: 100), () {
        commonSnackBar(message: AppStrings.bioUpdated);
      });
    } else {
      commonSnackBar(message: res.message ?? AppStrings.bioUpdateFailed);
    }
  } catch (e) {
    commonSnackBar(message:AppStrings.bioUpdateFailed);
  }
}

  Future<void> deleteBio() async {
    try {
      final res = await ResumeRepo().deleteBio();
      if (res.isSuccess) {
        educationList.clear();
         clearBioFields();
        commonSnackBar(message: AppStrings.bioDeleted);
      } else {
        commonSnackBar(message: res.message ??AppStrings.bioDeleteFailed);
      }
    } catch (e) {
      commonSnackBar(message:AppStrings.bioDeleteError);
    }
  }
}
