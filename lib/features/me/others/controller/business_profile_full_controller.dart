import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/others/model/ai_other_service_res_model.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/others/view/other_service_preview_detials_screen.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessProfileFullController extends GetxController {
  final OtherRepo _repo = OtherRepo();
  var isLoading = false.obs;
  var businessProfile = Rx<BusinessProfileData?>(null);
  RxBool hasProfile = false.obs;

  ///GENERATE VIA AI SCHOOL DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();

  // RxBool hasSchool = false.obs;

  // final fullSchoolAddressController = TextEditingController();
  RxDouble lat = 0.0.obs;
  RxDouble lng = 0.0.obs;

  clearAiGenerateFiled() {
    searchController.clear();
    websiteController.clear();
    // fullSchoolAddressController.clear();
    lat.value = 0.0;
    lng.value = 0.0;
  }

  Rx<AiOtherServiceResModel>? aiOtherServiceRes = AiOtherServiceResModel().obs;
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
      final response =
          await _repo.getBusinessProfileFullRepo(otherServiceIDGlobal);
      if (response != null && response.isSuccess) {
        final model =
            BusinessProfileFullModel.fromJson(response.response?.data);
        if (model.success == true && model.data != null) {
          businessProfile.value = model.data;
        }
      } else {
        commonSnackBar(message: response?.message ?? "Failed to fetch profile");
      }
    } catch (e) {
      print("Error fetching profile: $e");
      // commonSnackBar(message: "Error: $e");
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
    } on Exception catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);

      // TODO
    }
  }

  Future<void> aiGenerateOtherServiceFetchDetailsController() async {
    String serviceName = searchController.text;
    String website = websiteController.text;
    // Logic for AI generation goes here
    Get.back();
    try {
      ResponseModel response =
          await _repo.aiGenerateOtherServiceFetchDetailsRepo(reqBody: {
        ApiKeys.name: serviceName,
        "websiteUrl": website,
        ApiKeys.address: serviceName,
      });
      if (response.isSuccess) {
        final data = response.response?.data;
        aiOtherServiceRes?.value = AiOtherServiceResModel.fromJson(data);
        generateSchoolViaAIResponse.value =
            ApiResponse.complete(aiOtherServiceRes);
        Get.to(OtherServicePreviewDetailsScreen());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        generateSchoolViaAIResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      // TODO
      generateSchoolViaAIResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> createOtherProfileController() async {
    // Logic for AI generation goes here
    try {
      aiOtherServiceRes?.value.data?.locationReq = {
        "name": searchController.text,
        "type": "Point",
        "coordinates": [lat.value, lng.value]
      };
      aiOtherServiceRes?.value.data?.profileName =
          aiOtherServiceRes?.value.data?.name;

      ResponseModel response = await _repo.createOtherBusinessProfileRepo(
          reqBODY: (aiOtherServiceRes?.value.data ?? {}));
      if (response.isSuccess) {
        commonSnackBar(message: "Other service create successfully");
        createSchoolResponse.value =
            ApiResponse.complete(response.response?.data);
        otherServiceIDGlobal = response.response?.data['data']['_id'];

        if (otherServiceIDGlobal.isNotEmpty) {
          await setOtherServiceID(otherServiceIDGlobal);
        } else {
          await setOtherServiceID("");
        }
        await getOtherServiceID();
        hasProfile.value = otherServiceIDGlobal.isNotEmpty;
        await getBusinessProfileFull();
        // await controller.updateAboutInfo();
        await Future.delayed(Duration(milliseconds: 500));
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        createSchoolResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      // TODO
      createSchoolResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
}
