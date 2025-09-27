import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/food/food_ai_res_model.dart';
import 'package:BlueEra/features/common/food/repo/food_ai_repo.dart';
import 'package:BlueEra/features/common/food/view/food_preview_screen.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;

class FoodUploadController extends GetxController {
  Rx<ApiResponse> foodAiResponse = ApiResponse.initial('Initial').obs;

  // Form controllers
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController cityNameController = TextEditingController();

  // Selected options
  final RxString foodName = "".obs;
  final RxString selectedFoodType1 = "Food Item".obs;
  final RxString selectedFoodType2 = "Non-Veg".obs;
  final RxString selectedCookingMethod = "Boiled".obs;
  final RxString selectedItemNature = "Break-Fast".obs;

  // Image selection
  final Rx<File?> selectedImage = Rx<File?>(null);

  // Loading state
  final RxBool isLoading = false.obs;

  // Food type 1 options
  final List<String> foodType1Options = ["Food Item", "Beverage"];

  // Food type 2 options
  final List<String> foodType2Options = [
    "Veg",
    "Non-Veg",
    "Vigan",
    "Dairy/Sweet"
  ];

  // Cooking method options
  final List<String> cookingMethodOptions = [
    "Cold Mix",
    "Boiled",
    "Oil Fried",
    "Deshi Ghee",
    "Oil + Ghee Mix",
    "Vegetable Ghee"
  ];

  // Item nature options
  final List<String> itemNatureOptions = [
    "All Time",
    "Break-Fast",
    "Dinner",
    "Snacks",
    "Lunch"
  ];


  // Show image picker dialog
Rx<FoodAiResModel> foodAiResponseModel=FoodAiResModel().obs;
  // Generate food data
  Future<void> generateFood() async {
    try {
      String fileName = selectedImage.value?.path.split('/').last ?? "";
      dio.MultipartFile? imageByPart = await dio.MultipartFile.fromFile(
          selectedImage.value?.path ?? "",
          filename: fileName);
      Map<String, dynamic> reqParm = {
        ApiKeys.product_details: jsonEncode({
          ApiKeys.product_name: foodNameController.text,
          ApiKeys.category: selectedItemNature.value,
          ApiKeys.keywords:
              "${selectedFoodType1.value}, ${selectedFoodType2.value},${selectedCookingMethod.value}",
          if (cityNameController.text.isNotEmpty)
            ApiKeys.city: cityNameController.text
        }),
        ApiKeys.images: imageByPart,
      };
      ResponseModel responseModel =
          await FoodAiRepo().aiFoodGenerateRepo(queryParam: reqParm);
      if (responseModel.isSuccess) {
         foodAiResponseModel.value =
            FoodAiResModel.fromJson(responseModel.response?.data);

        commonSnackBar(message: "Food added successfully");
        Get.to(FoodDetailScreen(foodData: responseModel.response?.data,));
        foodAiResponse.value = ApiResponse.complete(foodAiResponseModel);
      } else {
        foodAiResponse.value = ApiResponse.error('Failed to load feed');
      }
    } catch (e) {
      logs("ERROR===== ${e}");
      foodAiResponse.value = ApiResponse.error(e.toString());
    }
  }

  @override
  void onClose() {
    foodNameController.dispose();
    cityNameController.dispose();
    super.onClose();
  }
}
