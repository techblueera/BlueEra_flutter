import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/features/me/product/controller/product_service_preview_details_screen.dart';
import 'package:BlueEra/features/me/product/model/ai_product_res_model.dart';
import 'package:BlueEra/features/me/product/repo/inventory_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductBusinessProfileFullController extends GetxController {
  final InventoryRepo _repo = InventoryRepo();
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

  Rx<AiProductResModel>? aiProductRes = AiProductResModel().obs;
  Rx<ApiResponse> generateProductViaAIResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createStoreResponse = ApiResponse.initial('Initial').obs;

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
      await _repo.getBusinessProfileFullRepo(productBusinessProfileIDGlobal);
      if (response != null && response.isSuccess) {
        final model =
        BusinessProfileFullModel.fromJson(response.response?.data);
        if (model.success == true && model.data != null) {
          businessProfile.value = model.data;
        }
      } else {
        commonSnackBar(message: response?.message ?? "Failed to fetch profile");
      }
    } catch (e, s) {
      print("Error fetching profile: $s");
      // commonSnackBar(message: "Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  uploadLogoOrBannerImage(
      {required File uploadFile, required String uploadVia}) async {
    try {
      UploadResult? result = await S3UploadService.uploadFile(uploadFile);
      if (result.isSuccess) {
        ResponseModel response =
        await _repo.updateProductBusinessProfileRepo(reqBODY: {
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

    }
  }

  Future<void> aiGenerateProductFetchDetailsController() async {
    String serviceName = searchController.text;
    String website = websiteController.text;
    // Logic for AI generation goes here
    Get.back();
    try {
      ResponseModel response =
      await _repo.aiGenerateProductFetchDetailsRepo(reqBody: {
        ApiKeys.name: serviceName,
        "websiteUrl": website,
        ApiKeys.address: serviceName,
      });
      if (response.isSuccess) {
        final data = response.response?.data;
        aiProductRes?.value = AiProductResModel.fromJson(data);
        generateProductViaAIResponse.value = ApiResponse.complete(aiProductRes);
        Get.to(()=> ProductPreviewDetailsScreen());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        generateProductViaAIResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      generateProductViaAIResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> createProductProfileController() async {
    // Logic for AI generation goes here
    try {
      aiProductRes?.value.data?.locationReq = {
        "name": searchController.text,
        "type": "Point",
        "coordinates": [lat.value, lng.value]
      };
      aiProductRes?.value.data?.profileName =
          aiProductRes?.value.data?.name;

      ResponseModel response = await _repo.createProductBusinessProfileRepo(
          reqBODY: (aiProductRes?.value.data ?? {}));
      if (response.isSuccess) {
        commonSnackBar(message: "Store create successfully");
        createStoreResponse.value =
            ApiResponse.complete(response.response?.data);
        productBusinessProfileIDGlobal = response.response?.data['data']['_id'];

        if (productBusinessProfileIDGlobal.isNotEmpty) {
          await setProductBusinessProfileID(productBusinessProfileIDGlobal);
        } else {
          await setProductBusinessProfileID("");
        }
        await getProductBusinessProfileID();
        hasProfile.value = productBusinessProfileIDGlobal.isNotEmpty;
        print('has profile -- ${hasProfile.value}');
        await getBusinessProfileFull();
        // await controller.updateAboutInfo();
        await Future.delayed(Duration(milliseconds: 500));
        Get.until((route) =>
        route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        createStoreResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      createStoreResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
}
