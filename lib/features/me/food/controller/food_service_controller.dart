import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/food/model/food_snap_search_response.dart';
import 'package:BlueEra/features/me/food/model/food_product_response_model.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

class FoodServiceController extends GetxController {
  Rx<ApiResponse> getFoodCategoryResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getFoodByCategoryIDResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> foodSnapSearchResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSingleFoodProductResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getFoodCategoryWithInventoryResponse =
      ApiResponse.initial('Initial').obs;

  RxList<GroceryNestedCategoryModel> foodNestedCateList =
      <GroceryNestedCategoryModel>[].obs;

  RxList<CategoryFoodProductData> categoryFoundProductDataList =
      <CategoryFoodProductData>[].obs;
  RxList<MissingFoodProducts> missingProducts = <MissingFoodProducts>[].obs;

  RxString selectedSubFoodTypeIDCat = "".obs;
  RxString selectedFoodTypeID = "".obs;
  var isPosting = false.obs;
  var selectedCategoryId = '1'.obs;
  RxString selectedSubCategoryId = "".obs;
  RxList<GroceryNestedCategoryModel> subCategoryTabs =
      <GroceryNestedCategoryModel>[].obs;

  Rxn<CategoryFoodProductData> singleFoodProductData =
      Rxn<CategoryFoodProductData>();

  FoodProductSnapSearchData? productSnapSearchData;
  List<Map<String, String>> foodSnapSearchPhotos = [
    {
      'title': AppStrings.groceryUploadList,
      'icon': AppIconAssets.cameraAddOutlineIcon,
      'image': AppImageAssets.groceryImageFirst,
    },
    {
      'title': AppStrings.grocerySearchManually,
      'icon': AppIconAssets.search,
      'image': AppImageAssets.groceryImageSecond,
    },
  ];
  RxMap<String, File?> foodSnapSearchImagesMap = <String, File?>{}.obs;
  int maxUploadImages = 2;

  List<File> get validSnapSearchImages {
    return foodSnapSearchImagesMap.values.whereType<File>().toList();
  }

