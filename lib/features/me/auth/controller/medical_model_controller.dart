import 'dart:convert';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../model/medical_lab_details.dart';
import '../repo/medical_repo.dart';

class MedicalModelController extends GetxController {
  final medicalRepo = MedicalRepo();
  final RxList<MedicalLabDataListModel> medicalCategoryDataList =
      <MedicalLabDataListModel>[].obs;
  Rx<ApiResponse> getMedicalCategoryResponse =
      ApiResponse.initial('Initial').obs;

  Future<void> fetchMedicalCategoryData(String categoryTopic) async {
    ResponseModel response =
        await medicalRepo.fetchMedicalCategoryData(categoryTopic);
    if (response.isSuccess) {
      final modelJson = response.response?.data['data'];
      List<dynamic> modelList = modelJson;
      medicalCategoryDataList.value =
          modelList.map((e) => MedicalLabDataListModel.fromJson(e)).toList();
      getMedicalCategoryResponse.value =
          ApiResponse.complete(medicalCategoryDataList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getMedicalCategoryResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
}
