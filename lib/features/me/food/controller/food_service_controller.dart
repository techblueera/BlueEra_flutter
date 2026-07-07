import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/services/hive_services.dart';
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
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_gen_ai_res_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// Top-level so it can run in a background isolate via [compute]. Builds the
/// root food categories (with their nested `children`) for the drill-down.
///
/// The `jsonDecode(jsonEncode())` round-trip normalises types so the same
/// parser serves both fresh Dio maps and Hive-restored maps (cache + network).
List<GroceryNestedCategoryModel> _parseFoodNestedCategories(
    List<dynamic> raw) {
  return raw
      .map((e) => GroceryNestedCategoryModel.fromJson(
          jsonDecode(jsonEncode(e)) as Map<String, dynamic>))
      .toList();
}

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

  Rxn<CategoryFoodProductData> singleFoodProductData = Rxn<CategoryFoodProductData>();

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

  /// Append a freshly-created variant into the Source-of-Truth product list so
  /// the product card's variant count and the variant sheet both update live.
  void addLocalVariant(String productId, FoodVariants newVariant) {
    final productIndex = categoryFoundProductDataList.indexWhere(
      (p) => p.id.toString().trim() == productId.toString().trim(),
    );
    if (productIndex == -1) return;

    final product = categoryFoundProductDataList[productIndex];
    final variants = List<FoodVariants>.from(product.variants ?? []);

    // Guard against a double-insert if the same variant id comes back twice.
    if (newVariant.id != null &&
        variants.any((v) => v.id == newVariant.id)) {
      return;
    }

    variants.add(newVariant);
    categoryFoundProductDataList[productIndex] =
        product.copyWith(variants: variants);
    categoryFoundProductDataList.refresh();

    debugPrint("✅ Source of Truth: variant added to $productId");
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
    try {
      getFoodCategoryResponse.value = ApiResponse.initial("Initial");

      // 1) Cache-first — show the last-saved categories instantly while the
      //    network call refreshes them in the background. Parsing happens off
      //    the UI isolate via `compute`.
      final cachedRaw = HiveServices().getFoodSuperCategoriesRaw();
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final cached = await compute(_parseFoodNestedCategories, cachedRaw);
        if (cached.isNotEmpty) {
          foodNestedCateList.assignAll(cached);
          getFoodCategoryResponse.value =
              ApiResponse.complete(foodNestedCateList);
        }
      }

      // 2) Silent refresh from the network.
      final ResponseModel response =
          await FoodRepo().getFoodNestedCategoryRepo();

      if (response.isSuccess) {
        final data = response.response?.data;
        // Null-safe extraction — a missing/!List `data` previously threw
        // here, leaving the status at "Initial" so the shimmer span forever.
        final List<dynamic> rawList = (data is Map && data['data'] is List)
            ? data['data'] as List
            : const [];

        // Parse the categories off the UI isolate so a large response can't
        // freeze the shimmer; the screen renders them lazily either way.
        final parsed = rawList.isEmpty
            ? <GroceryNestedCategoryModel>[]
            : await compute(_parseFoodNestedCategories, rawList);

        foodNestedCateList.assignAll(parsed);
        getFoodCategoryResponse.value =
            ApiResponse.complete(foodNestedCateList);

        // Persist the fresh tree for the next cold start.
        if (rawList.isNotEmpty) {
          await HiveServices().saveFoodSuperCategoriesRaw(rawList);
        }
      } else if (foodNestedCateList.isEmpty) {
        // Only surface an error when we have no cached data to fall back on.
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getFoodCategoryResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      // Catch parse/network failures so the screen can't get stuck on the
      // shimmer and an unhandled async error can't crash on navigation.
      log('getFoodNestedCategoryApi error: $e\n$s');
      if (foodNestedCateList.isEmpty) {
        try {
          getFoodCategoryResponse.value =
              ApiResponse.error(AppStrings.somethingWentWrong);
        } catch (_) {}
      }
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

  /// Human-readable reason the variant form is invalid (shown inline in the
  /// add/update-variant sheet). `null` when there is nothing to flag.
  var variantFormError = RxnString();

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
    final name = nameController.text.trim();
    final quantity = quantityController.text.trim();
    final mrpText = mrpController.text.trim();
    final priceText = priceController.text.trim();

    final int? mrp = int.tryParse(mrpText);
    final int? sellingPrice = int.tryParse(priceText);

    // Surface the first relevant problem so the user knows *why* Submit is
    // disabled. Required-field emptiness is left to the field hints; the
    // message here focuses on the price rules, which aren't otherwise obvious.
    String? error;
    if (mrpText.isNotEmpty && (mrp == null || mrp <= 0)) {
      error = AppStrings.foodMrpMustBePositive.tr;
    } else if (priceText.isNotEmpty && (sellingPrice == null || sellingPrice <= 0)) {
      error = AppStrings.foodSellingPriceMustBePositive.tr;
    } else if (mrp != null && sellingPrice != null && sellingPrice > mrp) {
      error = AppStrings.foodSellingPriceExceedsMrp.tr;
    }
    variantFormError.value = error;

    isFormValid.value = name.isNotEmpty &&
        quantity.isNotEmpty &&
        mrp != null &&
        mrp > 0 &&
        sellingPrice != null &&
        sellingPrice > 0 &&
        sellingPrice <= mrp;
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
    variantFormError.value = null;
    // editingIndex = null;
  }

  /// Price-only validation used by the edit-variant-price sheet (which edits
  /// MRP & selling price but not name/quantity). Both must be > 0 and the
  /// selling price must not exceed MRP.
  void validateVariantPrice() {
    final int? mrp = int.tryParse(mrpController.text.trim());
    final int? sellingPrice = int.tryParse(priceController.text.trim());

    String? error;
    if (mrp == null || mrp <= 0) {
      error = AppStrings.foodMrpMustBePositive.tr;
    } else if (sellingPrice == null || sellingPrice <= 0) {
      error = AppStrings.foodSellingPriceMustBePositive.tr;
    } else if (sellingPrice > mrp) {
      error = AppStrings.foodSellingPriceExceedsMrp.tr;
    }
    variantFormError.value = error;
    isFormValid.value = error == null;
  }

  Future<void> createFoodProductViaAiApi(
      {
        required FoodGenAiData foodData,
        int? createMissingProductIndex}) async {
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

        if (newProductId == null || newProductId.isEmpty) {
          commonSnackBar(message: AppStrings.somethingWentWrong);
          return;
        }

        // Missing-product flow: stamp the new productId on the row so
        // MissingFoodItemsScreen would re-render to the "Add Stock"
        if (createMissingProductIndex != null) {
          missingProducts[createMissingProductIndex].productId = newProductId;
          missingProducts.refresh();
        }

        // Fetch the freshly-created product the same way
        // AddSingleFoodProductScreen does — gives us the fully hydrated
        await getSingleFoodProductApi(FoodId: newProductId);
        final List<FoodVariants> createdVariants = singleFoodProductData.value?.variants ?? <FoodVariants>[];

        await addSingleProductToInventory(
          productId: newProductId,
          selectedVariants: createdVariants,
          createMissingProductIndex: createMissingProductIndex,
        );
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

        // Refresh FoodMainScreen's Overview-tab data (popular dishes +
        // discount products) so the just-published item shows up the
        // moment the user lands back on it via Get.until below.
        if (Get.isRegistered<RestaurantController>() &&
            businessId.isNotEmpty) {
          final restaurantController = Get.find<RestaurantController>();
          restaurantController.fetchHomeData(businessId: businessId);
          restaurantController.fetchDiscountFoodProducts(
              businessId: businessId);
        }

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

  /// ─── Category showcase (food-service/api/foodProduct/category-showcase) ───
  /// Cross-category food product list rendered as "Suggested Products" at the
  /// bottom of the food category menu screen. TTL-guarded via
  /// [_foodShowcaseCache] so re-entering the screen within the cache window
  /// reuses the loaded list instead of refetching.
  Rx<ApiResponse> foodShowcaseResponse = ApiResponse.initial('Initial').obs;
  RxList<CategoryFoodProductData> foodShowcaseList =
      <CategoryFoodProductData>[].obs;
  RxBool isFoodShowcaseLoadingMore = false.obs;
  int _foodShowcasePage = 1;
  bool _foodShowcaseHasMore = true;
  static const int _foodShowcaseLimit = 50;
  bool get foodShowcaseHasMore => _foodShowcaseHasMore;

  final FetchCache _foodShowcaseCache = FetchCache();

  /// Fetch the showcase only when it isn't already loaded & fresh (TTL). Use on
  /// screen (re)entry; call [fetchFoodCategoryShowcase] for explicit refreshes.
  Future<void> fetchFoodCategoryShowcaseIfNeeded() async {
    if (_foodShowcaseCache.isFresh('food-showcase',
        hasData: foodShowcaseList.isNotEmpty)) {
      return;
    }
    await fetchFoodCategoryShowcase();
  }

  Future<void> fetchFoodCategoryShowcase({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        if (!_foodShowcaseHasMore || isFoodShowcaseLoadingMore.value) return;
        isFoodShowcaseLoadingMore.value = true;
      } else {
        foodShowcaseResponse.value = ApiResponse.loading('loading');
        _foodShowcasePage = 1;
        _foodShowcaseHasMore = true;
      }

      final Map<String, dynamic> params = {
        ApiKeys.page: _foodShowcasePage,
        ApiKeys.limit: _foodShowcaseLimit,
      };

      final response =
          await FoodRepo().getFoodCategoryShowcaseRepo(queryParam: params);

      if (!response.isSuccess) {
        if (!isLoadMore && foodShowcaseList.isEmpty) {
          foodShowcaseResponse.value = ApiResponse.error('error');
        }
        return;
      }

      final data = response.response?.data;
      final List rawList =
          (data is Map && data['data'] is List) ? data['data'] as List : const [];
      final newItems =
          rawList.map((e) => CategoryFoodProductData.fromJson(e)).toList();

      if (isLoadMore) {
        foodShowcaseList.addAll(newItems);
      } else {
        foodShowcaseList.assignAll(newItems);
      }
      if (newItems.isNotEmpty) _foodShowcasePage++;

      final pagination = (data is Map) ? data['pagination'] : null;
      if (pagination is Map) {
        final page = int.tryParse('${pagination['page'] ?? 1}') ?? 1;
        final totalPages = int.tryParse('${pagination['totalPages'] ?? 1}') ?? 1;
        _foodShowcaseHasMore = page < totalPages;
      } else {
        _foodShowcaseHasMore = newItems.isNotEmpty;
      }

      foodShowcaseResponse.value = ApiResponse.complete(foodShowcaseList);
      _foodShowcaseCache.mark('food-showcase');
      log('food showcase loaded -- ${foodShowcaseList.length}');
    } catch (e, s) {
      log('food showcase stack trace -- $s');
      if (!isLoadMore && foodShowcaseList.isEmpty) {
        foodShowcaseResponse.value = ApiResponse.error('error');
      }
    } finally {
      if (isLoadMore) isFoodShowcaseLoadingMore.value = false;
    }
  }
}
