import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabServiceAiController extends GetxController {
  LabServiceRepo labServiceRepo = LabServiceRepo();

  ///GENERATE VIA AI LAB DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxString labAddress = "".obs;
  RxBool hasLabCreated = false.obs;

  clearFiled() {
    searchController.clear();
    websiteController.clear();
    labAddress.value = "";
  }


  Future<void> createLabServiceController({required Map<String, dynamic>? reqData}) async {
    try {
      ResponseModel response = await labServiceRepo
          // .createLabServiceRepo(reqBody: {"data": aiLabResModel?.value.data});
          .createLabServiceRepo(reqBody: {"data": reqData});
      if (response.isSuccess) {
        commonSnackBar(message: "Laboratory Service Created successfully");

        labAddress.value = "";
        String? labID = response.response?.data['laboratoryId'];
        if (labID != null && labID.isNotEmpty) {
          await setLabID(labID);
        } else {
          await setLabID("");
        }
        await getLabID();
        await Future.delayed(Duration(milliseconds: 200));
        hasLabCreated.value=true;
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      hasLabCreated.value=false;

      commonSnackBar(message: e.toString());
    }
  }

}
