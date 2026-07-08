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
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_by_root_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_products_response.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/view/admin/edit_grocery_varient_dialog.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_varient_dialog.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Top-level so it can run in a background isolate via [compute]. The
/// `jsonDecode(jsonEncode())` round-trip normalises types so the same parser
/// works for both fresh Dio maps and Hive-restored maps (cache + network).
List<GroceryNestedCategoryModel> _parseGroceryNestedCategories(
    List<dynamic> raw) {
  return raw
      .map((e) => GroceryNestedCategoryModel.fromJson(
          jsonDecode(jsonEncode(e)) as Map<String, dynamic>))
      .toList();
}

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
  String get currentCatId =>
      selectedHorizontalTabIndex.value == 0
          ? (selectedGroceryData.value?.sId ?? '')
          : selectedGroceryData.value?.children?.first.sId ?? '';

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
            message: AppStrings.groceryMaxSelectWarning.tr);
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
          title: AppStrings.groceryAddMoreVariant.tr,
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
      commonSnackBar(message: AppStrings.groceryRemoveCurrentImageType.tr);
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
    await PhotoPickerService.pickMultiplePhotos(Get.context!, title);
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
        ApiKeys.categoryId: currentCatId,
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
      final List<GroceryProductData> newItems = groceryProductModel.data ?? <GroceryProductData>[];

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
    final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
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
      commonSnackBar(message: AppStrings.groceryEnableGpsOrPincode.tr);
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
      commonSnackBar(message: AppStrings.groceryUploadAtLeastOnePhoto.tr);
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

  /// ─── Pagination for "Top Selling Products" (business-products API) ───
  /// Shared between the store screens (home preview) and the standalone
  /// "View All" screen. On the home screens only the first
  /// [businessProductsPreviewLimit] items are rendered — the rest of the
  /// paginated list lives behind the "View All" action.
  RxBool isBusinessProductsLoadingMore = false.obs;
  int _businessProductsPage = 1;
  bool _businessProductsHasMore = true;
  static const int _businessProductsLimit = 20;
  static const int businessProductsPreviewLimit = 20;

  bool get businessProductsHasMore => _businessProductsHasMore;

  /// Freshness guard for [fetchAllGroceryData], keyed per store so visiting
  /// store A → B → back to A re-fetches A only if its data went stale.
  final FetchCache _allGroceryCache = FetchCache();

  /// Fetch the store's grocery data (categories + top-selling) only when it
  /// isn't already loaded & fresh for this [userId]. Use on screen (re)entry;
  /// call [fetchAllGroceryData] for explicit refreshes.
  Future<void> fetchAllGroceryDataIfNeeded(String userId,
      {required bool otherStore}) async {
    final signature = 'grocery|$userId|$otherStore';
    final hasData = groceryCategoryList.isNotEmpty ||
        groceryBusinessProductsList.isNotEmpty;
    if (_allGroceryCache.isFresh(signature, hasData: hasData)) return;
    await fetchAllGroceryData(userId, otherStore: otherStore);
  }

  Future<void> fetchAllGroceryData(String userId, {required bool otherStore}) async {
    try {
      myGroceryLoading.value = true;

      // 1. Run both repo calls in parallel
      await Future.wait([
        fetchGroceryCategoryWithInventory(userId, otherStore),
        fetchGroceryBusinessProductsRepo(userId, otherStore),
      ]);

      // Stamp the freshness cache once the category list actually loaded so a
      // re-entry for the same store reuses it instead of refetching.
      if (fetchMyGroceryCategoryResponse.value.status == Status.COMPLETE) {
        _allGroceryCache.mark('grocery|$userId|$otherStore');
      }
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

  Future<void> fetchGroceryBusinessProductsRepo(
    String userId,
    bool otherStore, {
    bool isLoadMore = false,
  }) async {
    try {
      if (isLoadMore) {
        // Guard against duplicate/overlapping load-more calls and stop once
        // the server has reported there are no more pages.
        if (!_businessProductsHasMore ||
            isBusinessProductsLoadingMore.value ||
            fetchGroceryBusinessProductsResponse.value.status ==
                Status.INITIAL) {
          return;
        }
        isBusinessProductsLoadingMore.value = true;
      } else {
        fetchGroceryBusinessProductsResponse.value = ApiResponse.initial('Initial');
        _businessProductsPage = 1;
        _businessProductsHasMore = true;
        groceryBusinessProductsList.clear();
      }

      Map<String, dynamic> params = {
        ApiKeys.businessId: userId,
        ApiKeys.sortBy: "discount_high_to_low",
        ApiKeys.page: _businessProductsPage,
        ApiKeys.limit: _businessProductsLimit,
      };

      ResponseModel responseModel;
      if (!otherStore) {
        responseModel =
            await GroceryRepo().fetchGroceryBusinessProductsRepo(params: params);
      } else {
        responseModel = await GroceryRepo()
            .fetchPublicGroceryBusinessProductsRepo(params: params);
      }

      if (responseModel.isSuccess) {
        var groceryBusinessProductsModel = GroceryBusinessProductsModel
            .fromJson(responseModel.response?.data);
        final newItems = groceryBusinessProductsModel.data ?? [];

        if (isLoadMore) {
          groceryBusinessProductsList.addAll(newItems);
        } else {
          groceryBusinessProductsList.value = newItems;
        }

        if (newItems.isNotEmpty) {
          _businessProductsPage++;
        }
        // If the backend returned less than the page size, we've reached
        // the end — no point hammering the server for another page.
        if (newItems.length < _businessProductsLimit) {
          _businessProductsHasMore = false;
        }

        fetchGroceryBusinessProductsResponse.value =
            ApiResponse.complete(responseModel);
        log("Loaded ${groceryBusinessProductsList.length}");
      } else {
        fetchGroceryBusinessProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      fetchGroceryBusinessProductsResponse.value = ApiResponse.error('error');
      log("Stack Trace===== $s");
    } finally {
      if (isLoadMore) {
        isBusinessProductsLoadingMore.value = false;
      }
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

  /// Fetch Grocery Nested Categories.
  ///
  /// Cache-first for the super-category list (no `groceryCatKey`): the last
  /// saved tree is shown instantly while a fresh copy is fetched silently in
  /// the background. The tree is parsed off the UI isolate via [compute] so a
  /// large response can't freeze the shimmer / starve frames.
  Future<void> fetchGroceryNestedCategory({String? groceryCatKey}) async {
    final bool isSuper = groceryCatKey == null;
    try {
      fetchNestedGroceryCategoryResponse.value = ApiResponse.initial('Initial');
      grocerySuperCategoryList.clear();

      // 1) Cache-first (super-category list only).
      if (isSuper) {
        final cachedRaw = HiveServices().getGrocerySuperCategoriesRaw();
        if (cachedRaw != null && cachedRaw.isNotEmpty) {
          final cached =
              await compute(_parseGroceryNestedCategories, cachedRaw);
          if (cached.isNotEmpty) {
            grocerySuperCategoryList.assignAll(cached);
            fetchNestedGroceryCategoryResponse.value = ApiResponse.complete();
          }
        }
      }

      // 2) Silent network refresh.
      Map<String, dynamic> queryParams = {};
      if (groceryCatKey != null) queryParams[ApiKeys.categoryKey] = groceryCatKey;

      ResponseModel responseModel = await GroceryRepo()
          .fetchGroceryNestedCategoryRepo(queryParams: queryParams);
      if (responseModel.isSuccess) {
        final List<dynamic> rawList = (responseModel.response?.data is List)
            ? responseModel.response!.data as List
            : const [];
        final parsed = rawList.isEmpty
            ? <GroceryNestedCategoryModel>[]
            : await compute(_parseGroceryNestedCategories, rawList);

        grocerySuperCategoryList.assignAll(parsed);
        fetchNestedGroceryCategoryResponse.value =
            ApiResponse.complete(responseModel);

        if (isSuper && rawList.isNotEmpty) {
          await HiveServices().saveGrocerySuperCategoriesRaw(rawList);
        }
      } else if (grocerySuperCategoryList.isEmpty) {
        // Only surface an error when there's no cached data on screen.
        fetchNestedGroceryCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      log('stack trace -- $s');
      if (grocerySuperCategoryList.isEmpty) {
        try {
          fetchNestedGroceryCategoryResponse.value = ApiResponse.error('error');
        } catch (_) {}
      }
    }
  }

  /// ─── Category showcase (grocery-service/api/products/category-showcase) ───
  /// Cross-category product list rendered at the bottom of the grocery
  /// super-category screen. TTL-guarded via [_showcaseCache] so re-entering the
  /// screen within the cache window reuses the loaded list instead of
  /// refetching.
  Rx<ApiResponse> groceryCategoryShowcaseResponse =
      ApiResponse.initial('Initial').obs;
  RxList<GroceryProductData> groceryCategoryShowcaseList =
      <GroceryProductData>[].obs;
  RxBool isGroceryShowcaseLoadingMore = false.obs;
  int _showcasePage = 1;
  bool _showcaseHasMore = true;
  static const int _showcaseLimit = 10;
  bool get groceryShowcaseHasMore => _showcaseHasMore;

  final FetchCache _showcaseCache = FetchCache();

  /// Fetch the showcase only when it isn't already loaded & fresh (within the
  /// [FetchCache] TTL). Call on screen (re)entry; use [fetchGroceryCategoryShowcase]
  /// for explicit refreshes.
  Future<void> fetchGroceryCategoryShowcaseIfNeeded() async {
    if (_showcaseCache.isFresh('grocery-showcase',
        hasData: groceryCategoryShowcaseList.isNotEmpty)) {
      return;
    }
    await fetchGroceryCategoryShowcase();
  }

  Future<void> fetchGroceryCategoryShowcase({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        if (!_showcaseHasMore || isGroceryShowcaseLoadingMore.value) return;
        isGroceryShowcaseLoadingMore.value = true;
      } else {
        groceryCategoryShowcaseResponse.value = ApiResponse.loading('loading');
        _showcasePage = 1;
        _showcaseHasMore = true;
      }

      final Map<String, dynamic> params = {
        ApiKeys.page: _showcasePage,
        ApiKeys.limit: _showcaseLimit,
      };

      final response =
          await GroceryRepo().fetchGroceryCategoryShowcaseRepo(queryParam: params);

      if (!response.isSuccess) {
        if (!isLoadMore && groceryCategoryShowcaseList.isEmpty) {
          groceryCategoryShowcaseResponse.value = ApiResponse.error('error');
        }
        return;
      }

      final model = GroceryProductModel.fromJson(response.response?.data);
      final List<GroceryProductData> newItems =
          model.data ?? <GroceryProductData>[];

      if (isLoadMore) {
        groceryCategoryShowcaseList.addAll(newItems);
      } else {
        groceryCategoryShowcaseList.assignAll(newItems);
      }

      if (newItems.isNotEmpty) _showcasePage++;

      final pagination = model.pagination;
      _showcaseHasMore = pagination != null
          ? (pagination.page ?? 1) < (pagination.totalPages ?? 1)
          : newItems.isNotEmpty;

      groceryCategoryShowcaseResponse.value = ApiResponse.complete(response);
      // Stamp freshness only after the list is populated so a re-entry reuses
      // it instead of refetching.
      _showcaseCache.mark('grocery-showcase');
      log('showcase loaded -- ${groceryCategoryShowcaseList.length}');
    } catch (e, s) {
      log('showcase stack trace -- $s');
      if (!isLoadMore && groceryCategoryShowcaseList.isEmpty) {
        groceryCategoryShowcaseResponse.value = ApiResponse.error('error');
      }
    } finally {
      if (isLoadMore) isGroceryShowcaseLoadingMore.value = false;
    }
  }

  /// ─── Products by root category (grocery-service/api/products/by-root-category) ───
  /// Powers the "Quick Upload" rails on the add-grocery super-category screen:
  /// one horizontal rail per root category, each with a capped product list.
  /// TTL-guarded via [_rootCategoryCache] so re-entering the screen within the
  /// cache window reuses the loaded sections instead of refetching.
  Rx<ApiResponse> groceryRootCategoryResponse =
      ApiResponse.initial('Initial').obs;
  RxList<GroceryRootCategorySection> groceryRootCategoryList =
      <GroceryRootCategorySection>[].obs;
  static const int _rootCategoryLimit = 10;

  final FetchCache _rootCategoryCache = FetchCache();

  /// Fetch the root-category rails only when not already loaded & fresh (within
  /// the [FetchCache] TTL). Call on screen (re)entry; use
  /// [fetchGroceryProductsByRootCategory] for explicit refreshes.
  Future<void> fetchGroceryProductsByRootCategoryIfNeeded() async {
    if (_rootCategoryCache.isFresh('grocery-by-root-category',
        hasData: groceryRootCategoryList.isNotEmpty)) {
      return;
    }
    await fetchGroceryProductsByRootCategory();
  }

  Future<void> fetchGroceryProductsByRootCategory() async {
    try {
      groceryRootCategoryResponse.value = ApiResponse.loading('loading');

      final Map<String, dynamic> params = {
        ApiKeys.limit: _rootCategoryLimit,
        ApiKeys.min: 0,
      };

      final response = await GroceryRepo()
          .fetchGroceryProductsByRootCategoryRepo(queryParam: params);

      if (!response.isSuccess) {
        if (groceryRootCategoryList.isEmpty) {
          groceryRootCategoryResponse.value = ApiResponse.error('error');
        }
        return;
      }

      final model = GroceryByRootCategoryModel.fromJson(
          (response.response?.data as Map<String, dynamic>?) ?? const {});
      // Drop empty sections so we never render a titled rail with no products.
      final sections =
          model.sections.where((s) => s.products.isNotEmpty).toList();

      groceryRootCategoryList.assignAll(sections);
      groceryRootCategoryResponse.value = ApiResponse.complete(response);
      // Stamp freshness only after the list is populated so a re-entry reuses
      // it instead of refetching.
      _rootCategoryCache.mark('grocery-by-root-category');
      log('by-root-category loaded -- ${groceryRootCategoryList.length} sections');
    } catch (e, s) {
      log('by-root-category stack trace -- $s');
      if (groceryRootCategoryList.isEmpty) {
        groceryRootCategoryResponse.value = ApiResponse.error('error');
      }
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
    final viewBusinessDetailsController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    String city = viewBusinessDetailsController.businessProfileDetails.value?.data?.cityStatePincode ?? LocationService.userCurrentAddress.value.city;
    String postalCode = viewBusinessDetailsController.businessProfileDetails.value?.data?.pincode.toString() ?? LocationService.userCurrentAddress.value.postalCode;

    if(postalCode.isEmpty) {
      commonSnackBar(message: AppStrings.groceryEnableLocationForGrocery.tr);
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
