import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/model/service_ai_generate_model.dart';
import 'package:BlueEra/features/common/service/repo/service_ai_repo.dart';
import 'package:BlueEra/features/common/service/view/add_services_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/earn_service_repo.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;

class ServiceController extends GetxController {
  Rx<ApiResponse> serviceAiResponse
            = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addServiceResponse
             = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deleteServiceResponse
             = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> singleServiceDataResponse =
      ApiResponse.initial('Initial').obs;

  // Form controllers
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController serviceShortDescriptionController =
      TextEditingController();

  // Selected options
  final RxString serviceName = "".obs;
  final RxString shortDescriptionName = "".obs;

  // Image selection
  final Rx<File?> selectedImage = Rx<File?>(null);

  // Service category dropdown (Tailor / Beautician / Interior Designer /
  // Digital Marketing). The UI shows `name`; the API call uses `tagId`.
  static const List<ServiceCategoryOption> serviceCategoryOptions = [
    ServiceCategoryOption(name: 'Tailor', tagId: TAILOR),
    ServiceCategoryOption(name: 'Beautician', tagId: BEAUTICIAN),
    ServiceCategoryOption(name: 'Interior Designer', tagId: INTERIOR_DESIGNER),
    ServiceCategoryOption(name: 'Digital Marketing', tagId: DIGITAL_MARKETING),
  ];
  final Rxn<ServiceCategoryOption> selectedServiceCategory =
      Rxn<ServiceCategoryOption>();

  ProviderType? providerType;
  String? category;
  String? serviceSubType;
  String? channelId;

  // Loading state
  final RxBool isLoading = false.obs;

  // Show image picker dialog
  // Generate food data
  Rx<ServiceAiGenerateModel> serviceAiResModel = ServiceAiGenerateModel().obs;
  RxBool isGenerateAiServiceLoading = false.obs;

  /// All Service data

  Future<void> generateServiceAiController(
      {
        required Map<String, dynamic> serviceDetailsReq
      }) async {
    try {
      isGenerateAiServiceLoading.value = true;
      String fileName = selectedImage.value?.path.split('/').last ?? "";
      dio.MultipartFile? imageByPart = await dio.MultipartFile.fromFile(
          selectedImage.value?.path ?? "",
          filename: fileName);
      Map<String, dynamic> reqParam = {
        ApiKeys.service_details: jsonEncode(serviceDetailsReq),
        ApiKeys.images: imageByPart,
      };
      // if(channelId!=null){
      //   reqParam[ApiKeys.channelId] = channelId;
      // }
      ResponseModel responseModel =
          await ServiceAiRepo().aiServiceGenerateRepo(queryParam: reqParam);
      if (responseModel.isSuccess) {
        serviceAiResModel.value = ServiceAiGenerateModel.fromJson(responseModel.response?.data);
        Get.to(() => const AddServicesScreenNew());
        serviceAiResponse.value = ApiResponse.complete(serviceAiResModel);
      } else {
        serviceAiResponse.value = ApiResponse.error('Failed to load');
      }
    } catch (e) {
      logs("ERROR===== ${e}");
      serviceAiResponse.value = ApiResponse.error(e.toString());
    }finally{
      isGenerateAiServiceLoading.value = false;
    }
  }
  RxList<GetServiceModel> serviceDataList = <GetServiceModel>[].obs;
  RxBool isServiceDataLoadingMore = false.obs;
  RxBool isServiceDataFirstLoading = false.obs;
  int serviceDataPage = 1;
  bool serviceDataHasMore = true;

  /// fetch services
  Future<void> getServices(Map<String, dynamic> queryParams,  {bool isFromEarnWithBlueEra = false, bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isServiceDataLoadingMore.value || !serviceDataHasMore) return;
      isServiceDataLoadingMore.value = true;
    } else {
      isServiceDataFirstLoading.value = true;
      serviceDataPage = 1;
      serviceDataHasMore = true;
      serviceDataList.clear();
    }
    queryParams[ApiKeys.page] = serviceDataPage;

