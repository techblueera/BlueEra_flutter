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
class MedicalModelController extends GetxController {
  final medicalRepo = MedicalRepo();
  final RxList<MedicalLabDataListModel> medicalCategoryDataList =
      <MedicalLabDataListModel>[].obs;
  final RxList<MedicalProductDetailsModel> medicalProductDetails =
      <MedicalProductDetailsModel>[].obs;
  Rx<ApiResponse> getMedicalCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getMedicalProductListResponse =
      ApiResponse.initial('Initial').obs;
  final RxList<MedicalProductDetailsModel> selectedProducts =
      <MedicalProductDetailsModel>[].obs;

  bool isSelected(MedicalProductDetailsModel product) {
    return selectedProducts.any((p) => p.id == product.id);
  }

  void toggleProduct(MedicalProductDetailsModel product) {
    final index =
    selectedProducts.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      selectedProducts.removeAt(index);
    } else {
      selectedProducts.add(product);
    }
  }

  void clearSelection() {
    selectedProducts.clear();
  }
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
  Future<void> fetchMedicalAdminProducts(String categoryTopic) async {
    ResponseModel response =
        await medicalRepo.fetchMedicalAdminProduct(categoryTopic);
    if (response.isSuccess) {
      final modelJson = response.response?.data['data'];
      List<dynamic> modelList = modelJson;
      medicalProductDetails.value =
          modelList.map((e) => MedicalProductDetailsModel.fromJson(e)).toList();
      getMedicalProductListResponse.value =
          ApiResponse.complete(medicalProductDetails);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getMedicalProductListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
}
