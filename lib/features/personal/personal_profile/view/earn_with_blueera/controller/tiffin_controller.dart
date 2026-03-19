import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/tiffin_meal_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/tiffin_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TiffinController extends GetxController {

  final TiffinRepo _repo = TiffinRepo();

  // ✅ meal data per key — empty by default (no id = not created)
  final Map<MealType, Rx<TiffinMealModel>> mealData = {
    MealType.morningTiffin: TiffinMealModel(mealType: MealType.morningTiffin).obs,
    MealType.breakfast:     TiffinMealModel(mealType: MealType.breakfast).obs,
    MealType.eveningDinner: TiffinMealModel(mealType: MealType.eveningDinner).obs,
  };

  // ✅ loading per key
  final RxBool isLoading = false.obs;

  final RxBool isSubmitting = false.obs;
  final Rx<MealType?> currentEditType = Rx<MealType?>(null);

  // Form fields
  final tiffinNameController   = TextEditingController();
  final mrpPriceController     = TextEditingController();
  final sellingPriceController = TextEditingController();

  final Rx<File?> tiffinImageFile      = Rx<File?>(null);
  final RxString selectedFoodType      = ''.obs;
  final RxString selectedCookingMethod = ''.obs;
  final RxString selectedStartTime     = ''.obs;
  final RxString selectedEndTime       = ''.obs;

  final formKey = GlobalKey<FormState>();

  final foodTypeList      = ['Veg', 'Non-Veg', 'Vegan', 'Eggetarian'].obs;
  final cookingMethodList = ['Boiled', 'Fried', 'Grilled', 'Steamed', 'Baked'].obs;
  final startTimeList     = generateFullDayTimeList().obs;
  final endTimeList       = generateFullDayTimeList().obs;


  @override
  void onInit() {
    super.onInit();
    fetchAllMeals(); // ✅ fetch on start
  }

  // ✅ Fetch all — called on init & after create/update
  Future<void> fetchAllMeals() async {
    for (final type in MealType.values) {
      fetchMealByType(type);
    }
  }

  MealType? _getMealType(String? type) {
    switch (type) {
      case 'morning_tiffin': return MealType.morningTiffin;
      case 'breakfast':      return MealType.breakfast;
      case 'evening_dinner': return MealType.eveningDinner;
      default:               return null;
    }
  }

  // ✅ Fetch single meal by key
  Future<void> fetchMealByType(MealType type) async {
    try {
      isLoading.value = true;
      final response = await _repo.fetchAllMeals();
      // if (response != null) {
      //   for (final item in response) {
      //     final type = _getMealType(item['meal_type']); // map string to enum
      //     if (type != null) {
      //       mealData[type]?.value = TiffinMealModel.fromJson(item, type);
      //     }
      //   }
      // }
      // if null → stays empty → shows dummy UI
    } catch (e) {
      // stays empty → shows dummy UI
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Open bottom sheet for CREATE (no prefill)
  void openCreateSheet(MealType type) {
    currentEditType.value = type;
    _clearForm();
  }

  // ✅ Open bottom sheet for EDIT (prefill from model)
  void openEditSheet(TiffinMealModel meal) {
    currentEditType.value        = meal.mealType;
    tiffinNameController.text    = meal.tiffinName;
    mrpPriceController.text      = meal.mrpPrice;
    sellingPriceController.text  = meal.sellingPrice;
    selectedFoodType.value       = meal.selectedFoodType;
    selectedCookingMethod.value  = meal.selectedCookingMethod;
    selectedStartTime.value      = meal.selectedStartTime;
    selectedEndTime.value        = meal.selectedEndTime;
    tiffinImageFile.value        = meal.imagePath != null ? File(meal.imagePath!) : null;
  }

  // ✅ Create or Update based on id
  Future<void> onGoLive() async {
    if (!formKey.currentState!.validate()) return;

    if (tiffinImageFile.value == null) {
      commonSnackBar(message: 'Please select tiffin image');
      return;
    }
    if (selectedFoodType.value.isEmpty) {
      commonSnackBar(message: 'Please select food type');
      return;
    }
    if (selectedCookingMethod.value.isEmpty) {
      commonSnackBar(message: 'Please select cooking method');
      return;
    }

    final startError = ValidationMethod.validateStartTime(selectedStartTime.value);
    if (startError != null) { commonSnackBar(message: startError); return; }

    final endError = ValidationMethod.validateEndTime(selectedStartTime.value, selectedEndTime.value);
    if (endError != null) { commonSnackBar(message: endError); return; }

    final type= currentEditType.value;
    if (type == null) return;

    final existing = mealData[type]?.value;
    final isUpdate = existing?.hasData ?? false; // ✅ has id = update

    try {
      isSubmitting.value = true;

      ResponseModel response;

      if (isUpdate) {
        // ✅ UPDATE
        response = await _repo.updateMeal(
          id:    existing!.id!,
          data:  _buildPayload(type, existing.id).toJson(),
        );
        commonSnackBar(message: 'Updated successfully');
      } else {
        // ✅ CREATE
        response = await _repo.createMeal(
          data:  _buildPayload(type, null).toJson(),
        );
        commonSnackBar(message: 'Created successfully');
      }

      // ✅ After create/update — fetch latest from API
      await fetchMealByType(type);
      Get.back();

    } catch (e) {
      commonSnackBar(message: 'Something went wrong');
    } finally {
      isSubmitting.value = false;
    }
  }

  TiffinMealModel _buildPayload(MealType type, String? id) {
    return TiffinMealModel(
      id:                    id,
      mealType:              type,
      tiffinName:            tiffinNameController.text,
      mrpPrice:              mrpPriceController.text,
      sellingPrice:          sellingPriceController.text,
      imagePath:             tiffinImageFile.value?.path,
      selectedFoodType:      selectedFoodType.value,
      selectedCookingMethod: selectedCookingMethod.value,
      selectedStartTime:     selectedStartTime.value,
      selectedEndTime:       selectedEndTime.value,
      isLive:                true,
    );
  }

  // ✅ Toggle go live — optimistic update then API
  Future<void> toggleGoLive(MealType type, bool value) async {
    final meal = mealData[type]?.value;
    if (meal == null || !meal.hasData) return;

    mealData[type]?.value = meal.copyWith(isLive: value); // optimistic

    try {
      // await ApiService.toggleGoLive(id: meal.id!, isLive: value);
    } catch (e) {
      mealData[type]?.value = meal.copyWith(isLive: !value); // revert
      commonSnackBar(message: 'Failed to update');
    }
  }

  void _clearForm() {
    tiffinNameController.clear();
    mrpPriceController.clear();
    sellingPriceController.clear();
    tiffinImageFile.value       = null;
    selectedFoodType.value      = '';
    selectedCookingMethod.value = '';
    selectedStartTime.value     = '';
    selectedEndTime.value       = '';
  }

  Future<void> pickImage() async {
    final String? path = await SelectProfilePictureDialog.showLogoDialog(Get.context!, "Upload Picture");
    if (path != null && path.isNotEmpty) {
      tiffinImageFile.value = File(path);
    }
  }

  @override
  void onClose() {
    tiffinNameController.dispose();
    mrpPriceController.dispose();
    sellingPriceController.dispose();
    super.onClose();
  }
}