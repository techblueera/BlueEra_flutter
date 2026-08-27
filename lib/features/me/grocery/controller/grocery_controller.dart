import 'dart:async';
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
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/service/grocery_local_store.dart';
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

  /// Variant-only toggle, used by the snap-search screen — it keeps its own
  /// product list rather than [selectedGroceries], so this deliberately does
  /// not touch the product cart. The catalogue screens go through
  /// [toggleVariantSelection] instead.
  void toggleVariant(String productId, ProductVariants variant) {
    // Never selectable: already on this store's own shelf. The rows paint it
    // locked; this is the guard behind them.
    if (isVariantStocked(variant.sId)) return;

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

  /// Variant-level selection, the way food does it: ticking the FIRST variant
  /// of a product is what puts the product in the cart, unticking the LAST one
  /// is what takes it out.
  ///
  /// So [selectedGroceries] always means "products with at least one variant
  /// chosen" — which is exactly what the floating cart counts, and what the
  /// publish payload is built from. Selecting a whole product (the old `+`
  /// behaviour) published every pack size the catalogue carries; a store
  /// stocking only the 500 g had no way to say so.
  void toggleVariantSelection(
      GroceryProductData product, ProductVariants variant) {
    final productId = product.sId ?? '';
    final variantId = variant.sId ?? '';
    if (productId.isEmpty || variantId.isEmpty) return;

    // Never selectable: it is already on this store's own shelf, and a second
    // inventory record against one catalogue variant is a duplicate row with a
    // second price. The sheet paints it locked; this is the guard behind it.
    if (isVariantStocked(variantId)) return;

    final current = List<ProductVariants>.from(
        selectedProductVariants[productId] ?? const <ProductVariants>[]);
    final idx = current.indexWhere((v) => v.sId == variantId);

    if (idx != -1) {
      current.removeAt(idx);
    } else {
      // The cap counts PRODUCTS, not variants, so it can only bite on the
      // first variant of a product that isn't in the cart yet.
      final bool isNewProduct = !selectedGroceries.any((p) => p.sId == productId);
      if (isNewProduct && selectedGroceries.length >= maxLimit) {
        commonSnackBar(message: AppStrings.groceryMaxSelectWarning.tr);
        return;
      }
      current.add(variant);
    }

    if (current.isEmpty) {
      selectedProductVariants.remove(productId);
      selectedGroceries.removeWhere((p) => p.sId == productId);
    } else {
      selectedProductVariants[productId] = current;
      if (!selectedGroceries.any((p) => p.sId == productId)) {
        selectedGroceries.add(product);
      }
    }

    selectedProductVariants.refresh();
    selectedGroceries.refresh();
  }

  /// How many variants of [productId] are in the cart — the number the card's
  /// "+" badge shows.
  int selectedVariantCount(String? productId) =>
      selectedProductVariants[productId ?? '']?.length ?? 0;

  /// Empties the add-product basket after a successful publish.
  ///
  /// The controller survives the flow (`getOrPut`, never deleted, so the
  /// Products tab can reuse its cached lists), which means the basket has to
  /// be cleared on purpose — otherwise re-entering "Add product" shows the
  /// items that were just published still sitting in the cart, now badged
  /// "already added" and un-publishable.
  void clearGrocerySelection() {
    selectedGroceries.clear();
    selectedProductVariants.clear();
    selectedProductVariants.refresh();
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

    // Discounts are min/max'd over the PER-ROW values. Deriving them from the
    // min/max price pair instead produced descending nonsense like
    // "10% - 8% Off", because the cheapest row isn't the biggest discount.
    final discounts = pricingList
        .where((p) => p.sellingPrice != null && p.mrp != null)
        .map((p) => discount(p.mrp!, p.sellingPrice!))
        .toList()
      ..sort();
    final minDiscount = discounts.isEmpty ? 0.0 : discounts.first;
    final maxDiscount = discounts.isEmpty ? 0.0 : discounts.last;

    // Format ranges. `₹90`, not `₹90.0` — these are doubles, and interpolating
    // one raw put a trailing `.0` on every price in the app.
    String money(double value) {
      final text = value == value.roundToDouble()
          ? value.round().toString()
          : value.toStringAsFixed(2);
      return '₹$text';
    }

    final sellingRange = minSelling == maxSelling
        ? money(minSelling)
        : "${money(minSelling)} - ${money(maxSelling)}";

    final mrpRange = minMrp == maxMrp
        ? money(minMrp)
        : "${money(minMrp)} - ${money(maxMrp)}";

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
    showModalBottomSheet(
      context: context,
      // The sheet pads itself against the keyboard, so it must be free to grow
      // past the default half-screen cap; transparent because the sheet draws
      // its own rounded white surface.
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
            // The edited `variant` is the SAME object held by both the product's
            // variant list AND `selectedProductVariants` (toggleVariant stores
            // the reference, not a copy), so the model is already updated. But
            // the in-place mutation notifies nothing — refresh both reactive
            // collections so the variant row's Obx rebuilds and shows the new
            // MRP / selling price whether or not the variant is selected.
            selectedProductVariants.refresh();
            selectedGroceries.refresh();
            Get.back();
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
      // Put it straight in the cart. The merchant created this pack in order
      // to publish it, and the review card now lists only what's picked — an
      // unticked new variant would simply vanish.
      toggleVariantSelection(groceryItem, newVariant);
      // The variant list itself is a plain List on the model, so nothing above
      // notifies the pickers. The variant sheet's Obx watches this map — poke
      // it so the row the merchant just created appears without reopening.
      selectedProductVariants.refresh();
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
      // State work first. The cart has to be emptied here — the controller
      // outlives this flow, so anything left in it comes back on the next
      // "Add product" as items that are now already stocked.
      clearGrocerySelection();
      // Products just entered the store's inventory: drop the freshness guard,
      // refetch, and rewrite the saved snapshot. Without this the tab would
      // serve the pre-publish cache and the new items would be invisible.
      markInventoryChanged();

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


  /// Freshness guard for [fetchAllGroceryData], keyed per store so visiting
  /// store A → B → back to A re-fetches A only if its data went stale.
  final FetchCache _allGroceryCache = FetchCache();

  /// Fetch the store's grocery data (categories + top-selling) only when it
  /// isn't already loaded & fresh for this [userId]. Use on screen (re)entry;
  /// call [fetchAllGroceryData] for explicit refreshes.
  ///
  /// Three layers, cheapest first:
  /// 1. [_allGroceryCache] — same store, fetched < 5 min ago, still in memory.
  /// 2. [GroceryLocalStore] — the saved snapshot. **If there is one, that is the
  ///    answer and no request is made.**
  /// 3. The network — only when nothing is saved.
  ///
  /// The snapshot is not a head start on a request; it replaces the request.
  /// What keeps it honest is that every write the merchant makes (publish, price
  /// edit, delete, stock toggle) runs [markInventoryChanged], which refetches
  /// and rewrites it — so the only way to be looking at stale stock is for it to
  /// have changed somewhere other than this device, and pull-to-refresh on the
  /// tab is the escape hatch for that.
  Future<void> fetchAllGroceryDataIfNeeded(String userId,
      {required bool otherStore}) async {
    // No id, nothing to fetch — but RESOLVE the tab's state rather than
    // returning silently. Nothing re-runs the dispatcher, so a bare `return`
    // here leaves the Products tab shimmering on `Status.INITIAL` for good,
    // with no error and no retry. The same terminal early return is what the
    // food tab was fixed for; see `FoodMainScreen._fetchProductsTab`.
    if (userId.isEmpty) {
      log('grocery: businessId unresolved — Products tab has nothing to fetch');
      _resolveCategoryFailure(silent: false);
      _resolveBusinessProductsFailure(silent: false);
      return;
    }

    final signature = 'grocery|$userId|$otherStore';
    final hasData = groceryCategoryList.isNotEmpty ||
        groceryBusinessProductsList.isNotEmpty;
    if (_allGroceryCache.isFresh(signature, hasData: hasData)) return;

    if (await _hydrateGroceryDataFromCache(userId, otherStore)) {
      // Stamped so a tab switch doesn't go back to disk either.
      _allGroceryCache.mark(signature);
      return;
    }
    await fetchAllGroceryData(userId, otherStore: otherStore);
  }

  Future<void> fetchAllGroceryData(
    String userId, {
    required bool otherStore,
    bool silent = false,
  }) async {
    try {
      if (!silent) myGroceryLoading.value = true;

      // 1. Run both repo calls in parallel
      await Future.wait([
        fetchGroceryCategoryWithInventory(userId, otherStore, silent: silent),
        fetchGroceryBusinessProductsRepo(userId, otherStore, silent: silent),
      ]);

      // Stamp the freshness cache only once BOTH lists actually loaded.
      //
      // Categories alone used to be enough, and that is what stranded the tab:
      // `fetchAllGroceryDataIfNeeded` reads `hasData` as
      // `categories.isNotEmpty || products.isNotEmpty`, so a run where the
      // categories landed and the top-selling request did not stamped the
      // guard anyway — and every later entry then took the early return and
      // never retried the half that failed. The Products tab renders its
      // shimmer off that unresolved status, so it shimmered for good.
      //
      // COMPLETE means the REQUEST succeeded, not that rows came back, so a
      // store with an empty shelf still stamps and still gets its 5-minute
      // reuse.
      final bothLoaded = fetchMyGroceryCategoryResponse.value.status ==
              Status.COMPLETE &&
          fetchGroceryBusinessProductsResponse.value.status == Status.COMPLETE;
      if (bothLoaded) {
        _allGroceryCache.mark('grocery|$userId|$otherStore');
      }
    } catch (e) {
    } finally {
      if (!silent) myGroceryLoading.value = false;
    }
  }

  /// Paints the Products tab from the last saved snapshot.
  ///
  /// Returns true only when something was actually restored — false sends the
  /// caller to the network. Deliberately tolerant: a snapshot that fails to
  /// parse (a model changed shape since it was written) counts as a miss, so a
  /// bad cache degrades into a normal fetch rather than an error the user sees.
  ///
  /// Both lists must restore for this to report success. Restoring one and
  /// declaring victory would leave the other permanently empty, since a `true`
  /// return means no request is made.
  Future<bool> _hydrateGroceryDataFromCache(
      String userId, bool otherStore) async {
    // Owner scope only. A visitor browsing someone else's store has no way to
    // invalidate a snapshot — they can't add, edit or restock anything — so a
    // cache-first read with no revalidation would freeze that store's shelf on
    // their device indefinitely. Their fetches stay live (in-memory guard only),
    // exactly as before.
    if (otherStore || userId.isEmpty) return false;

    List<GroceryCategoryWithInventoryModel>? categories;
    List<BusinessProductData>? topSelling;
    try {
      final entry =
          await GroceryLocalStore.readCategories(userId, otherStore: otherStore);
      if (entry != null && !entry.isEmpty) {
        categories = entry.items
            .whereType<Map>()
            .map((e) => GroceryCategoryWithInventoryModel.fromJson(
                Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      log('grocery: category cache hydrate failed — $e');
    }
    try {
      final entry =
          await GroceryLocalStore.readTopSelling(userId, otherStore: otherStore);
      if (entry != null && !entry.isEmpty) {
        topSelling = entry.items
            .whereType<Map>()
            .map((e) => BusinessProductData.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      log('grocery: top-selling cache hydrate failed — $e');
    }

    // Half a snapshot is not a snapshot: publish nothing unless both sides
    // restored, or the missing list would stay empty with no request coming.
    if (categories == null ||
        categories.isEmpty ||
        topSelling == null ||
        topSelling.isEmpty) {
      return false;
    }

    groceryCategoryList.value = categories;
    fetchMyGroceryCategoryResponse.value = ApiResponse.complete();

    groceryBusinessProductsList.value = topSelling;
    // The snapshot only ever holds page 1, so paging restarts from there.
    _businessProductsPage = 1;
    _businessProductsHasMore = true;
    fetchGroceryBusinessProductsResponse.value = ApiResponse.complete();
    return true;
  }

  /// Called after any inventory write (publish / edit price / delete / stock
  /// toggle) that the merchant just made.
  ///
  /// The sheets already patch their own models in place, so the screen is
  /// correct the moment the call returns. What this fixes is everything the
  /// patch cannot reach: the 5-minute freshness guard that would otherwise
  /// short-circuit the next tab entry, the sibling lists that still hold the
  /// old row (a deleted variant lingered in `groceryBusinessProductsList` until
  /// something forced a real fetch), and the disk snapshot, which must never
  /// outlive the change that invalidated it.
  ///
  /// The server is the source of truth for the rewrite: rather than editing the
  /// cached JSON — which would mean re-implementing every mutation against a
  /// second data shape — the snapshot is **deleted** and then rebuilt from a
  /// refetch.
  ///
  /// Deleting first, rather than overwriting when the refetch lands, is what
  /// makes the race safe. The merchant can leave the add-product flow and be
  /// back on the tab before the refetch resolves; with the old snapshot still on
  /// disk, that re-entry would hydrate the pre-mutation list and stamp it fresh,
  /// hiding the change until the guard expired. With it gone the worst case is
  /// one extra request, and stale is not reachable.
  void markInventoryChanged({String? storeId}) {
    groceryDataNeedsRefresh = true;
    _allGroceryCache.invalidate();
    groceryBusinessProductsList.refresh();
    groceryCategoryList.refresh();
    // The publish/delete that got us here also changed which catalogue
    // variants this store holds, and the add flow reads that set to grey out
    // what is already stocked. Refreshed here rather than by each caller so a
    // new write path cannot forget it.
    markStockedVariantsChanged(storeId: storeId);

    final id = (storeId == null || storeId.isEmpty) ? userId : storeId;
    if (id.isEmpty) return;
    // Fire-and-forget: the caller is a sheet closing on a completed write, and
    // nothing on screen is waiting for this.
    unawaited(GroceryLocalStore.clearStore(id).then(
      (_) => fetchAllGroceryData(id, otherStore: false, silent: true),
    ));
  }

  // ─── Already-stocked variants ──────────────────────────────────────────────
  // Grocery mirror of the food flow — see
  // `FoodServiceController.fetchStockedVariantIdsIfNeeded`. The grocery add
  // flow selects a whole PRODUCT rather than picking variants in a sheet, so
  // the gate lands on the card: a product whose every variant is already
  // stocked is not offerable, and a partly-stocked one says how far along it
  // is.

  /// productVariant ids this store ALREADY has in its inventory.
  ///
  /// A set, and observable, because every card on the selection rails asks the
  /// same question of it — [isVariantStocked].
  final RxSet<String> stockedVariantIds = <String>{}.obs;

  /// Freshness guard, keyed per store like [_allGroceryCache], so re-entering
  /// the add flow reuses the answer instead of refetching.
  final FetchCache _stockedVariantIdsCache = FetchCache();

  /// Load the stocked-variant set, cheapest source first — the same three-layer
  /// discipline the Products tab uses:
  ///
  /// 1. in-memory, same store, fetched < 5 min ago;
  /// 2. the saved snapshot on disk;
  /// 3. the network.
  ///
  /// The snapshot REPLACES the request rather than racing it, and stays honest
  /// for the same reason the catalogue snapshot does: the only thing that
  /// changes this set on this device is the merchant publishing or deleting,
  /// and both run [markInventoryChanged] → [markStockedVariantsChanged].
  Future<void> fetchStockedVariantIdsIfNeeded() async {
    final id = userId;
    if (id.isEmpty) return;

    final signature = 'groceryStockedVariants|$id';
    if (_stockedVariantIdsCache.isFresh(signature,
        hasData: stockedVariantIds.isNotEmpty)) {
      return;
    }

    try {
      final entry = await GroceryLocalStore.readStockedVariantIds(id);
      if (entry != null && !entry.isEmpty) {
        stockedVariantIds
          ..clear()
          ..addAll(entry.items.map((e) => e.toString()));
        _stockedVariantIdsCache.mark(signature);
        return;
      }
    } catch (e) {
      log('grocery: stocked-variant cache hydrate failed — $e');
    }

    await fetchStockedVariantIds();
  }

  /// Unguarded fetch. Use for an explicit refresh; screen entry should go
  /// through [fetchStockedVariantIdsIfNeeded].
  Future<void> fetchStockedVariantIds() async {
    final id = userId;
    if (id.isEmpty) return;
    try {
      final response =
          await GroceryRepo().getInventoryProductVariantIdsRepo(businessId: id);
      if (!response.isSuccess) return;

      final raw = response.response?.data?['data']?['productVariantIds'];
      if (raw is! List) return;
      final ids = [
        for (final value in raw)
          if ((value?.toString() ?? '').trim().isNotEmpty) value.toString(),
      ];

      stockedVariantIds
        ..clear()
        ..addAll(ids);
      _stockedVariantIdsCache.mark('groceryStockedVariants|$id');
      unawaited(GroceryLocalStore.writeStockedVariantIds(id, ids: ids));
    } catch (e, s) {
      log('grocery fetchStockedVariantIds error: $e\n$s');
    }
  }

  /// Whether [variantId] is a catalogue variant the store already stocks.
  ///
  /// An EMPTY set means "not loaded / this store has nothing", and both answer
  /// false — the selection screens stay fully usable when the lookup fails
  /// rather than locking every card on a request that did not come back.
  bool isVariantStocked(String? variantId) {
    final id = (variantId ?? '').trim();
    return id.isNotEmpty && stockedVariantIds.contains(id);
  }

  /// Every variant of [product] is already stocked — the card can say so
  /// instead of offering an add that would publish duplicates.
  ///
  /// A product with NO variants answers false: there is nothing to have
  /// stocked, and `every` on an empty list is vacuously true, which would
  /// wrongly lock the card.
  bool isProductFullyStocked(GroceryProductData product) {
    final variants = product.variants ?? const <ProductVariants>[];
    if (variants.isEmpty) return false;
    return variants.every((v) => isVariantStocked(v.sId));
  }

  /// How many of [product]'s variants are already stocked.
  int stockedVariantCount(GroceryProductData product) {
    final variants = product.variants ?? const <ProductVariants>[];
    return variants.where((v) => isVariantStocked(v.sId)).length;
  }

  /// The set changed under us — a publish added variants, a delete removed one.
  ///
  /// Drops the guard AND the snapshot, then refetches. Without the snapshot
  /// delete a re-entry would paint the pre-publish set straight off disk and
  /// keep offering a variant the merchant just added.
  void markStockedVariantsChanged({String? storeId}) {
    final id = (storeId == null || storeId.isEmpty) ? userId : storeId;
    _stockedVariantIdsCache.invalidate();
    if (id.isEmpty) return;
    unawaited(
      GroceryLocalStore.writeStockedVariantIds(id, ids: const [])
          .then((_) => fetchStockedVariantIds()),
    );
  }

  /// [silent] keeps the currently rendered list on screen while the call runs —
  /// used when the tab was hydrated from disk, or refreshed after a write, so
  /// the content never flashes back to a skeleton it has already moved past.
  Future<void> fetchGroceryCategoryWithInventory(String userId, bool otherStore,
      {bool silent = false}) async {
    try {

      if (!silent) {
        fetchMyGroceryCategoryResponse.value = ApiResponse.initial('Initial');
      }

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

        // Persist the raw payload, not the parsed models: the next open rebuilds
        // them with this same `fromJson`, so there is one parser to keep right.
        // Owner scope only — see [_hydrateGroceryDataFromCache].
        if (!otherStore) {
          unawaited(GroceryLocalStore.writeCategories(
            userId,
            otherStore: otherStore,
            items: listData,
          ));
        }

        log("Loaded ${groceryCategoryList.length}");
      } else {
        // A failed SILENT refresh must not replace what the user is reading
        // with an error — the hydrated list stays, and the guard was already
        // left un-stamped so the next entry retries. The exception is a status
        // that never resolved; see [_resolveCategoryFailure].
        _resolveCategoryFailure(silent: silent);
      }
    } catch (e) {
      _resolveCategoryFailure(silent: silent);
      log("ERROR===== $e");
     }
  }

  /// Records a failed top-selling fetch.
  ///
  /// A silent refresh normally leaves the status alone — that is the whole
  /// point of `silent`: keep the rendered rows and their COMPLETE state while
  /// replacements are fetched, so the tab doesn't blink. **But a status that
  /// has never resolved is not something worth protecting.** The Products tab
  /// renders its shimmer on `Status.INITIAL`, so a silent failure over an
  /// unresolved status left that shimmer running with nothing scheduled to
  /// stop it — the tab shimmered for good, with no error and no retry. Same
  /// failure mode the food tab was fixed for; see
  /// `FoodMainScreen._fetchProductsTab`.
  void _resolveBusinessProductsFailure({required bool silent}) {
    final unresolved =
        fetchGroceryBusinessProductsResponse.value.status == Status.INITIAL;
    if (!silent || unresolved) {
      fetchGroceryBusinessProductsResponse.value = ApiResponse.error('error');
    }
  }

  /// Category-list counterpart of [_resolveBusinessProductsFailure].
  void _resolveCategoryFailure({required bool silent}) {
    final unresolved =
        fetchMyGroceryCategoryResponse.value.status == Status.INITIAL;
    if (!silent || unresolved) {
      fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> fetchGroceryBusinessProductsRepo(
    String userId,
    bool otherStore, {
    bool isLoadMore = false,
    bool silent = false,
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
        // Paging always restarts, but a silent refresh keeps the rendered rows
        // until the replacements arrive — clearing here is what would make the
        // list blink on every hydrate and after every write.
        _businessProductsPage = 1;
        _businessProductsHasMore = true;
        if (!silent) {
          fetchGroceryBusinessProductsResponse.value =
              ApiResponse.initial('Initial');
          groceryBusinessProductsList.clear();
        }
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
          // Page 1 only — that is exactly what the tab renders, and it keeps
          // the snapshot small however deep the user paged. Owner scope only —
          // see [_hydrateGroceryDataFromCache].
          if (!otherStore) {
            final rawItems = responseModel.response?.data is Map
                ? (responseModel.response?.data['data'] as List?) ?? const []
                : const [];
            unawaited(GroceryLocalStore.writeTopSelling(
              userId,
              otherStore: otherStore,
              items: rawItems,
            ));
          }
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
        _resolveBusinessProductsFailure(silent: silent);
      }
    } catch (e, s) {
      _resolveBusinessProductsFailure(silent: silent);
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
    required String userId,
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
        ApiKeys.businessId: userId,
        ApiKeys.categoryId: categoryId,
        ApiKeys.page: groceryDataPage,
        ApiKeys.limit: pageLimit,
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

      // 1) Cache-first — the root list AND every drilled-into branch.
      //
      // The branch (`groceryCatKey != null`) used to go straight to the network
      // every time, so walking back up and down the add-grocery tree re-asked
      // for the same children on every tap. Each branch is now its own entry.
      final entry = isSuper
          ? await GroceryLocalStore.readCatalogCategories()
          : await GroceryLocalStore.readCatalogChild(groceryCatKey);
      if (entry != null && !entry.isEmpty) {
        final cached =
            await compute(_parseGroceryNestedCategories, entry.items);
        if (cached.isNotEmpty) {
          grocerySuperCategoryList.assignAll(cached);
          fetchNestedGroceryCategoryResponse.value = ApiResponse.complete();
          // Served from disk, no request. Unlike the store's own stock, this
          // tree can only change on the backend — nothing the merchant does
          // invalidates it — so a long TTL is its refresh trigger.
          if (!entry.isOlderThan(GroceryLocalStore.catalogTtl)) return;
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

        if (rawList.isNotEmpty) {
          await (isSuper
              ? GroceryLocalStore.writeCatalogCategories(rawList)
              : GroceryLocalStore.writeCatalogChild(groceryCatKey, rawList));
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
