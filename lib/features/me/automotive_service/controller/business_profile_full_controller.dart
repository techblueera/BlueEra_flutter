import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessProfileFullController extends GetxController {
  final OtherRepo _repo = OtherRepo();
  var isLoading = false.obs;
  var businessProfile = Rx<BusinessProfileData?>(null);
  RxBool hasProfile = false.obs;

  String get website {
    if (businessProfile.value == null) return "";
    if (businessProfile.value?.contactUs != null &&
        (businessProfile.value?.contactUs?.isNotEmpty ?? false)) {
      return businessProfile.value?.contactUs?.firstOrNull?.branch?.website ??
          "";
    }
    return "";
  }

  ///GENERATE VIA AI SCHOOL DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxDouble lat = 0.0.obs;
  RxDouble lng = 0.0.obs;

  clearAiGenerateFiled() {
    searchController.clear();
    websiteController.clear();
    lat.value = 0.0;
    lng.value = 0.0;
  }

  Rx<ApiResponse> generateSchoolViaAIResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createSchoolResponse = ApiResponse.initial('Initial').obs;

  @override
  void onClose() {
    searchController.dispose();
    websiteController.dispose();
    // fullSchoolAddressController.dispose();
    super.onClose();
  }

  Future<void> getBusinessProfileFull() async {
    isLoading.value = true;
    try {
      if (otherServiceIDGlobal.isEmpty) {
        final idResponse = await _repo.getBusinessProfileRepo();
        if (idResponse.isSuccess) {
          final id = idResponse.response?.data['data']['_id'] ?? '';
          otherServiceIDGlobal = id;
          if (id.isNotEmpty) await setOtherServiceID(id);
        }
      }
      if (otherServiceIDGlobal.isEmpty) return;

      // Always call the full profile API directly
      final response =
          await _repo.getBusinessProfileFullRepo(otherServiceIDGlobal);
      if (response != null && response.isSuccess) {
        final model =
            BusinessProfileFullModel.fromJson(response.response?.data);
        if (model.success == true && model.data != null) {
          businessProfile.value = model.data;
          hasProfile.value = true;
        }
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  uploadSchoolLogoOrBannerImage(
      {required File uploadFile, required String uploadVia}) async {
    try {
      UploadResult? result = await S3UploadService.uploadFile(uploadFile);
      if (result.isSuccess) {
        ResponseModel response =
            await _repo.updateOtherBusinessProfileRepo(reqBODY: {
          uploadVia: result.url,
          "profileName": businessProfile.value?.profile?.profileName
        });
        if (response.isSuccess) {
          commonSnackBar(message: response.response?.data['message']);
          getBusinessProfileFull();
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);

      // TODO
    }
  }

}