  Future<List<String>?> pickImages(String title) async {
    final List<String>? selected =
        await PhotoPickerService.pickMultiplePhotos(Get.context!, title);
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }
    return null;
  }

  Future<void> addImagesBySlot(String title) async {
    // 1. Prevent adding if something else is already there (Safety check)
    if (foodSnapSearchImagesMap.values.any((v) => v != null)) {
      commonSnackBar(message: AppStrings.foodPleaseRemoveCurrentImage.tr);
      return;
    }

    final selectedImages = await pickImages(title);
    if (selectedImages == null || selectedImages.isEmpty) return;

    foodSnapSearchImagesMap[title] = File(selectedImages.first);

    // Trigger the API call since an image was successfully added
    fetchFoodSnapSearchApi();
  }

  void removeImageBySlot(String title) {
    foodSnapSearchImagesMap[title] = null;
    foodSnapSearchImagesMap.refresh();
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
  RxMap<String, List<FoodVariants>> selectedVariantsMap =
      <String, List<FoodVariants>>{}.obs;

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
    // Only update the Main Global List (Source of Truth)
    int productIndex = categoryFoundProductDataList.indexWhere(
      (p) => p.id.toString().trim() == productId.toString().trim(),
    );

    if (productIndex != -1) {
      final product = categoryFoundProductDataList[productIndex];
      List<FoodVariants> variants =
          List<FoodVariants>.from(product.variants ?? []);

      int vIndex = variants.indexWhere(
        (v) => v.id.toString().trim() == variantId.toString().trim(),
      );

      if (vIndex != -1) {
        variants[vIndex] = variants[vIndex].copyWith(
          baseSellingPrice: newPrice,
          mrp: newMrp,
        );

        categoryFoundProductDataList[productIndex] =
            product.copyWith(variants: variants);
        categoryFoundProductDataList.refresh();

        debugPrint("✅ Source of Truth Updated for Variant: $variantId");
      }
    }
  }

  void changeCategory(String id) {
    selectedCategoryId.value = id;
  }

  void resetControllerFields() {
    // 1. Clear Lists & Maps
    categoryFoundProductDataList.clear();
    subCategoryTabs.clear();
    foodSnapSearchImagesMap.clear();
    selectedVariantsMap.clear();

    // 2. Reset Strings & IDs
    selectedSubFoodTypeIDCat.value = "";
    selectedFoodTypeID.value = "";
    selectedCategoryId.value = "1"; // Default back to '1'
    selectedSubCategoryId.value = "";

    // 3. Reset Rxn (Nullable objects)
    singleFoodProductData.value = null;

    // 4. Reset Objects/Data
    productSnapSearchData = null;
  }

  Future<void> getFoodNestedCategoryApi() async {
    getFoodCategoryResponse.value = ApiResponse.initial("Initial");
    ResponseModel response = await FoodRepo().getFoodNestedCategoryRepo();
    if (response.isSuccess) {
      List rawList = response.response?.data['data'];
      foodNestedCateList.value =
          rawList.map((e) => GroceryNestedCategoryModel.fromJson(e)).toList();
      getFoodCategoryResponse.value = ApiResponse.complete(foodNestedCateList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getFoodCategoryResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> getFoodByCategoryIDController({
    required Map<String, String> categoryIdParams,
  }) async {
    categoryFoundProductDataList.clear();
    getFoodByCategoryIDResponse.value = ApiResponse.initial("Initial");

    Map<String, dynamic> params = {
      ApiKeys.page: 1,
      ApiKeys.limit: 20,
    };

    params.addAll(categoryIdParams);

    ResponseModel response =
        await FoodRepo().getFoodByCategoryIdRepo(queryPatrams: params);
    if (response.isSuccess) {
      List rawList = response.response?.data['data'];
      categoryFoundProductDataList.value =
          rawList.map((e) => CategoryFoodProductData.fromJson(e)).toList();
      getFoodByCategoryIDResponse.value =
          ApiResponse.complete(categoryFoundProductDataList);
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
    final List<String>? selected =
        await PhotoPickerService.pickMultiplePhotos(
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

  Future<String?> addOrUpdateVariant(
      {required String foodId, required FoodVariants newVariant}) async {
    if (foodId.isNotEmpty) {
      try {
        // call repo
        final responseModel = await FoodRepo().addFoodVariantRepo(
            params: {"variantData": newVariant}, foodID: foodId);

        if (responseModel.isSuccess) {
          commonSnackBar(message: responseModel.message ?? AppStrings.success);

          if (Get.isRegistered<RestaurantController>()) {
            Get.find<RestaurantController>().foodDataNeedsRefresh = true;
          }

          String variantId = responseModel.response?.data['data']['_id'];

          return variantId;
          // Get.until((route) =>
          //     route.settings.name ==
          //     RouteHelper.getBottomNavigationBarScreenRoute());
        } else {
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
          return null;
        }
      } catch (e, s) {
        print('stack trace-- $s');
        commonSnackBar(message: e.toString());
        return null;
      }
    }
    return null;
  }

  void prepareEdit(int index) {
    // editingIndex = index;
    final item = variantList[index];
    nameController.text = item.variantName ?? '';
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
      {required FoodGenAiData foodData, int? createMissingProductIndex}) async {
    try {
      isPosting.value = true;
      Map<String, dynamic> paramsReq = {};

      List<String> uploadedImages = [];

      // 1. Filter out nulls and loop through valid XFiles
      final validFiles = foodImages.whereType<XFile>().toList();

      if (validFiles.isEmpty) {
        commonSnackBar(message: AppStrings.foodEnsurePrimaryImagePresent.tr);
        return;
      }
      for (var xFile in validFiles) {
        UploadResult? result =
            await S3UploadService.uploadFile(File(xFile.path));

        if (result.isSuccess) {
          uploadedImages.add(result.url);
        } else {
          commonSnackBar(message: AppStrings.foodImageUploadFailed.tr);
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
        final String? newProductId =
            responseModel.response?.data?['product']?['_id']?.toString();

        if (createMissingProductIndex == null) {
          Get.offNamedUntil(
            RouteHelper.getAddSingleProductScreenRoute(),
            (route) =>
                route.settings.name ==
                RouteHelper.getProductSelectionScreenRoute(),
            arguments: {
              ApiKeys.productId: newProductId,
              ApiKeys.argCreateMissingProductIndex: null
            },
          );
        } else {
          // if (createMissingProductIndex != -1) {
          missingProducts[createMissingProductIndex].productId = newProductId;
          missingProducts.refresh();

          Get.offNamedUntil(
            RouteHelper.getAddSingleProductScreenRoute(),
            (route) =>
                route.settings.name ==
                RouteHelper.getMissingFoodItemsScreenRoute(),
            arguments: {
              ApiKeys.controller: this,
              ApiKeys.productId: newProductId,
              ApiKeys.argCreateMissingProductIndex: createMissingProductIndex
            },
          );
          // }
        }
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      print('stack trace-- $s');
      commonSnackBar(message: e.toString());
    } finally {
      isPosting.value = false;
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
        commonSnackBar(message: AppStrings.foodNoProductsSelectedToPublish.tr);
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
            "isAvailable": vData.isActive ?? true,
            "preparationTime": 30
          });
        }
      });
      // call repo
      final responseModel =
          await FoodRepo().addKitchenInventoryRepo(params: tempReqList);

      if (responseModel.isSuccess) {
        // Refresh FoodMainScreen's Products tab data (popular dishes +
        // discount products) so the newly-added items show up when the
        // user lands back on it via Get.until below. Fire-and-forget;
        // both calls own their own loading state.
        if (Get.isRegistered<RestaurantController>() &&
            businessId.isNotEmpty) {
          final restaurantController = Get.find<RestaurantController>();
          restaurantController.fetchHomeData(businessId: businessId);
          restaurantController.fetchDiscountFoodProducts(
              businessId: businessId);
        }

        final bool hasNoMissingProducts =
            (productSnapSearchData?.missingProducts ?? []).isEmpty;
        final bool shouldGoToHome = !isSnapSearch || hasNoMissingProducts;

        if (shouldGoToHome) {
          Get.until((route) =>
              route.settings.name ==
              RouteHelper.getBottomNavigationBarScreenRoute());
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
    if (validSnapSearchImages.isEmpty) {
      commonSnackBar(message: AppStrings.foodPleaseUploadAtLeastOnePhoto.tr);
      return;
    }

    try {
      foodSnapSearchResponse.value = ApiResponse.loading('Loading');

      categoryFoundProductDataList.clear();
      missingProducts.clear();

      List<dio.MultipartFile> imageByPart = [];

      for (final file in validSnapSearchImages) {
        final fileName = file.path.split('/').last;
        imageByPart.add(
          await dio.MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        );
      }
      Map<String, dynamic> params = {ApiKeys.images: imageByPart};

      ResponseModel responseModel =
          await FoodRepo().fetchFoodSnapSearchRepo(params: params);
      if (responseModel.isSuccess) {
        foodSnapSearchResponse.value = ApiResponse.complete(responseModel);
        var grocerySnapSearchResponseModel =
            FoodSnapSearchResponseModel.fromJson(responseModel.response?.data);

        final found = grocerySnapSearchResponseModel.data?.foundProducts ?? [];
        final missing =
            grocerySnapSearchResponseModel.data?.missingProducts ?? [];

        // Extract only the productDetails and filter out nulls
        List<CategoryFoodProductData> extractedProducts = found
            .map((item) => item.productDetails)
            .whereType<CategoryFoodProductData>()
            .toList();

        categoryFoundProductDataList.assignAll(extractedProducts);
        missingProducts.assignAll(missing);
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
      getSingleFoodProductResponse.value = ApiResponse.initial("Initial");
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
      getSingleFoodProductResponse.value = ApiResponse.error(e.toString());
      debugPrint("Error adding to product: $e");
    }
  }

  Future<void> addSingleProductToInventory(
      {required String productId,
      required List<FoodVariants> selectedVariants,
      int? createMissingProductIndex}) async {
    try {
      // 1. Validation
      if (selectedVariants.isEmpty) {
        commonSnackBar(
            message: AppStrings.foodPleaseSelectAtLeastOneVariant.tr);
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
            "address":
                LocationService.userCurrentAddress.value.formattedAddress,
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
      final responseModel =
          await FoodRepo().addKitchenInventoryRepo(params: tempReqList);

      if (responseModel.isSuccess) {
        commonSnackBar(
            message:
                responseModel.message ?? AppStrings.foodProductAddedSuccess.tr);
        if (createMissingProductIndex == null) {
          Get.until((route) =>
              route.settings.name ==
              RouteHelper.getBottomNavigationBarScreenRoute());
        } else {
          // logic for missing product creation flow

          // if (createMissingProductIndex != -1) {
          final responseData = responseModel.response?.data['data'];
          if (responseData != null && (responseData as List).isNotEmpty) {
            final firstItem = responseData[0];

            missingProducts[createMissingProductIndex].inventoryId =
                firstItem['_id']?.toString() ?? "";

            // 3. Safe Image Extraction
            final List<dynamic>? images = firstItem['product']?['images'];
            missingProducts[createMissingProductIndex].inventoryImage =
                (images != null && images.isNotEmpty)
                    ? images.first.toString()
                    : "";

            // 4. IMPORTANT: Trigger the UI update
            missingProducts.refresh();
          }

          // }
          Get.until((route) =>
              route.settings.name ==
              RouteHelper.getMissingFoodItemsScreenRoute());
        }
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      debugPrint("Error adding to product: $e");
    }
  }

  /// My Product By Category
  RxList<CategoryFoodProductData> categoryMyFoodProductDataList =
      <CategoryFoodProductData>[].obs;
  RxBool isFoodCatProductsWithInvLoading = false.obs;
  RxBool isFoodCatProductsWithInvLoadingMore = false.obs;
  int foodCatProductsWithInvPage = 1;
  bool foodCatProductsWithInvHasMore = true;
  RxList<GroceryNestedCategoryModel> subSubFoodCat =
      <GroceryNestedCategoryModel>[].obs;

  Future<void> getMyFoodProductByCategoryIdApi(
      {required String categoryId, bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isFoodCatProductsWithInvLoadingMore.value = true;
      } else {
        isFoodCatProductsWithInvLoading.value = true;
        categoryMyFoodProductDataList.clear();
        foodCatProductsWithInvPage = 1;
        foodCatProductsWithInvHasMore = true;
      }

      Map<String, dynamic> queryParams = {
        ApiKeys.categoryId: categoryId,
        ApiKeys.businessId: businessId,
        ApiKeys.page: foodCatProductsWithInvPage,
        ApiKeys.limit: 20
      };

      ResponseModel response =
          await FoodRepo().getMyFoodProductByCategoryIdRepo(
        queryParam: queryParams,
      );
      if (response.isSuccess) {
        var myFoodProductResponseModel =
            FoodProductResponseModel.fromJson(response.response?.data);

        List<CategoryFoodProductData> newItems =
            (myFoodProductResponseModel.data ?? [])
                .where((item) =>
                    item.productDetails != null) // Filter out nulls for safety
                .map((item) =>
                    item.productDetails!) // Extract the internal productDetails
                .toList();

        if (newItems.isNotEmpty) {
          if (isLoadMore) {
            categoryMyFoodProductDataList.addAll(newItems);
          } else {
            categoryMyFoodProductDataList.assignAll(newItems);
          }

          foodCatProductsWithInvPage++;
        } else {
          foodCatProductsWithInvHasMore = false;
        }
        log('total food products-- ${categoryMyFoodProductDataList.length}');
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      log('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isFoodCatProductsWithInvLoadingMore.value = false;
      } else {
        isFoodCatProductsWithInvLoading.value = false;
      }
    }
  }
}
