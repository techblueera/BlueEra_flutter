import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../model/medical_admin_product_details.dart';
import '../model/medical_lab_details.dart';
import '../repo/medical_repo.dart';

class HospitalModelController extends GetxController {
  final medicalRepo = MedicalRepo();
  final RxList<MedicalLabDataListModel> hospitalCategoryDataList =
      <MedicalLabDataListModel>[].obs;
  Rx<ApiResponse> getMedicalCategoryResponse =
      ApiResponse.initial('Initial').obs;


  Future<void> fetchHospitalCategoryData(String categoryTopic) async {
    ResponseModel response =
    await medicalRepo.fetchMedicalCategoryData(categoryTopic);
    if (response.isSuccess) {
      final modelJson = response.response?.data['data'];
      List<dynamic> modelList = modelJson;
      hospitalCategoryDataList.value =
          modelList.map((e) => MedicalLabDataListModel.fromJson(e)).toList();
      getMedicalCategoryResponse.value =
          ApiResponse.complete(hospitalCategoryDataList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getMedicalCategoryResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

}
