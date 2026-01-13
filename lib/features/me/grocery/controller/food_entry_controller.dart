import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/grocery/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/grocery/repo/food_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../view/food_ai_details_screen.dart';

class FoodEntryController extends GetxController {
  // Text Controllers
  final foodNameController = TextEditingController();
  final foodCategoryController = TextEditingController();

  // Observable selections for radio buttons
  var selectedFoodType = "Non-Veg".obs;
  var selectedCookingMethod = "Boiled".obs;

  // Observable for validation
  var isFormValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Re-validate whenever text changes
    foodNameController.addListener(validateForm);
    foodCategoryController.addListener(validateForm);
  }

  void validateForm() {
    isFormValid.value = foodNameController.text.trim().isNotEmpty &&
        foodCategoryController.text.trim().isNotEmpty;
  }

  Rx<FoodGenAiResModel>? aiFoodResModel = FoodGenAiResModel().obs;

  Future<void> onGenerate() async {
    if (isFormValid.value) {
      Get.back();
      try {
        ResponseModel response =
            await FoodRepo().getFoodAiGenerateRepo(reqBody: {
          "name": foodNameController.text,
          "foodType": selectedFoodType.value,
          "cookingMethod": selectedCookingMethod.value,
          "category": foodCategoryController.text
        });
        if (response.isSuccess) {
          final data = response.response?.data;
          aiFoodResModel?.value = FoodGenAiResModel.fromJson(data);

          Get.to(FoodDetailScreen(
            foodData: aiFoodResModel?.value ?? FoodGenAiResModel(),
          ));
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      } on Exception catch (e) {
        commonSnackBar(message: e.toString());
      }
    }
  }

  @override
  void onClose() {
    foodNameController.dispose();
    foodCategoryController.dispose();
    super.onClose();
  }
}