    try {
      ResponseModel response;
      if(!isFromEarnWithBlueEra){
         response = await ServiceAiRepo().getServiceRepo(queryParams: queryParams);
      }else{
        response = await EarnServiceRepo().getEarnServiceRepo(queryParams: queryParams);
      }

      if (response.isSuccess) {
        final responseData = response.response?.data;
        List<GetServiceModel> newServices = [];

        // Handle both array or map API structures
        if (responseData is List) {
          newServices = responseData.map((e) => GetServiceModel.fromJson(e)).toList();
        } else if (responseData is Map && responseData['data'] is List) {
          newServices = (responseData['data'] as List)
              .map((e) => GetServiceModel.fromJson(e))
              .toList();
        } else {
          print(" Unexpected API structure: $responseData");
        }

        if (newServices.isNotEmpty) {
          if (isLoadMore) {
            serviceDataList.addAll(newServices);
          } else {
            serviceDataList.assignAll(newServices);
          }

          serviceDataPage++;
        } else {
          serviceDataHasMore = false;
        }

        getServiceResponse.value = ApiResponse.complete(response);
        print("Loaded ${newServices.length} services | Total: ${serviceDataList.length}");
      } else {
        getServiceResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      getServiceResponse.value = ApiResponse.error('error');
      logs("stack trace--> $s");
    }finally{
      if (isLoadMore) {
        isServiceDataLoadingMore.value = false;
      } else {
        isServiceDataFirstLoading.value = false;
      }
    }
  }

  RxBool isDeleteServiceLoading = false.obs;
  Future<void> deleteService({required String serviceId, required bool isFromEarnWithBlueEra}) async {
    isDeleteServiceLoading.value = true;

    try {
      ResponseModel response;
      if(!isFromEarnWithBlueEra){
        response = await ServiceAiRepo().deleteServiceRepo(serviceId: serviceId);
      }else{
        response = await EarnServiceRepo().deleteServiceRepo(serviceId: serviceId);
      }

      if (response.isSuccess) {
        deleteServiceResponse.value = ApiResponse.complete(response);
        Get.back();
        serviceDataList.removeWhere((service) => service.id == serviceId);
        serviceDataList.refresh();

        // if(isFromEarnWithBlueEra){
        //   final viewPersonalDetailsController = Get.isRegistered<ViewPersonalDetailsController>()
        //       ? Get.find<ViewPersonalDetailsController>()
        //       : Get.put(ViewPersonalDetailsController());
        // earnServiceCreatedStatusGlobal = 'false';
        // viewPersonalDetailsController.getEarnServiceStatus();
        // }

        print('Total: ${serviceDataList.length}');
      } else {
        deleteServiceResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      deleteServiceResponse.value = ApiResponse.error('error');
      logs("stack trace--> $s");
    }finally{
      isDeleteServiceLoading.value = false;
    }
  }

  RxBool isSingleServiceLoading = false.obs;
  Rxn<GetServiceModel> singleServiceData = Rxn<GetServiceModel>();

  Future<void> fetchSingleServiceDataApi({required String serviceId}) async {
    try {
      isSingleServiceLoading.value = true;

      final response = await ServiceAiRepo().fetchSingleServiceDataApi(serviceId: serviceId);
      if (response.isSuccess) {
        singleServiceDataResponse.value = ApiResponse.complete(response);
        final singleServiceDetailsModel = GetServiceModel.fromJson(response.response!.data);
        singleServiceData.value = singleServiceDetailsModel;
      } else {
        print("API failed with status: ${response.statusCode}");
        singleServiceDataResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
      singleServiceDataResponse.value = ApiResponse.error('error');
    } finally {
      isSingleServiceLoading.value = false;
    }
  }

}

class ServiceCategoryOption {
  final String name;
  final String tagId;
  const ServiceCategoryOption({required this.name, required this.tagId});
}
