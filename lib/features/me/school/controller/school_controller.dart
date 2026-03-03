import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/institution_fetch_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/view/category/school_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'dart:async';

class SchoolController extends GetxController {
  ///GENERATE VIA AI SCHOOL DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxBool hasSchool = false.obs;

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

  @override
  void onClose() {
    searchController.dispose();
    websiteController.dispose();
    // fullSchoolAddressController.dispose();
    super.onClose();
  }

  Rx<InstitutionFetchModel>? institutionFetchModel =
      InstitutionFetchModel().obs;
  Rx<ApiResponse> generateSchoolViaAIResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createSchoolResponse = ApiResponse.initial('Initial').obs;


// Inside your GetxController

// Inside your Controller
  RxBool isAiLoading = false.obs;
  Timer? _forceTimer;

  Future<void> aiInstitutionFetchDetailsController() async {
    // 1. Start Loader (DO NOT call Get.back() here)
    isAiLoading.value = true;

    // 2. The 1-Minute "Safety Switch"
    // This is the ONLY thing that will close the loader if the API stays pending
    _forceTimer?.cancel();
    _forceTimer = Timer(const Duration(seconds: 45), () {
      if (isAiLoading.value) {
        isAiLoading.value = false;
        commonSnackBar(message: "Process finished or timed out.");
        // Optional: Get.back(); // Only uncomment if you want the dialog to disappear after 1 min
      }
    });

    try {
      ResponseModel response = await SchoolRepo().aiInstitutionFetchDetailsRepo(
        reqBody: {
          "name": searchController.text,
          "url": websiteController.text,
        },
      );

      if (response.isSuccess) {
        final data = response.response?.data;
        String status = data['status'] ?? '';

        if (status == "pending") {
          // REASON IT WAS CLOSING: Check if you have a Get.back() here.
          // We do NOTHING here. The loader stays visible.
          print("Status is pending... keeping dialog open.");
        } else {
          // STATUS IS COMPLETE
          institutionFetchModel?.value = InstitutionFetchModel.fromJson(data);
          isAiLoading.value = false;
          _forceTimer?.cancel();

          // Get.back(); // NOW we close the dialog because we are done
          Get.to(SchoolPreviewScreen());
        }
      } else {
        // If API fails, we stop the loader but KEEP the dialog open so they can fix info
        isAiLoading.value = false;
        _forceTimer?.cancel();
        // commonSnackBar(message: "Selection failed. Please check your inputs.");
      }
    } catch (e) {
      isAiLoading.value = false;
      _forceTimer?.cancel();
      print("Error: $e");
    }
  }
// Inside your SchoolController
//   RxBool isAiLoading = false.obs;
  RxString loadingStatusMessage = "AI is researching...".obs; // Dynamic message
  // RxInt secondsRemaining = 60.obs;
  Timer? _uiTimer;

 /* Future<void> aiInstitutionFetchDetailsController__() async {
    String school = searchController.text;
    String website = websiteController.text;

    // 1. Start Loading
    isAiLoading.value = true;
    secondsRemaining.value = 60;
    loadingStatusMessage.value = "AI is researching...";

    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
        if (isAiLoading.value) {
          _stopLoading();
          commonSnackBar(message: "Request timed out. Please try again later.");
        }
      }
    });

    try {
      // 2. Single API Call
      ResponseModel response = await SchoolRepo().aiInstitutionFetchDetailsRepo(
        reqBody: {
          ApiKeys.name: school,
          ApiKeys.url: website,
          ApiKeys.address: school,
        },
      );

      if (response.isSuccess) {
        final data = response.response?.data;
        String status = data['status'] ?? '';

        if (status == "pending") {
          // If pending, do NOT close loader. Update message and wait for timeout.
          loadingStatusMessage.value = "Request accepted. Researching in progress...";
          logs("Status is pending: Loader remains active.");
          isAiLoading.value=true;
          // Note: Since you asked for a SINGLE call, we stop here and wait for the 1-min timer to finish
          // OR you can add a 'Check Again' button that appears only if status was pending.
        } else {
          // If status is complete/success
          institutionFetchModel?.value = InstitutionFetchModel.fromJson(data);
          generateSchoolViaAIResponse.value = ApiResponse.complete(institutionFetchModel);

          _stopLoading();
          Get.back(); // Close Dialog
          Get.to(SchoolPreviewScreen());
        }
      } else {
        _stopLoading();
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      _stopLoading();
      commonSnackBar(message: e.toString());
    }
  }*/

  Future<void> aiInstitutionFetchDetailsController_() async {
    String school = searchController.text;
    String website = websiteController.text;
// Logic for AI generation goes here
    Get.back();
    try {
      ResponseModel response =
      await SchoolRepo().aiInstitutionFetchDetailsRepo(reqBody: {
        ApiKeys.name: school,
        ApiKeys.url: website,
        ApiKeys.address: school,
      });
      if (response.isSuccess) {
        final data = response.response?.data;
        institutionFetchModel?.value = InstitutionFetchModel.fromJson(data);
        generateSchoolViaAIResponse.value =
            ApiResponse.complete(institutionFetchModel);
        Get.to(SchoolPreviewScreen());
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


  Future<void> createSchoolController() async {
    // Logic for AI generation goes here
    try {
      institutionFetchModel?.value.data?.category = businessCategoryGlobal;
      institutionFetchModel?.value.data?.locationReq = {
        "name": searchController.text,
        "type": "Point",
        "coordinates": [lat.value, lng.value]
      };

      ResponseModel response = await SchoolRepo()
          .createSchoolRepo(reqBody: (institutionFetchModel?.value.data ?? {}));
      if (response.isSuccess) {
        commonSnackBar(message: "School create successfully");
        createSchoolResponse.value =
            ApiResponse.complete(institutionFetchModel);
        String? schoolID = response.response?.data['data']['_id'];

        final controller = Get.isRegistered<SchoolAboutUsController>()
            ? Get.find<SchoolAboutUsController>()
            : Get.put(SchoolAboutUsController());

        if (schoolID != null && schoolID.isNotEmpty) {
          await setSchoolID(schoolID);
        } else {
          await setSchoolID("");
        }
        await getSchoolID();
        hasSchool.value = schoolIDGlobal.isNotEmpty;

        await controller.updateAboutInfo();

        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
        // Get.offAll(BottomNavigationBarScreen());
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
