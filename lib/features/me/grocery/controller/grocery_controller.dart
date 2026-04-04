import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_products_response.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/view/edit_grocery_varient_dialog.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_varient_dialog.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PriceResult {
  final String sellingRange;
  final String mrpRange;
  final String discountRange;

  PriceResult({
    required this.sellingRange,
    required this.mrpRange,
    required this.discountRange,
  });
}

class GroceryController extends GetxController {
  bool groceryDataNeedsRefresh = false;

  Rx<ApiResponse> groceryCategoryResponse =
    ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> groceryCategoryOfChildrenResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createNewGroceryProductNewVariantResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addGroceryProductVariantResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchMyGroceryProductsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchMyGroceryCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchGroceryBusinessProductsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> grocerySnapSearchResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> missingGroceryProductRequestsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchNestedGroceryCategoryResponse =
      ApiResponse.initial('Initial').obs;

  final selectedGroceryData = Rxn<GroceryNestedCategoryModel>();

  RxList<GroceryProductData> selectedGroceries = <GroceryProductData>[].obs;

  RxInt selectedHorizontalTabIndex = 0.obs;
  String get currentTabKey =>
      selectedHorizontalTabIndex.value == 0
          ? (selectedGroceryData.value?.key ?? '')
          : selectedGroceryData.value?.children?.first.key ?? '';

  String get currentTabName =>
      selectedHorizontalTabIndex.value == 0
          ? (selectedGroceryData.value?.name ?? 'All Items')
          : selectedGroceryData.value?.children?.first.name ?? '';

  int maxLimit = 10;

  bool get isMaxLimitHit => selectedGroceries.length == maxLimit;

  RxMap<String, List<ProductVariants>> selectedProductVariants = <String, List<ProductVariants>>{}.obs;

  Rxn<ProductSnapSearchData> productSnapSearchData = Rxn<ProductSnapSearchData>();
  // RxList<FoundProducts> groceryFoundProducts = <FoundProducts>[].obs;

  final List<Map<String, String>> grocerySnapSearchConfig = [
    {
      'title': 'Upload Grocery List',
      'icon': AppIconAssets.cameraAddOutlineIcon,
      'image': AppImageAssets.groceryImageFirst,
    },
    {
      'title': 'Search Manually',
      'icon': AppIconAssets.search,
      'image': AppImageAssets.groceryImageSecond,
    },
  ];

// 2. Reactive Map to store captured files by their Title
  final RxMap<String, File?> grocerySnapSearchImagesMap = <String, File?>{}.obs;
  int maxUploadImages = 2;

  RxBool isSearchOpen = false.obs;

  void toggleSelection(GroceryProductData p) {
    if (selectedGroceries.contains(p)) {
      selectedGroceries.remove(p);
    } else {
      if (selectedGroceries.length >= 10) {
        commonSnackBar(
            message: 'You can’t select more than 10 products at a time.');
        return;
      }
      selectedGroceries.add(p);
    }
  }

  void toggleVariant(String productId, ProductVariants variant) {
    selectedProductVariants.putIfAbsent(productId, () => []);
    final selectedList = selectedProductVariants[productId]!;

    if (selectedList.any((v) => v.sId == variant.sId)) {
      selectedList.removeWhere((v) => v.sId == variant.sId);

      // If no variants left for this specific product, remove the key
      if (selectedList.isEmpty) {
        selectedProductVariants.remove(productId);
      }
    } else {
      selectedList.add(variant);
    }

    selectedProductVariants.refresh();
  }

  bool isVariantSelected(String productId, String variantId) {
    return selectedProductVariants[productId]?.any((v) => v.sId == variantId) ??
        false;
  }

  bool get canSubmitProducts {
    // Check if there is ANY list in the map that is NOT empty
    bool hasAtLeastOneVariant = selectedProductVariants.values.any((variants) => variants.isNotEmpty);

    print('--- Validation Check ---');
    print('Total Product Keys: ${selectedProductVariants.length}');
    print('Has at least one variant selected: $hasAtLeastOneVariant');

    return hasAtLeastOneVariant;
  }

