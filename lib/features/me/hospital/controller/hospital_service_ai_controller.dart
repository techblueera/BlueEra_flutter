import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/hospital/model/hospita_ai_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_repo.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_service_preview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalServiceAiController extends GetxController {
  HospitalRepo hospitalServiceRepo = HospitalRepo();

  ///GENERATE VIA AI LAB DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxString labAddress = "".obs;
  RxBool hasHospitalCreated = false.obs;

  clearFiled() {
    searchController.clear();
    websiteController.clear();
    labAddress.value = "";
  }

  Rx<HospitalAiDetailsResModel>? aiHospitalResModel =
      HospitalAiDetailsResModel().obs;

  Future<void> aiHospitalFetchDetailsController() async {
    String hospitalName = searchController.text;
    labAddress.value = hospitalName;
    String website = websiteController.text;
    // Logic for AI generation goes here
    Get.back();
    try {
      ResponseModel response =
          await hospitalServiceRepo.aiHospitalFetchDetailsRepo(reqBody: {
        ApiKeys.name: hospitalName,
        ApiKeys.url: website,
        ApiKeys.address: hospitalName,
      });
      if (response.isSuccess) {
        final data = response.response?.data;
        aiHospitalResModel?.value = HospitalAiDetailsResModel.fromJson(data);

        Get.to(HospitalServicePreview());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: e.toString());
    }
  }

  Future<void> createHospitalServiceController() async {
    try {
      ResponseModel response = await hospitalServiceRepo.createHospitalRepo(
          reqBody: {"aiOutput": aiHospitalResModel?.value.data});
      if (response.isSuccess) {
        commonSnackBar(message: "Hospital Service Created successfully");

        labAddress.value = "";
        String? hospitalID = response.response?.data['hospitalId'];
        if (hospitalID != null && hospitalID.isNotEmpty) {
          await setHospitalID(hospitalID);
        } else {
          await setHospitalID("");
        }
        await getHospitalID();
        await Future.delayed(Duration(milliseconds: 200));
        hasHospitalCreated.value = true;
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      hasHospitalCreated.value = false;

      commonSnackBar(message: e.toString());
    }
  }
}
