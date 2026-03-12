import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/food/model/food_snap_search_response.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/food/view/add_single_food_product_screen.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import '../../../common/food/model/food_category_res_model.dart';

class FoodServiceController extends GetxController {
  Rx<ApiResponse> getFoodCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getFoodByCategoryIDResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> foodSnapSearchResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSingleFoodProductResponse =
      ApiResponse.initial('Initial').obs;

  RxList<FoodCategoryData> foodSubCateList = <FoodCategoryData>[].obs;
  RxList<CategoryFoodProductData> categoryFoodProductDataList =
      <CategoryFoodProductData>[].obs;
  RxString selectedSubFoodTypeIDCat = "".obs;
  RxString selectedFoodTypeID = "".obs;
  var selectedCategoryId = '1'.obs;
  RxString selectedSubCategoryId = "".obs;
  RxList<Children> subCategoryTabs = <Children>[].obs;

  Rxn<CategoryFoodProductData> singleFoodProductData = Rxn<CategoryFoodProductData>();

  FoodProductSnapSearchData? productSnapSearchData;
  List<Map<String, String>> foodSnapSearchPhotos = [
    {
      'title': 'Upload Photo',
      'image': AppImageAssets.groceryImageFirst
    },
    {
      'title': 'Upload List',
      'image': AppImageAssets.groceryImageSecond
    },
  ];
  RxMap<String, File?> foodSnapSearchImagesMap = <String, File?>{}.obs;
  int maxUploadImages = 2;

  Future<List<String>?> pickImages(String title) async {
    final List<String>? selected =
    await SelectProductImageDialog.showLogoDialog(Get.context!, title);
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }
    return null;
  }


  /// Pick and replace image for a specific slot
  Future<void> addImagesByTitle(String title) async {
    final selectedImages = await pickImages(title);
    if (selectedImages == null || selectedImages.isEmpty) return;

    // We only need one image per slot, so we take the first one
    foodSnapSearchImagesMap[title] = File(selectedImages.first);
  }

  /// Remove image for a specific slot
  void removeImageByTitle(String title) {
    if (foodSnapSearchImagesMap.containsKey(title)) {
      foodSnapSearchImagesMap[title] = null;
      // Or foodSnapSearchImagesMap.remove(title);
    }
  }

  // Variant related var and methods
  RxMap<String, List<FoodVariants>> selectedVariantsMap = <String, List<FoodVariants>>{}.obs;

