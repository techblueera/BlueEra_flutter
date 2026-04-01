import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/apiService/s3_image_uploader.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/date_time_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/add_tiffin_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/tiffin_meal_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/tiffin_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TiffinController extends GetxController {
  final TiffinRepo _repo = TiffinRepo();

  // meal data per key — empty by default (no id = not created)
  final Map<MealType, Rx<TiffinMealModel>> mealData = {
    MealType.morningTiffin:
        TiffinMealModel(mealType: MealType.morningTiffin).obs,
    MealType.breakfast: TiffinMealModel(mealType: MealType.breakfast).obs,
    MealType.eveningDinner:
        TiffinMealModel(mealType: MealType.eveningDinner).obs,
  };

  // loading per key
  final RxBool isLoading = false.obs;

  final RxBool isSubmitting = false.obs;
  final Rx<MealType?> currentEditType = Rx<MealType?>(null);

  // Form fields
  final foodCenterController = TextEditingController();
  final tiffinNameController = TextEditingController();
  final mrpPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();

  final Rx<File?> tiffinImageFile = Rx<File?>(null);
  final RxString selectedFoodType = ''.obs;
  final RxString selectedCookingMethod = ''.obs;
  final RxString selectedStartTime = ''.obs;
  final RxString selectedEndTime = ''.obs;

  final formKey = GlobalKey<FormState>();

  final foodTypeList = ['Veg', 'Non-Veg', 'Vegan'].obs;
  final cookingMethodList =
      ['Boiled', 'Fried', 'Grilled', 'Steamed', 'Baked'].obs;
  final startTimeList = generateFullDayTimeList().obs;
  final endTimeList = generateFullDayTimeList().obs;

  final RxBool isCenterLoading = false.obs;
  final RxBool isCenterNameAvailable = false.obs;
  final RxBool isCenterNameEditing = false.obs;

  void enableCenterNameEdit() {
    isCenterNameEditing.value = true;
  }

  bool get isUpdateMode {
    final type = currentEditType.value;
    if (type == null) return false;
    return mealData[type]?.value.hasData ?? false;
  }

  String? get currentMealId {
    final type = currentEditType.value;
    if (type == null) return null;
    return mealData[type]?.value.id;
  }

  Future<void> fetchAllMeals({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }

      final response = await _repo.fetchAllMeals();
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong.tr);
        return;
      }

      final tiffinResponse = TiffinResponseModel.fromJson(
        response.response!.data,
      );

      if (tiffinResponse.success) {
        isCenterNameAvailable.value = tiffinResponse.centerName.isNotEmpty;
        if (isCenterNameAvailable.value) {
          foodCenterController.text = tiffinResponse.centerName;
        }
        for (final meal in tiffinResponse.data) {
          // Only update if key exists in mealData
          if (mealData.containsKey(meal.mealType)) {
            mealData[meal.mealType]?.value = meal;
          }
        }
      }
    } catch (e) {
      // stays empty → shows dummy UI
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  //  Open bottom sheet for CREATE (no prefill)
  void openCreateSheet(MealType type) {
    currentEditType.value = type;
    _clearForm();
  }

  //  Open bottom sheet for EDIT (prefill from model)
  void openEditSheet(TiffinMealModel meal) {
    currentEditType.value = meal.mealType;
    tiffinNameController.text = meal.tiffinName;
    mrpPriceController.text = meal.mrpPrice;
    sellingPriceController.text = meal.sellingPrice;
    selectedFoodType.value = meal.selectedFoodType;
    selectedCookingMethod.value = meal.selectedCookingMethod;
    selectedStartTime.value = meal.selectedStartTime;
    selectedEndTime.value = meal.selectedEndTime;
    tiffinImageFile.value =
        meal.imagePath != null ? File(meal.imagePath!) : null;
  }

  //  Create or Update based on id
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

    final startError =
        ValidationMethod.validateStartTime(selectedStartTime.value);
    if (startError != null) {
      commonSnackBar(message: startError);
      return;
    }

    final endError = ValidationMethod.validateEndTime(
        selectedStartTime.value, selectedEndTime.value);
    if (endError != null) {
      commonSnackBar(message: endError);
      return;
    }

    final type = currentEditType.value;
    if (type == null) return;

    // Prepare images
    final hasNewImage = tiffinImageFile.value != null;
    final images = hasNewImage ? _prepareTiffinImage() : <UploadS3ImageModel>[];

    try {
      isSubmitting.value = true;

      ResponseModel response;

      if (isUpdateMode) {
        //  UPDATE
        response = await _repo.updateMeal(
          id: currentMealId!,
          data: _buildPayload(
              type: type,
              images: hasNewImage
                  ? images.map((img) => img.mimeType).toList()
                  : null,
          ),
        );
        commonSnackBar(message: 'Updated successfully');
      } else {
        //  CREATE
        response = await _repo.createMeal(
          data: _buildPayload(
              type: type, images: images.map((img) => img.mimeType).toList()),
        );
        commonSnackBar(message: 'Created successfully');
      }

      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong.tr);
        return;
      }

      final addTiffinResponseModel = AddTiffinResponseModel.fromJson(
        response.response!.data,
      );

      if (images.isNotEmpty) {
        final preSignedUrls = addTiffinResponseModel.uploadUrls;

        final uploader = S3ImageUploader();
        uploader.reset();

        final assigned = uploader.assignPreSignedUrls(
          images: images,
          preSignedUrls: preSignedUrls,
        );
        if (!assigned) return;

        final uploadSuccess = await uploader.uploadAll(images);
        if (!uploadSuccess) {
          commonSnackBar(message: 'Image upload failed. Please try again.');
          return;
        }
      }

      await fetchAllMeals();
      Get.back();
    } catch (e) {
      commonSnackBar(message: 'Something went wrong');
    } finally {
      isSubmitting.value = false;
    }
  }

  List<UploadS3ImageModel> _prepareTiffinImage() {
    final file = tiffinImageFile.value;
    if (file == null) return [];

    final imageInfo = getFileInfo(file);
    if (imageInfo.isEmpty) return [];

    return [
      UploadS3ImageModel(
        path: file.path,
        mimeType: imageInfo['mimeType'] ?? 'image/jpeg',
      ),
    ];
  }

  Map<String, dynamic> _buildPayload({
    required MealType type,
    List<String>? images,
  }) {
    return {
      'tiffinKey': type.name,
      'tiffinName': tiffinNameController.text.trim(),
      'lat': LocationService.lat,
      'long': LocationService.lng,
      'foodType': selectedFoodType.value,
      'cookingMethod': selectedCookingMethod.value,
      'sellingPrice': sellingPriceController.text.trim(),
      'mrp': mrpPriceController.text.trim(),
      'tiffinTiming': {
        'start': selectedStartTime.value,
        'end': selectedEndTime.value,
      },
      'images': images,
      'isActive': true
    };
  }

  //  Toggle go live — optimistic update then API
  Future<void> toggleGoLive(MealType type, bool value) async {
    final meal = mealData[type]?.value;
    if (meal == null || !meal.hasData) return;

    mealData[type]?.value = meal.copyWith(isLive: value); // optimistic

    try {
      Map<String, dynamic> params = {'tiffinKey': type.name, 'isActive': value};
      await _repo.toggleGoLive(id: meal.id!, data: params);
    } catch (e) {
      mealData[type]?.value = meal.copyWith(isLive: !value); // revert
      commonSnackBar(message: 'Failed to update');
    }
  }

  Future<void> submitCenterName() async {
    final name = foodCenterController.text.trim();

    if (name.isEmpty) {
      commonSnackBar(message: 'Please enter food centre name');
      return;
    }

    try {
      isCenterLoading.value = true;

      final data = {'centerName': name};
      ResponseModel response;

      if (isCenterNameAvailable.value) {
        //  UPDATE
        response = await _repo.updateCenterName(data: data);
      } else {
        // ADD
        response = await _repo.addCenterName(data: data);
      }

      if (response.isSuccess) {
        // await fetchAllMeals(showLoading: false);
        isCenterNameEditing.value = false; //
        isCenterNameAvailable.value = true;
        commonSnackBar(
          message: !isCenterNameAvailable.value
              ? 'Centre name updated!'
              : 'Centre name saved!',
        );
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong.tr);
      }
    } catch (e) {
      log('submitCenterName failed: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isCenterLoading.value = false;
    }
  }

  void _clearForm() {
    tiffinNameController.clear();
    mrpPriceController.clear();
    sellingPriceController.clear();
    tiffinImageFile.value = null;
    selectedFoodType.value = '';
    selectedCookingMethod.value = '';
    selectedStartTime.value = '';
    selectedEndTime.value = '';
  }

  Future<void> pickImage() async {
    final String? path = await SelectProfilePictureDialog.showLogoDialog(
        Get.context!, "Upload Picture");
    if (path != null && path.isNotEmpty) {
      tiffinImageFile.value = File(path);
    }
  }

  @override
  void onClose() {
    foodCenterController.dispose();
    tiffinNameController.dispose();
    mrpPriceController.dispose();
    sellingPriceController.dispose();
    super.onClose();
  }
}
