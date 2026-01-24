
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/institution_fetch_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/view/category/school_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  Future<void> aiInstitutionFetchDetailsController() async {
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
        hasSchool.value=schoolIDGlobal.isNotEmpty;

        await controller.updateAboutInfo();

        Get.until((route) =>
        route.settings
            .name ==
            RouteHelper
                .getBottomNavigationBarScreenRoute());
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