// Check if a specific variant is selected for a product
  bool isVariantSelected(String pId, String variantId) {
    return selectedVariantsMap[pId]?.any((v) => v.id == variantId) ?? false;
  }

  void updateLocalVariantPrice(
      String productId,
      String variantId,
      int newPrice,
      int newMrp,
      ) {
    // 1. Update the Price in the Main Global List (Source of Truth)
    int productIndex = categoryFoodProductDataList.indexWhere(
          (p) => p.id.toString().trim() == productId.toString().trim(),
    );

    if (productIndex != -1) {
      final product = categoryFoodProductDataList[productIndex];
      // Create a new list instance to ensure deep reactivity
      List<FoodVariants> variants = List<FoodVariants>.from(product.variants ?? []);

      int vIndex = variants.indexWhere(
            (v) => v.id.toString().trim() == variantId.toString().trim(),
      );

      if (vIndex != -1) {
        // Update specific variant and re-assign the list
        variants[vIndex] = variants[vIndex].copyWith(
          baseSellingPrice: newPrice,
          mrp: newMrp,
        );

        categoryFoodProductDataList[productIndex] = product.copyWith(variants: variants);
        categoryFoodProductDataList.refresh();
      }
    }

    // 2. Update the Price in the Selected Map (Payload for Posting)
    if (selectedVariantsMap.containsKey(productId)) {
      List<FoodVariants> selectedList = List.from(selectedVariantsMap[productId]!);
      int sIndex = selectedList.indexWhere(
            (v) => v.id.toString().trim() == variantId.toString().trim(),
      );

      if (sIndex != -1) {
        selectedList[sIndex] = selectedList[sIndex].copyWith(
          baseSellingPrice: newPrice,
          mrp: newMrp,
        );
        selectedVariantsMap[productId] = selectedList;
        selectedVariantsMap.refresh();
      }
    }
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
  var foodImages = <XFile?>[null, null].obs;

  // Observable list of variants
  var variantList = <FoodVariants>[].obs;
  var isFormValid = false.obs;

  /// Method for the second box only
  Future<void> pickSecondImage(BuildContext context) async {
    final List<String>? selected = await SelectProductImageDialog.showLogoDialog(
      context,
      AppStrings.productImage,
    );

    if (selected != null && selected.isNotEmpty) {
      XFile newFile = XFile(selected.first);
      foodImages.add(newFile);
    }
  }

  void removeSecondImage() {
    foodImages.removeAt(1);
  }

  // Track if we are editing an item
  // int? editingIndex;

  void validate() {
    isFormValid.value = nameController.text.trim().isNotEmpty &&
        quantityController.text.trim().isNotEmpty &&
        mrpController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty;
  }

  // Future<void> addOrUpdateVariant({
  //   required String foodId,
  // }) async {
  //   final variant = {
  //     "variantName": nameController.text.trim(),
  //     "mrp": int.tryParse(mrpController.text.trim()) ?? 0,
  //     "quantityLabel": quantityController.text.trim(),
  //     "baseSellingPrice": int.tryParse(priceController.text.trim()) ?? 0,
  //     "isDefault": false
  //   };
  //
  //   if (editingIndex != null) {
  //     // Update existing
  //     variantList[editingIndex!] = variant;
  //   } else {
  //     // Add new
  //     variantList.add(variant);
  //     if (foodId.isNotEmpty) {
  //       try {
  //         // call repo
  //         final responseModel = await FoodRepo().addFoodVariantRepo(
  //             params: {"variantData": variant}, foodID: foodId);
  //
  //         if (responseModel.isSuccess) {
  //           commonSnackBar(
  //               message: responseModel.message ?? AppStrings.success);
  //
  //           Get.until((route) =>
  //               route.settings.name ==
  //               RouteHelper.getBottomNavigationBarScreenRoute());
  //         } else {
  //           commonSnackBar(
  //               message:
  //                   responseModel.message ?? AppStrings.somethingWentWrong);
  //         }
  //       } catch (e, s) {
  //         print('stack trace-- $s');
  //         commonSnackBar(message: e.toString());
  //       }
  //     }
  //   }
  //
  //   clearAllField();
  // }


  void prepareEdit(int index) {
    // editingIndex = index;
    final item = variantList[index];
    nameController.text = item.variantName??'';
    mrpController.text = item.mrp.toString();
    quantityController.text = item.quantityLabel.toString();
    priceController.text = item.baseSellingPrice.toString();
    validate(); // Refresh validation for edit mode
  }

  void clearAllField() {
    nameController.clear();
    quantityController.clear();
    mrpController.clear();
    priceController.clear();
    isFormValid.value = false;
    // editingIndex = null;
  }

  void validateVariantPrice() {
    final double mrp = double.tryParse(mrpController.text) ?? 0;
    final double sellingPrice = double.tryParse(priceController.text) ?? 0;

    // Validation: Both must be > 0 and Selling Price <= MRP
    if (mrp > 0 && sellingPrice > 0 && sellingPrice <= mrp) {
      isFormValid.value = true;
    } else {
      isFormValid.value = false;
    }
  }

  Future<void> createFoodProductViaAiApi(
      {
        required FoodGenAiData foodData,
        required bool isCreateFromMissingProduct
      }) async {
    try {
      Map<String, dynamic> paramsReq = {};

      List<String> uploadedImages = [];

      // 1. Filter out nulls and loop through valid XFiles
      final validFiles = foodImages.whereType<XFile>().toList();

      if (validFiles.isEmpty) {
        commonSnackBar(message: "Please ensure the primary image is present.");
        return;
      }
      for (var xFile in validFiles) {
        UploadResult? result = await S3UploadService.uploadFile(File(xFile.path));

        if (result.isSuccess) {
          uploadedImages.add(result.url);
        } else {
          commonSnackBar(message: "One of the images failed to upload.");
          return; // Stop process if a single upload fails
        }
      }

      // prepare product details json
      final productDetailsMap = {
        "name": foodData.name,
        "description": foodData.description,
        "cookingMethod": foodData.cookingMethod,
        "category": selectedSubFoodTypeIDCat.value,
        "dietaryType": foodData.dietaryType,
        "ingredients": foodData.ingredients,
        if (uploadedImages.isNotEmpty) "images": uploadedImages
      };
      paramsReq["productData"] = productDetailsMap;
      paramsReq['variantData'] = variantList.map((v) => v.toJson()).toList();

      // call repo
      final responseModel =
          await FoodRepo().createFoodCategoryRepo(params: paramsReq);

      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? AppStrings.success);
        final String? newProductId = responseModel.response?.data['product']['_id'];

        if(!isCreateFromMissingProduct){
          Get.offNamedUntil(
            RouteHelper.getAddSingleProductScreenRoute(),
                (route) => route.settings.name == RouteHelper.getProductSelectionScreenRoute(),
            arguments: {
              ApiKeys.controller: this,
              ApiKeys.productId: newProductId,
            },
          );
        }else{
          Get.offNamedUntil(
            RouteHelper.getMissingFoodItemsScreenRoute(),
                (route) => route.settings.name == RouteHelper.getProductSelectionScreenRoute(),
            arguments: {
              ApiKeys.controller: this,
              ApiKeys.productId: newProductId,
            },
          );
        }


      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      print('stack trace-- $s');
      commonSnackBar(message: e.toString());
    }
  }

  // Future<void> updateFoodProductVariantPriceController(
  //     {required FoodVariants variantData, required String foodTyeID}) async {
  //   try {
  //     // prepare product details json
  //     final productDetailsMap = {
  //       "variantData": [
  //         {
  //           "_id": variantData.id,
  //           "baseSellingPrice": priceController.text,
  //           "mrp": mrpController.text,
  //           "quantityLabel": variantData.quantityLabel
  //         }
  //       ]
  //     };
  //
  //     // call repo
  //     final responseModel = await FoodRepo()
  //         .updateFoodVariantRepo(params: productDetailsMap, foodID: foodTyeID);
  //
  //     if (responseModel.isSuccess) {
  //       commonSnackBar(message: responseModel.message ?? AppStrings.success);
  //
  //       Get.until((route) =>
  //           route.settings.name ==
  //           RouteHelper.getBottomNavigationBarScreenRoute());
  //     } else {
  //       commonSnackBar(
  //           message: responseModel.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e, s) {
  //     print('stack trace-- $s');
  //     commonSnackBar(message: e.toString());
  //   }
  // }

  void bulkPublishInventory({bool isSnapSearch = false}) async {
    try {

      // 1. Check if there is anything to publish
      if (selectedVariantsMap.isEmpty) {
        commonSnackBar(message: "No products selected to publish.");
        return;
      }

      List<Map<String, dynamic>> tempReqList = [];

      // 2. Iterate through the Map (Key = ProductId, Value = List of Variants)
      selectedVariantsMap.forEach((productId, variants) {
        for (var vData in variants) {
          tempReqList.add({
            "productVariant": vData.id,
            "product": productId, // Using the Map Key as product ID
            "location": {
              "type": "Point",
              "coordinates": [LocationService.lat, LocationService.lng],
              "address": LocationService.userCurrentAddress.value.formattedAddress,
              "pincode": LocationService.userCurrentAddress.value.postalCode
            },
            "price": {
              "mrp": vData.mrp,
              "sellingPrice": vData.baseSellingPrice,
              "currency": "INR",
              "packingCharges": 20
            },
            "isAvailable": vData.isActive ?? true,
            "preparationTime": 30
          });
        }
      });
      // call repo
      final responseModel =
          await FoodRepo().addKitchenInventoryRepo(params: tempReqList);

      if (responseModel.isSuccess) {
        final bool hasNoMissingProducts = (productSnapSearchData?.missingProducts ?? []).isEmpty;
        final bool shouldGoToHome = !isSnapSearch || hasNoMissingProducts;

        if (shouldGoToHome) {
          Get.until((route) => route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
          commonSnackBar(message: responseModel.message ?? AppStrings.success);
          return;
        }

        Get.toNamed(
          RouteHelper.getMissingFoodItemsScreenRoute(),
          arguments: {
            ApiKeys.controller: this,
            ApiKeys.argMissingProducts: productSnapSearchData?.missingProducts,
          },
        );

        log('success-- ${responseModel.isSuccess}');
        commonSnackBar(message: responseModel.message ?? AppStrings.success);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs(e.toString());
    }
  }

  Future<void> fetchFoodSnapSearchApi() async {
    final List<File> validImages = foodSnapSearchImagesMap.values
        .where((file) => file != null)
        .cast<File>()
        .toList();

    if (validImages.isEmpty) {
      commonSnackBar(message: "Please upload at least 1 photo");
      return;
    }

    try {

      foodSnapSearchResponse.value = ApiResponse.loading('Loading');

      List<dio.MultipartFile> imageByPart = [];

      for (final file in validImages) {
        final fileName = file.path.split('/').last;
        imageByPart.add(
          await dio.MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        );
      }
      Map<String, dynamic> params = {
        ApiKeys.images : imageByPart
      };

      ResponseModel responseModel = await FoodRepo().fetchFoodSnapSearchRepo(
          params: params
      );
      if (responseModel.isSuccess) {
        foodSnapSearchResponse.value = ApiResponse.complete(responseModel);
        var grocerySnapSearchResponseModel = FoodSnapSearchResponseModel.fromJson(responseModel.response?.data);
        productSnapSearchData = grocerySnapSearchResponseModel.data;

        final found = grocerySnapSearchResponseModel.data?.foundProducts ?? [];

        // Extract only the productDetails and filter out nulls
        List<CategoryFoodProductData> extractedProducts = found
            .map((item) => item.productDetails)
            .whereType<CategoryFoodProductData>()
            .toList();

        categoryFoodProductDataList.assignAll(extractedProducts);

      } else {
        foodSnapSearchResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      foodSnapSearchResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    }
  }

  Future<void> getSingleFoodProductApi({required String FoodId}) async {
    try {
      getSingleFoodProductResponse.value = ApiResponse.loading("Initial");
      ResponseModel response =
      await FoodRepo().fetchSingleFoodProductDetailsRepo(foodID: FoodId);
      if (response.isSuccess) {
        singleFoodProductData.value =
            CategoryFoodProductData.fromJson(response.response?.data['data']);
        getSingleFoodProductResponse.value =
            ApiResponse.complete(singleFoodProductData);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getSingleFoodProductResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getSingleFoodProductResponse.value =
          ApiResponse.error(e.toString());
      debugPrint("Error adding to inventory: $e");
    }

  }

  Future<void> addSingleProductToInventory({
    required String productId,
    required List<FoodVariants> selectedVariants,
    bool isMissingFoodCreation = false
  }) async {
    try {
      // 1. Validation
      if (selectedVariants.isEmpty) {
        commonSnackBar(message: "Please select at least one variant.");
        return;
      }

      // 2. Prepare the Request List (The API expects a List of objects)
      List<Map<String, dynamic>> tempReqList = [];

      for (var vData in selectedVariants) {
        tempReqList.add({
          "productVariant": vData.id,
          "product": productId,
          "location": {
            "type": "Point",
            "coordinates": [LocationService.lat, LocationService.lng],
            "address": LocationService.userCurrentAddress.value.formattedAddress,
            "pincode": LocationService.userCurrentAddress.value.postalCode
          },
          "price": {
            "mrp": vData.mrp,
            "sellingPrice": vData.baseSellingPrice,
            "currency": "INR",
            "packingCharges": 20 // Default or from controller
          },
          "isAvailable": vData.isActive ?? true,
          "preparationTime": 30 // Default or from controller
        });
      }

      // 3. Call Repository
      final responseModel = await FoodRepo().addKitchenInventoryRepo(params: tempReqList);

      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? "Product added to inventory");
        if(isMissingFoodCreation){
          // logic for missing product creation flow
        }else{
          Get.until((route) => route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
        }
      } else {
        commonSnackBar(message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      debugPrint("Error adding to inventory: $e");
    }
  }


}
