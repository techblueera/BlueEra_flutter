import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
class SchoolController extends GetxController {
  ///GENERATE VIA AI SCHOOL DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxBool hasSchool = false.obs;
  RxDouble lat = 0.0.obs;
  RxDouble lng = 0.0.obs;

  clearAiGenerateFiled() {
    searchController.clear();
    websiteController.clear();
    lat.value = 0.0;
    lng.value = 0.0;
  }

  @override
  void onClose() {
    searchController.dispose();
    websiteController.dispose();
    super.onClose();
  }


  Rx<ApiResponse> generateSchoolViaAIResponse =
      ApiResponse.initial('Initial').obs;

// Inside your GetxController

// Inside your Controller
  RxBool isAiLoading = false.obs;




  Future<void> createSchoolController(
      {required Map<String, dynamic>? reqData}) async {
    // Logic for AI generation goes here
    try {
      ResponseModel response = await SchoolRepo().createSchoolRepo(reqBody: {
        ApiKeys.business_name:   reqData![ApiKeys.business_name],
        ApiKeys.business_location: reqData[ ApiKeys.business_location],
        ApiKeys.type_of_business: reqData[ ApiKeys.type_of_business],
        ApiKeys.nature_of_business: reqData[ ApiKeys.nature_of_business],
        ApiKeys.date_of_incorporation: reqData[ ApiKeys.date_of_incorporation],
        ApiKeys.category_Of_Business: reqData[ ApiKeys.category_Of_Business],
        ApiKeys.sub_category_Of_Business: reqData[ ApiKeys.sub_category_Of_Business],
        ApiKeys.number_of_Employees: reqData[ ApiKeys.number_of_Employees],
        ApiKeys.number_of_branch: reqData[ ApiKeys.number_of_branch],
      });
      if (response.isSuccess) {
        commonSnackBar(message: "School create successfully");
        String? schoolID = response.response?.data['data']['_id'];


        if (schoolID != null && schoolID.isNotEmpty) {
          await setSchoolID(schoolID);
        } else {
          await setSchoolID("");
        }
        await getSchoolID();
        hasSchool.value = schoolIDGlobal.isNotEmpty;

      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception {
      // TODO
    }
  }
}
