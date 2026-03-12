import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/food/model/food_category_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodEntryController extends GetxController {
  // Text Controllers
  final foodNameController = TextEditingController();
  final foodCategoryController = TextEditingController();
  var categoryList = <Children>[].obs;
  // Observable selections for radio buttons
  var selectedFoodType = "Non-Veg".obs;
  var selectedCategoryId = "".obs;
  // Observable for validation
  var isFormValid = false.obs;

  RxList<File?> foodSearchImages = <File?>[null].obs;
  RxList<String> selectedCookingMethods = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Re-validate whenever text changes
    foodNameController.addListener(validateForm);
    foodCategoryController.addListener(validateForm);
  }

  void validateForm() {
    isFormValid.value =
        foodNameController.text.trim().isNotEmpty &&
        foodCategoryController.text.trim().isNotEmpty;
  }

  void toggleCookingMethod(String method) {
    if (selectedCookingMethods.contains(method)) {
      selectedCookingMethods.remove(method);
    } else {
      selectedCookingMethods.add(method);
    }
  }

  Future<void> pickImageForIndex(BuildContext context, int index) async {
    final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
      context,
      AppStrings.productImage,
    );

    if (selected != null && selected.isNotEmpty) {
      foodSearchImages[index] = File(selected.first);
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < foodSearchImages.length) {
      foodSearchImages[index] = null;
    }
  }

  Rx<FoodGenAiResModel>? aiFoodResModel = FoodGenAiResModel().obs;

  Future<void> onGenerate({required bool isCreateFromMissingProduct}) async {
    if (isFormValid.value) {
      try {
        ResponseModel response =
            await FoodRepo().getFoodAiGenerateRepo(reqBody: {
          "name": foodNameController.text,
          "foodType": selectedFoodType.value,
          "cookingMethod": selectedCookingMethods,
          "category": foodCategoryController.text
        });
        if (response.isSuccess) {
          final data = response.response?.data;
          aiFoodResModel?.value = FoodGenAiResModel.fromJson(data);

          Get.toNamed(
              RouteHelper.getFoodAiDetailScreenRoute(),
              arguments: {
                ApiKeys.argFoodGenAiResModel: aiFoodResModel?.value ?? FoodGenAiResModel(),
                ApiKeys.argIsCreateFromMissingProduct: isCreateFromMissingProduct,
              }
          );

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
