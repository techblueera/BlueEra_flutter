import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/services/location/location_service.dart';
import '../../medical/model/medical_lab_details.dart';
import '../../medical/repo/medical_repo.dart';
import '../model/hospital_main_page_model.dart';
import '../model/hospital_model_class.dart';

class HospitalModelController extends GetxController {
  final medicalRepo = MedicalRepo();


  Rx<ApiResponse> getHospitalMainResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getHospitalSubResponse =
      ApiResponse.initial('Initial').obs;
  final hospitalNameTextController=TextEditingController();
  final hospitalAddressTextController=TextEditingController();
  final hospitalLinkTextController=TextEditingController();
  final TextEditingController nameController = TextEditingController();
  RxBool isActive = true.obs;
  RxBool isAiBtnLoading=false.obs;
  RxString hospitalCurrentAddress=''.obs;
  RxBool saveAiDetailsLoading=false.obs;
  Rx<HospitalPreviewResponse> hospitalData = HospitalPreviewResponse().obs;
  Rx<MainHospitalDepartmentResponse> hospitalMainPageData = MainHospitalDepartmentResponse().obs;
  RxList<Department> hospitalSubCate = <Department>[].obs;
  Map<String,dynamic> aiRawDetails={
  };
  RxMap<String,dynamic> hospitalFacilitiesMap=<String,dynamic>{}.obs;

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

Future<void> fetchAddressByLatLng({required double lat,required double lng})async{
  String? address=await LocationService.getAddressUsingLatLng(latitude: lat, longitude: lng);
  hospitalCurrentAddress.value=address;
}

  Future<void> fetchHospitalCategoryData() async {
    ResponseModel response = await medicalRepo.fetchHospitalMainCateApi();
    if (response.isSuccess) {
      hospitalMainPageData.value= MainHospitalDepartmentResponse.fromJson(response.response?.data);
      getHospitalMainResponse.value =
          ApiResponse.complete(hospitalMainPageData);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getHospitalMainResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
  Future<void> addHospitalDepartmentApi(Map<String,dynamic> params) async {
    ResponseModel response = await medicalRepo.addHospitalDepartmentApi(params);
    if (response.isSuccess) {
      log("dslkjcnskjdcnskjdc ${response.response?.data}");

    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      // getHospitalMainResponse.value =
      //     ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
  Future<void> fetchHospitalSubCategoryData(String categoryTopic) async {
    getHospitalSubResponse.value =
        ApiResponse.initial("Initial");
    ResponseModel response = await medicalRepo.fetchHospitalSubCateApi(categoryTopic);
    if (response.isSuccess) {
      List rawList=response.response?.data['data']['subDepartments'];
      hospitalSubCate.value=rawList.map((e)=>Department.fromJson(e)).toList();
      getHospitalSubResponse.value =
      ApiResponse.complete(hospitalSubCate);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getHospitalSubResponse.value =
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
      //
      // hospitalCategoryDataList.value = updateCategoryStatusById(
      //   list: hospitalCategoryDataList,
      //   id: categoryTopicId,
      //   isActive: updatedStatus,
      // );

      // reassign API response for UI


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
      log("dslkjcnskjdcnskjdc ${response.response?.data}");
      hospitalAiDataSaveResponse.value =ApiResponse.complete(response.response?.data);
      saveAiDetailsLoading.value=false;
    } else {
      isAiBtnLoading.value=false;
      commonSnackBar(message: response.message??AppStrings.somethingWentWrong);
      hospitalAiDataSaveResponse.value =ApiResponse.error("Error");
      saveAiDetailsLoading.value=false;
    }
  }


  Future<void> createBusinessPost(Map<String,dynamic> params)async {

    ResponseModel response =
    await medicalRepo.createBusinessPost(params);
    if (response.isSuccess) {
      log("dslkjcnskjdcnskjdc Save Hospital ${response.response?.data}");

    } else {

    }
  }


}
//https://themissionhospital.com/
//The Mission Hospital