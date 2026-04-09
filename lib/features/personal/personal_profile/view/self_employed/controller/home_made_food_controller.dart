import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/apiService/s3_image_uploader.dart';
import 'package:BlueEra/core/api/model/upload_s3_image_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/add_food_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_response_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeFoodController extends GetxController {
  final FoodRepo _repo = FoodRepo();

  //  Each category holds LIST of max 2 items (same as tiffin but list instead of single)
  final Map<FoodCategoryType, RxList<FoodItemModel>> categoryData = {
    FoodCategoryType.bakery: <FoodItemModel>[].obs,
    FoodCategoryType.namkeens: <FoodItemModel>[].obs,
    FoodCategoryType.sweets: <FoodItemModel>[].obs,
    FoodCategoryType.pickles: <FoodItemModel>[].obs,
  };

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  //  current editing state
  final Rx<FoodCategoryType?> currentEditCategory = Rx<FoodCategoryType?>(null);
  final Rx<FoodItemModel?> currentEditItem =
      Rx<FoodItemModel?>(null); // null = create

  // Form fields
  final itemNameController = TextEditingController();
  final mrpPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();

  final Rx<File?> foodImageFile = Rx<File?>(null);
  final RxString selectedFoodType = ''.obs;
  final RxString selectedCookingMethod = ''.obs;
  final formKey = GlobalKey<FormState>();

  final foodTypeList = ['Veg', 'Non-Veg', 'Vegan'].obs;
  final cookingMethodList =
      ['Boiled', 'Fried', 'Grilled', 'Steamed', 'Baked'].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllItems();
  }

  //  check if category can add more (max 2)
  bool canAddMore(FoodCategoryType type) {
    return (categoryData[type]?.length ?? 0) < 2;
  }

  bool get isUpdateMode => currentEditItem.value != null;

  String? get currentItemId => currentEditItem.value?.id;

  //  Open create sheet
  void openCreateSheet(FoodCategoryType type) {
    currentEditCategory.value = type;
    currentEditItem.value = null;
    _clearForm();
  }

  //  Open edit sheet — prefill
  void openEditSheet(FoodItemModel item) {
    currentEditCategory.value = item.categoryType;
    currentEditItem.value = item;
    itemNameController.text = item.foodName;
    mrpPriceController.text = item.mrpPrice;
    sellingPriceController.text = item.sellingPrice;
    selectedFoodType.value = item.foodType;
    selectedCookingMethod.value = item.cookingMethod;
    foodImageFile.value = item.imagePath != null ? File(item.imagePath!) : null;
  }

  Future<void> fetchAllItems() async {
    try {
      isLoading.value = true;

      final response = await _repo.fetchAllHomeMadeFoodItems();
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong.tr);
        return;
      }

      final foodResponse = FoodResponseModel.fromJson(response.response!.data);

      if (foodResponse.success) {
        for (final type in FoodCategoryType.values) {
          categoryData[type]?.clear();
        }
        for (final item in foodResponse.data) {
          if (categoryData.containsKey(item.categoryType)) {
            categoryData[item.categoryType]?.add(item);
          }
        }
      }
    } catch (e, s) {
      log('stack trace: $s');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onSubmit() async {
    if (!formKey.currentState!.validate()) return;

    if (foodImageFile.value == null && !isUpdateMode) {
      commonSnackBar(message: 'Please select item image');
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

    final type = currentEditCategory.value;
    if (type == null) return;

    final hasNewImage = foodImageFile.value != null;
    final List<UploadS3ImageModel> images  = hasNewImage ? _prepareImage() : [];

    try {
      isSubmitting.value = true;

      ResponseModel response;

      if (isUpdateMode) {
        response = await _repo.updateHomeMadeFood(
          id: currentItemId!,
          data: _buildPayload(
              type: type,
            images: hasNewImage
                ? images.map((img) => img.mimeType).toList()
                : null,
          ),
        );
      } else {
        response = await _repo.createHomeMadeFood(
          data: _buildPayload(
              type: type, images: images.map((img) => img.mimeType).toList()),
        );
      }

      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong.tr);
        return;
      }

      //  Upload image to S3
      if (images.isNotEmpty) {
        final addFoodResponse =
            AddFoodResponseModel.fromJson(response.response!.data);
        final preSignedUrls = addFoodResponse.uploadUrls;

        final uploader = S3ImageUploader();
        uploader.reset();

        final assigned = uploader.assignPreSignedUrls(
            images: images, preSignedUrls: preSignedUrls);
        if (!assigned) return;

        final uploadSuccess = await uploader.uploadAll(images);
        if (!uploadSuccess) {
          commonSnackBar(message: 'Image upload failed. Please try again.');
          return;
        }
      }

      commonSnackBar(
          message:
              isUpdateMode ? 'Updated successfully' : 'Added successfully');
      await fetchAllItems();
      Get.back();
    } catch (e) {
      log('onSubmit failed: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  List<UploadS3ImageModel> _prepareImage() {
    final file = foodImageFile.value;
    if (file == null) return [];
    final imageInfo = getFileInfo(file);
    if (imageInfo.isEmpty) return [];
    return [
      UploadS3ImageModel(
          path: file.path, mimeType: imageInfo['mimeType'] ?? 'image/jpeg')
    ];
  }

  Map<String, dynamic> _buildPayload({
    required FoodCategoryType type,
    List<String>? images,
  }) {
    return FoodItemModel(
            categoryType: type,
            foodName: itemNameController.text.trim(),
            foodType: selectedFoodType.value,
            cookingMethod: selectedCookingMethod.value,
            sellingPrice: sellingPriceController.text.trim(),
            mrpPrice: mrpPriceController.text.trim(),
            isLive: true,
            lat: LocationService.lat,
            lng: LocationService.lng,
            images: images ?? [])
        .toJson()
    // ✅ remove images key entirely if null (don't overwrite existing image on server)
      ..remove(images == null ? 'images' : null);
  }

  void _clearForm() {
    itemNameController.clear();
    mrpPriceController.clear();
    sellingPriceController.clear();
    foodImageFile.value = null;
    selectedFoodType.value = '';
    selectedCookingMethod.value = '';
  }

  Future<void> pickImage() async {
    final String? path = await SelectProfilePictureDialog.showLogoDialog(
        Get.context!, "Upload Picture");
    if (path != null && path.isNotEmpty) {
      foodImageFile.value = File(path);
    }
  }

  @override
  void onClose() {
    itemNameController.dispose();
    mrpPriceController.dispose();
    sellingPriceController.dispose();
    super.onClose();
  }
}
