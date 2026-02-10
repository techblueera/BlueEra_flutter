import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/ai_lab_service_model_res.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_preview_screeen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabServiceAiController extends GetxController {
  LabServiceRepo labServiceRepo=LabServiceRepo();
  ///GENERATE VIA AI LAB DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxString labAddress = "".obs;


  clearFiled()
  {
    searchController.clear();
    websiteController.clear();
    labAddress.value="";
  }

  Rx<AiLabServiceModelRes>? aiLabResModel = AiLabServiceModelRes().obs;

  Future<void> aiLabFetchDetailsController() async {
    String hotelName = searchController.text;
    labAddress.value = hotelName;
    String website = websiteController.text;
    // Logic for AI generation goes here
    Get.back();
    try {
      ResponseModel response =
          await labServiceRepo.aiLabFetchDetailsRepo(reqBody: {
        ApiKeys.name: hotelName,
        ApiKeys.websiteUrl: website,
        ApiKeys.address: hotelName,
      });
      if (response.isSuccess) {
        final data = response.response?.data;
        aiLabResModel?.value = AiLabServiceModelRes.fromJson(data);

        Get.to(LabPreviewScreen());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: e.toString());
    }
  }
}
