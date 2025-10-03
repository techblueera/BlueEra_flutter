import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/business_service/model/service_ai_generate_model.dart';
import 'package:BlueEra/features/common/business_service/repo/service_ai_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/add_services_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;

class ServiceController extends GetxController {
  Rx<ApiResponse> serviceAiResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addServiceResponse = ApiResponse.initial('Initial').obs;

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
      {required Map<String, dynamic> serviceDetailsReq}) async {
    try {
      String fileName = selectedImage.value?.path.split('/').last ?? "";
      dio.MultipartFile? imageByPart = await dio.MultipartFile.fromFile(
          selectedImage.value?.path ?? "",
          filename: fileName);
      Map<String, dynamic> reqParam = {
        ApiKeys.service_details: jsonEncode(serviceDetailsReq),
        ApiKeys.images: imageByPart,
      };
      ResponseModel responseModel =
          await ServiceAiRepo().aiServiceGenerateRepo(queryParam: reqParam);
      if (responseModel.isSuccess) {
        serviceAiResModel.value =
            ServiceAiGenerateModel.fromJson(responseModel.response?.data);
        // commonSnackBar(message: "Service generated successfully");
        Get.to(AddServicesScreenNew(
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




  @override
  void onClose() {
    serviceNameController.dispose();
    serviceShortDescriptionController.dispose();
    super.onClose();
  }
}