  PriceResult getPriceDetails(List<Pricing>? v) {
    final pricingList = v;

    if (pricingList==null) {
      return PriceResult(
        sellingRange: "0",
        mrpRange: "0",
        discountRange: "0%",
      );
    }

    // Safely map → remove null → convert to double
    final sellingPrices = pricingList
        .map((e) => e.sellingPrice)
        .where((p) => p != null)
        .map((p) => p!.toDouble())
        .toList();

    final mrpPrices = pricingList
        .map((e) => e.mrp)
        .where((p) => p != null)
        .map((p) => p!.toDouble())
        .toList();

    if (sellingPrices.isEmpty || mrpPrices.isEmpty) {
      return PriceResult(
        sellingRange: "0",
        mrpRange: "0",
        discountRange: "0%",
      );
    }

    // Find MIN/MAX
    final minSelling = sellingPrices.reduce((a, b) => a < b ? a : b);
    final maxSelling = sellingPrices.reduce((a, b) => a > b ? a : b);

    final minMrp = mrpPrices.reduce((a, b) => a < b ? a : b);
    final maxMrp = mrpPrices.reduce((a, b) => a > b ? a : b);

    // Discount %
    double discount(num mrp, num selling) {
      if (mrp == 0) return 0;
      final d = ((mrp - selling) / mrp) * 100;
      return d < 0 ? 0 : d;
    }

    final minDiscount = discount(minMrp, minSelling);
    final maxDiscount = discount(maxMrp, maxSelling);

    // Format ranges
    final sellingRange = minSelling == maxSelling
        ? "₹$minSelling"
        : "₹$minSelling - ₹$maxSelling";

    final mrpRange = minMrp == maxMrp ? "₹$minMrp" : "₹$minMrp - ₹$maxMrp";

    final discountRange = minDiscount == maxDiscount
        ? "${minDiscount.toStringAsFixed(0)}% ${AppStrings.offCaps.tr}"
        : "${minDiscount.toStringAsFixed(0)}% - ${maxDiscount.toStringAsFixed(0)}% ${AppStrings.offCaps.tr}";

    return PriceResult(
      sellingRange: sellingRange,
      mrpRange: mrpRange,
      discountRange: discountRange,
    );
  }

