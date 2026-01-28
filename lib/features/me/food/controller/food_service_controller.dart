import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import '../../../common/food/model/food_category_res_model.dart';

class FoodServiceController extends GetxController {
  Rx<ApiResponse> getFoodCategoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getFoodByCategoryIDResponse =
      ApiResponse.initial('Initial').obs;
  RxList<FoodCategoryData> foodSubCateList = <FoodCategoryData>[].obs;
  RxList<CategoryFoodProductData> categoryFoodProductDataList =
      <CategoryFoodProductData>[].obs;
  RxString selectedSubFoodTypeIDCat = "".obs;
  RxString selectedFoodTypeID = "".obs;
  var selectedCategoryId = '1'.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  void changeCategory(String id) {
    selectedCategoryId.value = id;
  }

  Future<void> getFoodCategoryController() async {
    getFoodCategoryResponse.value = ApiResponse.initial("Initial");
    ResponseModel response = await FoodRepo().getFoodCategoryRepo();
    if (response.isSuccess) {
      List rawList = response.response?.data['data'];
      foodSubCateList.value =
          rawList.map((e) => FoodCategoryData.fromJson(e)).toList();
      getFoodCategoryResponse.value = ApiResponse.complete(foodSubCateList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getFoodCategoryResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> getFoodByCategoryIDController(
      {required String categoryId}) async {
    categoryFoodProductDataList.clear();
    getFoodByCategoryIDResponse.value = ApiResponse.initial("Initial");
    ResponseModel response =
        await FoodRepo().getFoodByCategoryIdRepo(catID: categoryId);
    if (response.isSuccess) {
      List rawList = response.response?.data['data'];
      categoryFoodProductDataList.value =
          rawList.map((e) => CategoryFoodProductData.fromJson(e)).toList();
      getFoodByCategoryIDResponse.value =
          ApiResponse.complete(categoryFoodProductDataList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getFoodByCategoryIDResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  // Text Controllers
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final mrpController = TextEditingController();
  final priceController = TextEditingController();
  var foodImages = <XFile>[].obs;

  // Observable list of variants
  var variantList = <Map<String, dynamic>>[].obs;
  var isFormValid = false.obs;

  void removeImage(int index, RxList<XFile> targetList) {
    targetList.removeAt(index);
  }

  // Track if we are editing an item
  int? editingIndex;

  void validate() {
    isFormValid.value = nameController.text.trim().isNotEmpty &&
        quantityController.text.trim().isNotEmpty &&
        mrpController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty;
  }

  Future<void> addOrUpdateVariant({
    required String foodId,
  }) async {
    final variant = {
      "variantName": nameController.text.trim(),
      "mrp": int.tryParse(mrpController.text.trim()) ?? 0,
      "quantityLabel": quantityController.text.trim(),
      "baseSellingPrice": int.tryParse(priceController.text.trim()) ?? 0,
      "isDefault": false
    };

    if (editingIndex != null) {
      // Update existing
      variantList[editingIndex!] = variant;
    } else {
      // Add new
      variantList.add(variant);
      if (foodId.isNotEmpty) {
        try {
          // call repo
          final responseModel = await FoodRepo().addFoodVariantRepo(
              params: {"variantData": variant}, foodID: foodId);

          if (responseModel.isSuccess) {
            commonSnackBar(
                message: responseModel.message ?? AppStrings.success);

            Get.until((route) =>
                route.settings.name ==
                RouteHelper.getBottomNavigationBarScreenRoute());
          } else {
            commonSnackBar(
                message:
                    responseModel.message ?? AppStrings.somethingWentWrong);
          }
        } catch (e, s) {
          print('stack trace-- $s');
          commonSnackBar(message: e.toString());
        }
      }
    }

    clearAllField();
  }

  void deleteVariant(int index) {
    variantList.removeAt(index);
  }

  void prepareEdit(int index) {
    editingIndex = index;
    final item = variantList[index];
    nameController.text = item['variantName'];
    mrpController.text = item['mrp'].toString();
    quantityController.text = item['quantityLabel'];
    priceController.text = item['baseSellingPrice'].toString();
    validate(); // Refresh validation for edit mode
  }

  void clearAllField() {
    nameController.clear();
    quantityController.clear();
    mrpController.clear();
    priceController.clear();
    isFormValid.value = false;
    editingIndex = null;
  }

  void validateVariantPrice() {
    isFormValid.value = mrpController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty;
  }

  Future<void> createFoodProductViaAiApi(
      {required FoodGenAiData foodData}) async {
    try {
      Map<String, dynamic> paramsReq = {};

      // prepare product details json
      final productDetailsMap = {
        "name": foodData.name,
        "category": selectedSubFoodTypeIDCat.value,
        "dietaryType": foodData.dietaryType,
        "ingredients": foodData.ingredients
      };
      paramsReq["productData"] = productDetailsMap;
      paramsReq['variantData'] = variantList;

      List<String> uploadedImages = [];
      for (int i = 0; i < foodImages.length; i++) {
        UploadResult? result =
            await S3UploadService.uploadFile(File(foodImages[i].path));
        if (result.isSuccess) {
          uploadedImages.add(result.url);
        } else {
          commonSnackBar(message: "Image upload failed");
        }
      }
      if (uploadedImages.isNotEmpty)
        paramsReq["productImages"] = uploadedImages;

      // call repo
      final responseModel =
          await FoodRepo().createFoodCategoryRepo(params: paramsReq);

      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? AppStrings.success);

        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      print('stack trace-- $s');
      commonSnackBar(message: e.toString());
    }
  }

  Future<void> updateFoodProductVariantPriceController(
      {required FoodVariants variantData, required String foodTyeID}) async {
    try {
      // prepare product details json
      final productDetailsMap = {
        "variantData": [
          {
            "_id": variantData.id,
            "baseSellingPrice": priceController.text,
            "mrp": mrpController.text,
            "quantityLabel": variantData.quantityLabel
          }
        ]
      };

      // call repo
      final responseModel = await FoodRepo()
          .updateFoodVariantRepo(params: productDetailsMap, foodID: foodTyeID);

      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? AppStrings.success);

        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      print('stack trace-- $s');
      commonSnackBar(message: e.toString());
    }
  }

  addKitchenInventoryController({required CategoryFoodProductData data}) async {
    try {
      List<dynamic> tempReqList = [];
      data.variants?.forEach((vData) {
        var reqData = {
          "productVariant": vData.id,
          "product": data.id,
          "location": {
            "type": "Point",
            "coordinates": [LocationService.lat, LocationService.lng],
            "address":
                LocationService.userCurrentAddress.value.formattedAddress,
            "pincode": LocationService.userCurrentAddress.value.postalCode
          },
          "price": {
            "mrp": vData.mrp,
            "sellingPrice": vData.baseSellingPrice,
            "currency": "INR",
            "packingCharges": 20
          },
          "isAvailable": vData.isActive,
          "preparationTime": 30
        };

        tempReqList.add(reqData);
      });
      // call repo
      final responseModel =
          await FoodRepo().addKitchenInventoryRepo(params: tempReqList);

      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? AppStrings.success);

        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs(e.toString());
    }
  }
}
