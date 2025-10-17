import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/common/business_service/model/service_ai_generate_model.dart';
import 'package:BlueEra/features/common/business_service/repo/service_ai_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/add_services_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;

class ServiceController extends GetxController {
  Rx<ApiResponse> serviceAiResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addServiceResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getServiceResponse =
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

  // Loading state
  final RxBool isLoading = false.obs;

  // Show image picker dialog
  // Generate food data
  Rx<ServiceAiGenerateModel> serviceAiResModel = ServiceAiGenerateModel().obs;

  Future<void> generateServiceAiController(
      {
        String? channelId,
        required ProductServiceProviderType providerType,
        required Map<String, dynamic> serviceDetailsReq
      }) async {
    try {
      log('provider type-- ${providerType.title}');
      String fileName = selectedImage.value?.path.split('/').last ?? "";
      dio.MultipartFile? imageByPart = await dio.MultipartFile.fromFile(
          selectedImage.value?.path ?? "",
          filename: fileName);
      Map<String, dynamic> reqParam = {
        ApiKeys.service_details: jsonEncode(serviceDetailsReq),
        ApiKeys.images: imageByPart,
        // ApiKeys.providerType: providerType.title,
      };
      // if(channelId!=null){
      //   reqParam[ApiKeys.channelId] = channelId;
      // }
      ResponseModel responseModel =
          await ServiceAiRepo().aiServiceGenerateRepo(queryParam: reqParam);
      if (responseModel.isSuccess) {
        serviceAiResModel.value =
            ServiceAiGenerateModel.fromJson(responseModel.response?.data);
        // commonSnackBar(message: "Service generated successfully");
        Get.to(()=> AddServicesScreenNew(
          channelId: channelId,
          providerType: providerType,
          service: serviceAiResModel.value,
        ));/*    Get.to(ServiceDetailScreen(
          service: serviceAiResModel.value,
        ));*/

        serviceAiResponse.value = ApiResponse.complete(serviceAiResModel);
      } else {
        serviceAiResponse.value = ApiResponse.error('Failed to load');
      }
    } catch (e) {
      logs("ERROR===== ${e}");
      serviceAiResponse.value = ApiResponse.error(e.toString());
    }
  }


  /// All Service data
  RxList<GetServiceModel> serviceDataList = <GetServiceModel>[].obs;
  RxBool isServiceDataLoadingMore = false.obs;
  RxBool isServiceDataFirstLoading = false.obs;
  int serviceDataPage = 1;
  bool serviceDataHasMore = true;

  /// fetch services
  Future<void> getServices(Map<String, dynamic> queryParams, {bool isLoadMore = false}) async {
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
      ResponseModel response =
      await ServiceAiRepo().getServiceRepo(queryParams: queryParams);

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

  @override
  void onClose() {
    serviceNameController.dispose();
    serviceShortDescriptionController.dispose();
    super.onClose();
  }
}