  void openEditVariantDialog({
    required BuildContext context,
    required String title,
    required ProductVariants variant,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return EditGroceryVarientDialog(
          title: title,
          mrp: variant.pricing?[0].mrp?.toString() ?? "",
          selling: variant.pricing?[0].sellingPrice?.toString() ?? "",
          onSubmit: (mrp, sellingPrice) {
            if (variant.pricing != null && variant.pricing!.isNotEmpty) {
              variant.pricing![0] = variant.pricing![0].copyWith(
                mrp: num.tryParse(mrp),
                sellingPrice: num.tryParse(sellingPrice),
              );
            }
            Get.back();
            // variant.pricing?[0].mrp = int.tryParse(mrp);
            // variant.pricing?[0].sellingPrice = int.tryParse(sellingPrice);
            // refresh();
          },
        );
      },
    );
  }

  void openAddVariantDialog({
    required BuildContext context,
    required GroceryProductData groceryItem,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isCreateNewGroceryProductNewVariantLoading.value,
      builder: (_) {
        return GroceryVariantDialog(
          title: "Add More Variant",
          onSubmit: (quantity, unit, mrp, sellingPrice) {
            createNewGroceryProductNewVariant(
                groceryItem: groceryItem,
                productId: groceryItem.sId ?? '',
                quantity: quantity.trim(),
                unit: unit.trim(),
                mrp: mrp.trim(),
                sellingPrice: sellingPrice.trim());
          },
        );
      },
    );
  }

  Future<void> addImagesBySlot(String title) async {
    // 1. Prevent adding if something else is already there (Safety check)
    if (grocerySnapSearchImagesMap.values.any((v) => v != null)) {
      commonSnackBar(message: "Please remove the current image before selecting another type.");
      return;
    }

    final selectedImages = await pickImages(title);
    if (selectedImages == null || selectedImages.isEmpty) return;

    grocerySnapSearchImagesMap[title] = File(selectedImages.first);

    // Trigger the API call since an image was successfully added
    fetchGrocerySnapSearchApi();
  }

  void removeImageBySlot(String title) {
    grocerySnapSearchImagesMap[title] = null;
    grocerySnapSearchImagesMap.refresh();
  }

  Future<List<String>?> pickImages(String title) async {
    final List<String>? selected =
    await SelectProductImageDialog.showLogoDialog(Get.context!, title);
    return (selected != null && selected.isNotEmpty) ? selected : null;
  }

  RxBool isInitialLoading = false.obs;
  Future<void> fetchBoth() async {
    try {
      isInitialLoading.value = true;
      await Future.wait([
        // fetchChildrenOfGroceryCategory(),
        fetchGroceryCategoryProducts(),
      ]);
     } catch (e) {
    } finally {
      isInitialLoading.value = false;
    }
  }

  // RxBool isGroceryCategoryOfChildrenLoading = false.obs;
  // RxList<ChildrenOfGroceryCategoryResponse> arrChildrenOfGroceryCategory =
  //     <ChildrenOfGroceryCategoryResponse>[].obs;
  //
  // Future<void> fetchChildrenOfGroceryCategory() async {
  //   try {
  //
  //     isGroceryCategoryOfChildrenLoading.value = true;
  //     final response =
  //     await GroceryRepo().groceryCategoryOfChildrenRepo(key: currentTabKey);
  //
  //     if (!response.isSuccess) {
  //       commonSnackBar(
  //         message: response.message ?? AppStrings.somethingWentWrong,
  //       );
  //       return;
  //     }
  //
  //     final jsonData = response.response?.data;
  //     arrChildrenOfGroceryCategory.value =
  //         ChildrenOfGroceryCategoryResponse.fromJsonList(jsonData);
  //     groceryCategoryOfChildrenResponse.value = ApiResponse.complete(response);
  //     update();
  //   } catch (e) {
  //     groceryCategoryOfChildrenResponse.value = ApiResponse.error('error');
  //     update();
  //   } finally {
  //     isGroceryCategoryOfChildrenLoading.value = false;
  //   }
  // }

  RxBool isGroceryCategoryProductsLoading = false.obs;
  RxList<GroceryProductData> arrGroceryCategoryProducts = <GroceryProductData>[].obs;
  RxBool isGroceryCategoryProductsLoadingMore = false.obs;
  int groceryCategoryProductsPage = 1;
  bool groceryCategoryProductsHasMore = true;

  Future<void> fetchGroceryCategoryProducts({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        // if (isGroceryCategoryProductsLoadingMore.value || !groceryCategoryProductsHasMore) return;
        isGroceryCategoryProductsLoadingMore.value = true;
      } else {
        arrGroceryCategoryProducts.clear();
        isGroceryCategoryProductsLoading.value = true;
        groceryCategoryProductsPage = 1;
        groceryCategoryProductsHasMore = true;
      }

      // log('current tab key-- $currentTabKey');
      Map<String, dynamic> queryParams = {
        ApiKeys.key: currentTabKey,
        ApiKeys.page: groceryCategoryProductsPage,
        ApiKeys.limit: pageLimit
      };

      final response = await GroceryRepo()
          .searchGroceryCategoryRepo(queryParam: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      groceryCategoryResponse.value = ApiResponse.complete(response);

      final groceryProductModel = GroceryProductModel.fromJson(response.response?.data);
      List<GroceryProductData> newItems = groceryProductModel.data ?? [];

      if (newItems.isNotEmpty) {
          if (isLoadMore) {
            arrGroceryCategoryProducts.addAll(newItems);
          } else {
            arrGroceryCategoryProducts.assignAll(newItems);
          }

          groceryCategoryProductsPage++;
      } else {
        groceryCategoryProductsHasMore = false;
      }

      log('total grocery-- ${arrGroceryCategoryProducts.length}');
      update();
    } catch (e, s) {
      groceryCategoryResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isGroceryCategoryProductsLoadingMore.value = false;
      } else {
        isGroceryCategoryProductsLoading.value = false;
      }
    }
  }

  RxBool isCreateNewGroceryProductNewVariantLoading = false.obs;
  Future<void> createNewGroceryProductNewVariant(
      {required GroceryProductData groceryItem,
      required String productId,
      required String quantity,
      required String unit,
      required String mrp,
      required String sellingPrice}) async {
    try {
      isCreateNewGroceryProductNewVariantLoading.value = true;
      Map<String, dynamic> data = {
        ApiKeys.variantData: jsonEncode({
          ApiKeys.quantity: "$quantity $unit",
          ApiKeys.pricing: [
            {
              ApiKeys.mrp: int.tryParse(mrp),
              ApiKeys.sellingPrice: int.tryParse(sellingPrice),
            }
          ]
        })
      };

      final response = await GroceryRepo().createNewGroceryProductVariantRepo(
        productId: productId,
        params: data,
      );

      if (!response.isSuccess) {
        createNewGroceryProductNewVariantResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      createNewGroceryProductNewVariantResponse.value = ApiResponse.complete(response);
      final jsonData = response.response?.data;
      log('id-- > ${jsonData['_id']}');
      final newVariant = ProductVariants(
        quantity: "$quantity $unit",
        sId: jsonData['_id'],
        product: productId,
        variantName: "$quantity",
        pricing: [
          Pricing(
            mrp: int.tryParse(mrp),
            sellingPrice: int.tryParse(sellingPrice),
          )
        ],
        images: [],
        sku: null,
        barcode: null,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
        iV: 0,
      );

      groceryItem.variants?.insert(
        groceryItem.variants!.length,
        newVariant,
      );
      selectedGroceries.refresh();
      // update();
      Get.back();
    } catch (e) {
      createNewGroceryProductNewVariantResponse.value = ApiResponse.error('error');
    } finally {
      isCreateNewGroceryProductNewVariantLoading.value = false;
    }
  }

  RxBool isAddGroceryProductsLoading = false.obs;
  Future<void> addGroceryProductNewVariant({bool isSnapSearch = false}) async {
    try {
      isAddGroceryProductsLoading.value = true;

      final payload = buildInventoryPayload();
      if(payload.isEmpty) return;

      print(jsonEncode(payload));

      final response = await GroceryRepo().addGroceryProductVariantRepo(
        params: payload,
      );

      if (!response.isSuccess) {
        addGroceryProductVariantResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      addGroceryProductVariantResponse.value = ApiResponse.complete(response);
      groceryDataNeedsRefresh = true;

      final bool hasNoMissingProducts = (productSnapSearchData.value?.missingProducts ?? []).isEmpty;
      final bool shouldGoToHome = !isSnapSearch || hasNoMissingProducts;

      if (shouldGoToHome) {
        Get.until((route) => route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
        return;
      }

      Get.toNamed(
        RouteHelper.getMissingGroceryItemsScreenRoute(),
        arguments: {
          ApiKeys.controller: this,
          ApiKeys.argMissingProducts: productSnapSearchData.value!.missingProducts,
        },
      );

      commonSnackBar(
        message: response.message ?? AppStrings.somethingWentWrong,
      );
      log('success-- ${response.isSuccess}');
    } catch (e) {
      addGroceryProductVariantResponse.value = ApiResponse.error('error');
    } finally {
      isAddGroceryProductsLoading.value = false;
    }
  }

  List<Map<String, dynamic>> buildInventoryPayload() {
    List<Map<String, dynamic>> payload = [];
    final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController());
    final businessData = viewBusinessDetailsController.businessProfileDetails.value?.data;

    print("City (Profile): ${businessData?.cityStatePincode}");
    print("Pincode (Profile): ${businessData?.pincode}");

    String city = (businessData?.cityStatePincode != null && businessData!.cityStatePincode!.isNotEmpty)
        ? businessData.cityStatePincode!
        : LocationService.userCurrentAddress.value.city;
    String postalCode;
    if (businessData?.pincode == null || businessData?.pincode == 0) {
      postalCode = LocationService.userCurrentAddress.value.postalCode;
    } else {
      postalCode = businessData!.pincode.toString();
    }

    if (postalCode.isEmpty || postalCode == "0") {
      commonSnackBar(message: 'Please enable GPS or update business pincode');
    }

    selectedProductVariants.forEach((productId, variants) {
      for (final variant in variants) {
        payload.add({
          "productVariant": variant.sId ?? "",
          "pincode": postalCode,
          "cityName": city,
          "batches": [
            {
              "quantity": variant.quantity,
              "mrp": variant.pricing?[0].mrp,
              "sellingPrice": variant.pricing?[0].sellingPrice,
            }
          ],
        });
      }
    });

    return payload;
  }

  Future<void> fetchGrocerySnapSearchApi() async {
    // 1. Filter out the null values from the map to get actual files
    final List<File> activeImages = grocerySnapSearchImagesMap.values
        .where((file) => file != null)
        .cast<File>()
        .toList();

    // 2. Validate that at least one image is uploaded
    if (activeImages.isEmpty) {
      commonSnackBar(message: "Please upload at least 1 photo");
      return;
    }

    try {
      grocerySnapSearchResponse.value = ApiResponse.loading('Loading');

      productSnapSearchData.value = null;

      List<dio.MultipartFile> imageByPart = [];

      // 3. Iterate through the valid files only
      for (final image in activeImages) {
        final fileName = image.path.split('/').last;
        imageByPart.add(
          await dio.MultipartFile.fromFile(
            image.path,
            filename: fileName,
          ),
        );
      }

      Map<String, dynamic> params = {
        ApiKeys.images: imageByPart,
      };

      ResponseModel responseModel = await GroceryRepo().fetchGrocerySnapSearchRepo(
        params: params,
      );

      if (responseModel.isSuccess) {
        grocerySnapSearchResponse.value = ApiResponse.complete(responseModel);
        var grocerySnapSearchResponseModel =
        GrocerySnapSearchResponseModel.fromJson(responseModel.response?.data);
        productSnapSearchData.value = grocerySnapSearchResponseModel.data;
      } else {
        grocerySnapSearchResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      grocerySnapSearchResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    }
  }

  /// Fetch Grocery Products
  RxBool myGroceryLoading = true.obs;
  RxList<GroceryCategoryWithInventoryModel> groceryCategoryList = <GroceryCategoryWithInventoryModel>[].obs;
  RxList<BusinessProductData> groceryBusinessProductsList = <BusinessProductData>[].obs;

  Future<void> fetchAllGroceryData(String userId, {required bool otherStore}) async {
    try {
      myGroceryLoading.value = true;

      // 1. Run both repo calls in parallel
      await Future.wait([
        fetchGroceryCategoryWithInventory(userId, otherStore),
        fetchGroceryBusinessProductsRepo(userId, otherStore),
      ]);

    } catch (e) {
    } finally {
      myGroceryLoading.value = false;
    }
  }

  Future<void> fetchGroceryCategoryWithInventory(String userId, bool otherStore) async {
    try {

      fetchMyGroceryCategoryResponse.value = ApiResponse.initial('Initial');

      var params = {
        ApiKeys.businessId: userId
      };

      ResponseModel responseModel;
      if(!otherStore){
        responseModel = await GroceryRepo().fetchGroceryCategoryWithInventoryRepo(
            params: params
        );
      }
      else{
         responseModel = await GroceryRepo().fetchPublicGroceryCategoryWithInventoryRepo(
            params: params
        );
      }

      if (responseModel.isSuccess) {
        fetchMyGroceryCategoryResponse.value = ApiResponse.complete(responseModel);
        final List listData = responseModel.response?.data ?? [];

        groceryCategoryList.value = listData
            .map((e) => GroceryCategoryWithInventoryModel.fromJson(e))
            .toList();

        log("Loaded ${groceryCategoryList.length}");
      } else {
        fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
      log("ERROR===== $e");
     }
  }

  Future<void> fetchGroceryBusinessProductsRepo(String userId, bool otherStore) async {
    try {

      fetchGroceryBusinessProductsResponse.value = ApiResponse.initial('Initial');

      Map<String, dynamic> params = {
        ApiKeys.businessId: userId,
        ApiKeys.sortBy: "discount_high_to_low",
      };

      ResponseModel responseModel;
      if(!otherStore){
        responseModel = await GroceryRepo().fetchGroceryBusinessProductsRepo(
            params: params
        );
      }else{
        responseModel = await GroceryRepo().fetchPublicGroceryBusinessProductsRepo(
            params: params
        );
      }

      if (responseModel.isSuccess) {

        fetchGroceryBusinessProductsResponse.value = ApiResponse.complete(responseModel);
        var groceryBusinessProductsModel = GroceryBusinessProductsModel.fromJson(responseModel.response?.data);
        groceryBusinessProductsList.value = groceryBusinessProductsModel.data ?? [];

        log("Loaded ${groceryBusinessProductsList.length}");
      }else{
        fetchGroceryBusinessProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      fetchGroceryBusinessProductsResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    }
  }

  /// Fetch Grocery Products
  RxList<GroceryProductData> groceryProductsList = <GroceryProductData>[].obs;
  // RxList<Variants> myGroceryProductsVariantsList = <Variants>[].obs;
  RxBool isGroceryDataFirstLoading = false.obs;
  RxBool isGroceryDataLoadingMore = false.obs;
  int groceryDataPage = 1;
  bool groceryDataHasMore = true;
  int pageLimit = 20;

  Future<void> fetchGroceryProducts({
    required String userId,
    required String categoryId,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (isGroceryDataLoadingMore.value || !groceryDataHasMore) return;
      isGroceryDataLoadingMore.value = true;
    } else {
      isGroceryDataFirstLoading.value = true;
      groceryDataPage = 1;
      groceryDataHasMore = true;
    }

    try {
      Map<String, dynamic> params = {
        ApiKeys.page: groceryDataPage,
        ApiKeys.limit: pageLimit,
        ApiKeys.businessId: userId,
        ApiKeys.categoryId: categoryId
      };

      ResponseModel responseModel = await GroceryRepo().fetchGroceryProductsRepo(queryParam: params);
      if (responseModel.isSuccess) {
        fetchMyGroceryProductsResponse.value = ApiResponse.complete(responseModel);
        final data = responseModel.response?.data;
        GroceryProductsModel myGroceryProductsModel = GroceryProductsModel.fromJson(data);
        List<GroceryProductData> newItems = [];
        if (myGroceryProductsModel.data != null && myGroceryProductsModel.data!.isNotEmpty) {
          newItems = myGroceryProductsModel.data![0].category?.products ?? [];
        }

        if (!isLoadMore) {
          groceryProductsList.clear();
        }

        if (newItems.isNotEmpty) {
          groceryProductsList.addAll(newItems);
          groceryDataPage++;
        }

        log("Loaded ${newItems.length} items | Total: ${ groceryProductsList.length}");


        // 4. Update "Has More" based on pagination metadata
        final pagination = myGroceryProductsModel.pagination;
        if (pagination != null) {
          // If current page matches or exceeds total pages, stop loading more
          groceryDataHasMore = (pagination.page ?? 1) < (pagination.totalPages ?? 1);
        } else {
          // Fallback if pagination is null
          groceryDataHasMore = newItems.isNotEmpty;
        }

        // if (newItems.isNotEmpty) {
        //     if (isLoadMore) {
        //       myGroceryProductsList.addAll(newItems);
        //     } else {
        //       myGroceryProductsList.clear();
        //       myGroceryProductsList.assignAll(newItems);
        //     }
        //
        //   myGroceryDataPage++;
        // } else {
        //   myGroceryDataHasMore = false;
        // }

      } else {
        fetchMyGroceryProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      fetchMyGroceryProductsResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    } finally{
      if (isLoadMore) {
        isGroceryDataLoadingMore.value = false;
      } else {
        isGroceryDataFirstLoading.value = false;
      }
    }
  }

  /// Fetch Grocery Products
  RxList<GroceryProductData> globalGroceryProductsList = <GroceryProductData>[].obs;
  RxBool isGlobalGroceryDataFirstLoading = false.obs;
  RxBool isGlobalGroceryDataLoadingMore = false.obs;
  int globalGroceryDataPage = 1;
  bool globalGroceryDataHasMore = true;

  Future<void> fetchGlobalGroceryProducts({
    required String categoryId,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (isGlobalGroceryDataLoadingMore.value || !globalGroceryDataHasMore) return;
      isGlobalGroceryDataLoadingMore.value = true;
    } else {
      isGlobalGroceryDataFirstLoading.value = true;
      globalGroceryDataPage = 1;
      globalGroceryDataHasMore = true;
    }

    try {
      Map<String, dynamic> params = {
        ApiKeys.page: groceryDataPage,
        ApiKeys.limit: pageLimit,
        ApiKeys.categoryId: categoryId
      };

      ResponseModel responseModel = await GroceryRepo().fetchGlobalGroceryProductsRepo(queryParam: params);
      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        GroceryProductsModel groceryProductsModel = GroceryProductsModel.fromJson(data);
        List<GroceryProductData> newItems = [];
        if (groceryProductsModel.data != null && groceryProductsModel.data!.isNotEmpty) {
          newItems = groceryProductsModel.data![0].category?.products ?? [];
        }

        if (!isLoadMore) {
          globalGroceryProductsList.clear();
        }

        if (newItems.isNotEmpty) {
          globalGroceryProductsList.addAll(newItems);
          globalGroceryDataPage++;
        }

        log("Loaded ${newItems.length} items | Total: ${ globalGroceryProductsList.length}");


        // 4. Update "Has More" based on pagination metadata
        final pagination = groceryProductsModel.pagination;
        if (pagination != null) {
          // If current page matches or exceeds total pages, stop loading more
          globalGroceryDataHasMore = (pagination.page ?? 1) < (pagination.totalPages ?? 1);
        } else {
          // Fallback if pagination is null
          globalGroceryDataHasMore = newItems.isNotEmpty;
        }

      }
    } catch (e, s) {
      log("Stack Trace===== $s");
    } finally{
      if (isLoadMore) {
        isGlobalGroceryDataLoadingMore.value = false;
      } else {
        isGlobalGroceryDataFirstLoading.value = false;
      }
    }
  }


  /// Fetch Grocery Nested Categories With Inventory
  RxBool groceryNestedCategoryWithInventoryLoading = true.obs;
  RxList<GroceryNestedCategoryModel> groceryNestedCategoryWithInventoryList =
      <GroceryNestedCategoryModel>[].obs;

  Future<void> fetchGroceryNestedCategoryWithInventory(
      { required String userId,
        required String groceryCatKey
      }) async {
    try {
      groceryNestedCategoryWithInventoryLoading.value = true;
      groceryNestedCategoryWithInventoryList.clear();

      ResponseModel responseModel =
          await GroceryRepo().fetchGroceryNestedCategoryWithInventoryRepo(
              queryParams: {
                ApiKeys.businessId: userId,
                ApiKeys.categoryKey: groceryCatKey}
          );
      if (responseModel.isSuccess) {
        final GroceryNestedCategoryModel groceryNestedCategoryModel = GroceryNestedCategoryModel.fromJson(responseModel.response?.data);
        groceryNestedCategoryWithInventoryList.value = groceryNestedCategoryModel.children ?? [];
        log('Nested categories with product loaded: ${groceryNestedCategoryWithInventoryList.length}');
      } else {
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e, s) {
      log('Error fetching nested categories with product: $e\n$s');
    } finally {
      groceryNestedCategoryWithInventoryLoading.value = false;
    }
  }

  /// Fetch Grocery Products
  RxList<GroceryNestedCategoryModel> grocerySuperCategoryList = <GroceryNestedCategoryModel>[].obs;

  /// Fetch Grocery Nested Categories
  Future<void> fetchGroceryNestedCategory({String? groceryCatKey}) async {
    try {
      fetchNestedGroceryCategoryResponse.value = ApiResponse.initial('Initial');
      grocerySuperCategoryList.clear();

      // final cachedData = await HiveServices().getGroceryNestedCategories(groceryCatKey);
      // if (cachedData != null && cachedData.isNotEmpty) {
      //   groceryNestedCategoryLoading.value = false;
      //   groceryNestedCategoryList.assignAll(cachedData);
      //   return;
      // }

      Map<String, dynamic> queryParams = {};
      if(groceryCatKey!=null) queryParams[ApiKeys.categoryKey] = groceryCatKey;

      ResponseModel responseModel = await GroceryRepo().fetchGroceryNestedCategoryRepo(
          queryParams: queryParams
      );
      if (responseModel.isSuccess) {
        fetchNestedGroceryCategoryResponse.value = ApiResponse.complete(responseModel);
        grocerySuperCategoryList.value = (responseModel.response?.data ?? [])
            .map<GroceryNestedCategoryModel>((e) => GroceryNestedCategoryModel.fromJson(e))
            .toList();
        // await HiveServices().saveGroceryNestedCategories(groceryCatKey, groceryNestedCategoryList);
      } else {
        fetchNestedGroceryCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      log('stack trace -- $s');
      fetchNestedGroceryCategoryResponse.value = ApiResponse.error('error');
    }
  }

  RxBool missingProductRequestsLoading = false.obs;
  Future<void> missingGroceryProductRequestsApi(List<MissingProducts> missingProducts) async {
    try {
      missingProductRequestsLoading.value = true;

      final payload = buildMissingRequestsPayload(missingProducts);
      if(payload.isEmpty) return;

      print(jsonEncode(payload));

      final response = await GroceryRepo().missingGroceryProductRequestsRepo(
        params: payload,
      );

      if (!response.isSuccess) {
        missingGroceryProductRequestsResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      missingGroceryProductRequestsResponse.value = ApiResponse.complete(response);

      Get.until((route) =>
      route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
      commonSnackBar(
        message: response.message ?? AppStrings.somethingWentWrong,
      );
    } catch (e) {
      missingGroceryProductRequestsResponse.value = ApiResponse.error('error');
    } finally {
      missingProductRequestsLoading.value = false;
    }
  }

  Map<String, dynamic> buildMissingRequestsPayload(List<MissingProducts> missingProducts) {
    final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController());
    String city = viewBusinessDetailsController.businessProfileDetails.value?.data?.cityStatePincode ?? LocationService.userCurrentAddress.value.city;
    String postalCode = viewBusinessDetailsController.businessProfileDetails.value?.data?.pincode.toString() ?? LocationService.userCurrentAddress.value.postalCode;

    if(postalCode.isEmpty) {
      commonSnackBar(message: 'Please enable your location permission for adding grocery');
      return {};
    }

    Map<String, dynamic> payload = {};
    payload["pincode"] = postalCode;
    payload["cityName"] = city;
    payload["items"] = missingProducts.map((product) {
      return {
        "name": product.name ?? "",
        "brand": product.brand ?? "",
        "searchKeywords": product.searchKeywords ?? "",
        "approxPrice": product.approxPrice ?? 0,
        "unit": product.unit ?? "",
      };
    }).toList();

    return payload;
  }

}
