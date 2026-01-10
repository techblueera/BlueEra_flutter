import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../medical/model/medical_lab_details.dart';
import '../../medical/repo/medical_repo.dart';
import '../model/hospital_model_class.dart';

class HospitalModelController extends GetxController {
  final medicalRepo = MedicalRepo();
  final RxList<MedicalLabDataListModel> hospitalCategoryDataList =
      <MedicalLabDataListModel>[].obs;
  Rx<ApiResponse> getMedicalCategoryResponse =
      ApiResponse.initial('Initial').obs;
  final hospitalNameTextController=TextEditingController();
  final hospitalAddressTextController=TextEditingController();
  final hospitalLinkTextController=TextEditingController();
  RxBool isAiBtnLoading=false.obs;
  RxBool saveAiDetailsLoading=false.obs;
  Rx<HospitalPreviewResponse> hospitalData = HospitalPreviewResponse().obs;
  Map<String,dynamic> aiRawDetails={
  };
  // Controllers for editable fields
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  void setContactControllers(ContactUs? contact) {
    phoneController.text = contact?.phone ?? '';
    emergencyController.text = contact?.emergencyPhone ?? '';
    emailController.text = contact?.email ?? '';
    addressController.text = contact?.address ?? '';
  }
  Rx<ApiResponse> hospitalAiDataResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> hospitalAiDataSaveResponse =
      ApiResponse.initial('Initial').obs;
  /// Holds user edits
  final Map<String, TextEditingController> editControllers = {};

  TextEditingController getController(String key, String value) {
    if (!editControllers.containsKey(key)) {
      editControllers[key] = TextEditingController(text: value);
    }
    return editControllers[key]!;
  }



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
  List<MedicalLabDataListModel> updateCategoryStatusById({
    required List<MedicalLabDataListModel> list,
    required String id,
    required bool isActive,
  }) {
    return list.map((item) {
      if (item.id == id) {
        return item.copyWith(isActive: isActive);
      }

      if (item.children != null && item.children!.isNotEmpty) {
        return item.copyWith(
          children: updateCategoryStatusById(
            list: item.children!,
            id: id,
            isActive: isActive,
          ),
        );
      }

      return item;
    }).toList();
  }

  Future<void> updateEnableStatus(
      String categoryTopicId,
      Map<String, dynamic> params,
      ) async {
    ResponseModel response =
    await medicalRepo.enableHotelServiceStatusApi(categoryTopicId, params);
    if (response.isSuccess) {
      final bool updatedStatus = params['isActive'];

      hospitalCategoryDataList.value = updateCategoryStatusById(
        list: hospitalCategoryDataList,
        id: categoryTopicId,
        isActive: updatedStatus,
      );

      // reassign API response for UI
      getMedicalCategoryResponse.value =
          ApiResponse.complete(hospitalCategoryDataList);

      commonSnackBar(message: response.response?.statusMessage ?? '');
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> fetchHospitalViaAi() async {
    Map<String, dynamic> params={
      ApiKeys.name: hospitalNameTextController.text,
      ApiKeys.address: hospitalAddressTextController.text,
      ApiKeys.url: hospitalLinkTextController.text
    };
    isAiBtnLoading.value=true;
    ResponseModel response =
    await medicalRepo.getHospitalFromAi(params);
    if (response.isSuccess) {
      aiRawDetails=response.response?.data;
      hospitalData.value =HospitalPreviewResponse.fromJson(response.response?.data);
      Get.back();
      isAiBtnLoading.value=false;
      hospitalAiDataResponse.value =ApiResponse.complete(hospitalData.value );
    } else {
      isAiBtnLoading.value=false;
      commonSnackBar(message: response.message??AppStrings.somethingWentWrong);
      hospitalAiDataResponse.value =ApiResponse.error("Error");
    }
  }
  Future<void> saveAiHospitalDetails()async {
    Map<String,dynamic> params ={
      "data":aiRawDetails['data']
    };
    saveAiDetailsLoading.value=true;
    ResponseModel response =
    await medicalRepo.saveAiDetailsOfHospital(params);
    if (response.isSuccess) {
      log("dslkjcnskjdcnskjdc ${response.data}");
      hospitalAiDataSaveResponse.value =ApiResponse.complete(response.response?.data);
      saveAiDetailsLoading.value=false;
    } else {
      isAiBtnLoading.value=false;
      commonSnackBar(message: response.message??AppStrings.somethingWentWrong);
      hospitalAiDataSaveResponse.value =ApiResponse.error("Error");
      saveAiDetailsLoading.value=false;
    }

  }


}
//https://themissionhospital.com/
//The Mission Hospital