
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/model/food_product_response_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Cart controller for the food self-pickup flow.
///
/// Mirrors [GrocerySelfPickupConsumerController] but for [FoodVariants].
/// The controller is registered when the user enters the food stores entry
/// point ([RestaurantNearMeScreen]) and deleted on exit so that cart state
/// is scoped to a browsing session — matching the grocery behavior where
/// going back from the stores list clears the cart.
class FoodSelfPickupController extends GetxController {
  RxBool isPlaceFoodOrderLoading = false.obs;
  Rx<ApiResponse> placeFoodOrderResponse = ApiResponse.initial('Initial').obs;

  /// Flat list of variants currently in the cart.
  RxList<FoodVariants> selectedFoodVariants = <FoodVariants>[].obs;

  /// Quantity per variant id.
  var cartQuantities = <String, int>{}.obs;

  /// Parent product id per variant id — used when placing the order.
  var cartProductIds = <String, String>{}.obs;

  /// Business info per variant id so we can show the store name in the cart
  /// and keep multi-store selections disambiguated.
  /// Shape: `{ variantId: { businessId, businessName, logo, address } }`.
  var cartBusinessInfo = <String, Map<String, String>>{}.obs;

  /// Product image per variant id — used to display images in the floating cart.
  var cartProductImages = <String, String>{}.obs;

  // ─────────────────────────────────────────────────────────────────────
  //  Mutations
  // ─────────────────────────────────────────────────────────────────────

  void addToCart(
    FoodVariants variant, {
    String? productId,
    String? businessId,
    String? businessName,
    String? businessLogo,
    String? businessAddress,
    String? productImage,
  }) {
    if (variant.id == null) return;

    if (cartQuantities.containsKey(variant.id)) {
      cartQuantities[variant.id!] = cartQuantities[variant.id]! + 1;
    } else {
      selectedFoodVariants.add(variant);
      cartQuantities[variant.id!] = 1;
      if (productId != null) {
        cartProductIds[variant.id!] = productId;
      }
      if (businessId != null) {
        cartBusinessInfo[variant.id!] = {
          'businessId': businessId,
          'businessName': businessName ?? '',
          'logo': businessLogo ?? '',
          'address': businessAddress ?? '',
        };
      }
      if (productImage != null && productImage.isNotEmpty) {
        cartProductImages[variant.id!] = productImage;
      }
    }
  }

  void removeFromCart(FoodVariants variant) {
    if (variant.id == null || !cartQuantities.containsKey(variant.id)) return;

    final currentQty = cartQuantities[variant.id]!;
    if (currentQty > 1) {
      cartQuantities[variant.id!] = currentQty - 1;
    } else {
      cartQuantities.remove(variant.id);
      cartProductIds.remove(variant.id);
      cartBusinessInfo.remove(variant.id);
      cartProductImages.remove(variant.id);
      selectedFoodVariants.removeWhere((v) => v.id == variant.id);
    }
  }

  /// Full wipe of the cart. Called by the entry point screen on back so
  /// selections don't leak across browsing sessions.
  void clearCart() {
    selectedFoodVariants.clear();
    cartQuantities.clear();
    cartProductIds.clear();
    cartBusinessInfo.clear();
    cartProductImages.clear();
  }

  bool isVariantInCart(String? variantId) {
    if (variantId == null) return false;
    return cartQuantities.containsKey(variantId);
  }

  int getQuantity(String? variantId) {
    if (variantId == null) return 0;
    return cartQuantities[variantId] ?? 0;
  }

  String? getProductId(String? variantId) {
    if (variantId == null) return null;
    return cartProductIds[variantId];
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Totals / bill
  // ─────────────────────────────────────────────────────────────────────

  double get totalMRP {
    double total = 0;
    for (final variant in selectedFoodVariants) {
      final qty = cartQuantities[variant.id] ?? 0;
      final mrp = (variant.mrp ?? 0).toDouble();
      total += mrp * qty;
    }
    return total;
  }

  double get totalSellingPrice {
    double total = 0;
    for (final variant in selectedFoodVariants) {
      final qty = cartQuantities[variant.id] ?? 0;
      final sp = (variant.baseSellingPrice ?? 0).toDouble();
      total += sp * qty;
    }
    return total;
  }

  double get totalSavings => totalMRP - totalSellingPrice;

  double get totalDiscountPercentage {
    if (totalMRP == 0) return 0.0;
    return (totalSavings / totalMRP) * 100;
  }

  int get totalItemsCount {
    int count = 0;
    cartQuantities.forEach((_, value) => count += value);
    return count;
  }

  /// Level-1 category id (left sidebar selection).
  var selectedCategoryId = ''.obs;

  /// Level-2 sub-category id (tab selection); `"all"` means "no tab filter".
  var selectedSubCategoryId = ''.obs;

  /// Level-2 children of the currently selected level-1 category.
  RxList<GroceryNestedCategoryModel> subCategoryTabs =
      <GroceryNestedCategoryModel>[].obs;

  /// Paginated flat list of products for the current category / sub-category.
  RxList<CategoryFoodProductData> categoryCustomerFoodProductDataList =
      <CategoryFoodProductData>[].obs;
  RxBool isFoodCatProductsWithInvLoading = false.obs;
  RxBool isFoodCatProductsWithInvLoadingMore = false.obs;
  int foodCatProductsWithInvPage = 1;
  bool foodCatProductsWithInvHasMore = true;

  /// Reset the category-listing pagination/state. Call when the user
  /// enters the listing screen or changes category/tab.
  void resetCategoryListingState() {
    categoryCustomerFoodProductDataList.clear();
    foodCatProductsWithInvPage = 1;
    foodCatProductsWithInvHasMore = true;
    isFoodCatProductsWithInvLoading.value = false;
    isFoodCatProductsWithInvLoadingMore.value = false;
  }

  /// Paginated fetch of food products scoped to a category (or the
  /// current sub-category) and optionally a visiting business. Copied
  /// verbatim from `FoodCustomerController.getCustomerFoodProductByCategoryIdApi`.
  Future<void> getCustomerFoodProductByCategoryIdApi({
    required Map<String, String> categoryIdParams,
    String? visitBusinessId,
    bool isLoadMore = false,
  }) async {
    try {
      if (isLoadMore) {
        isFoodCatProductsWithInvLoadingMore.value = true;
      } else {
        isFoodCatProductsWithInvLoading.value = true;
        categoryCustomerFoodProductDataList.clear();
        foodCatProductsWithInvPage = 1;
        foodCatProductsWithInvHasMore = true;
      }

      final String postalCode =
          LocationService.userCurrentAddress.value.postalCode;

      final Map<String, dynamic> queryParams = {
        ApiKeys.page: foodCatProductsWithInvPage,
        ApiKeys.limit: 20,
      };
      if (visitBusinessId == null) {
        queryParams[ApiKeys.pincode] = postalCode;
        queryParams[ApiKeys.radius] = kmRadius5000;
      } else {
        queryParams[ApiKeys.businessId] = visitBusinessId;
      }
      queryParams.addAll(categoryIdParams);

      final ResponseModel response =
          await FoodRepo().getUserFoodProductsCategoryIdRepo(
        queryParam: queryParams,
      );
      if (response.isSuccess) {
        final foodProductResponseModel =
            FoodProductResponseModel.fromJson(response.response?.data);

        // The category-listing API returns the inventory id at the
        // OUTER level (`MyFoodProductData.inventoryId`) — variants
        // nested in `productDetails.variants` don't carry their own
        // `inventoryId` on this endpoint. Copy the outer id down into
        // each variant so the cart's `buildBulkOrderItems` (which
        // reads `variant.inventoryId`) sends a non-empty inventory
        // ref and the place-order API succeeds. `??=` so we never
        // overwrite a variant that already has its own.
        final List<CategoryFoodProductData> newItems =
            (foodProductResponseModel.data ?? [])
                .where((item) => item.productDetails != null)
                .map((item) {
                  final pd = item.productDetails!;
                  final outerInv = item.inventoryId;
                  if (outerInv != null && outerInv.isNotEmpty) {
                    for (final v in pd.variants ?? const <FoodVariants>[]) {
                      v.inventoryId ??= outerInv;
                    }
                  }
                  return pd;
                })
                .toList();

        if (newItems.isNotEmpty) {
          if (isLoadMore) {
            categoryCustomerFoodProductDataList.addAll(newItems);
          } else {
            categoryCustomerFoodProductDataList.assignAll(newItems);
          }
          foodCatProductsWithInvPage++;
        } else {
          foodCatProductsWithInvHasMore = false;
        }
        debugPrint(
            'total food products-- ${categoryCustomerFoodProductDataList.length}');
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      debugPrint('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isFoodCatProductsWithInvLoadingMore.value = false;
      } else {
        isFoodCatProductsWithInvLoading.value = false;
      }
    }
  }

  /// Build the payload for a bulk self-pickup food order.
  List<Map<String, dynamic>> buildBulkOrderItems() {
    final items = <Map<String, dynamic>>[];
    for (final variant in selectedFoodVariants) {
      final qty = cartQuantities[variant.id] ?? 0;
      if (qty <= 0) continue;

      final mrp = (variant.mrp ?? 0).toDouble();
      final sp = (variant.baseSellingPrice ?? 0).toDouble();

      items.add({
        'inventory': variant.inventoryId ?? '',
        'productVariant': variant.id ?? '',
        'quantity': qty,
        'mrp': mrp,
        'sellingPrice': sp,
      });
    }
    return items;
  }

  /// Place a bulk food self-pickup order — mirrors grocery flow.
  Future<void> placeFoodOrderApi() async {
    try {
      isPlaceFoodOrderLoading.value = true;
      AppLoader.show();

      final itemsList = buildBulkOrderItems();

      final Map<String, dynamic> requestBody = {
        "items": itemsList,
        "deliveryType": "self-pickup",
        "discount": totalSavings,
      };

      final response =
          await FoodRepo().placeBulkFoodOrderApi(params: requestBody);

      if (!response.isSuccess) {
        AppLoader.hide();
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      // Navigate FIRST, clear the cart afterwards — mirrors the
      // grocery flow. Clearing before navigation triggers an Obx
      // rebuild on the cart screen (selectedFoodVariants empties →
      // empty-state widget mounts) which on some routes interferes
      // with `Get.until` resolving to BottomNavigationBarScreen, so
      // the chat hand-off never fired in food. Doing it in the same
      // order grocery does keeps the navigation deterministic.
      final bottomController = getOrPut(() => BottomBarController());
      bottomController.onChangeIndex(2);

      ChatViewController chatViewController =
          getOrPut(() => ChatViewController());
      chatViewController.emitEvent(
        ChatEmitEvents.ChatList,
        {ApiKeys.type: AppConstants.order_Chat_Type},
      );
      chatViewController.onSelectChatTab(2);

      Get.until((route) =>
          route.settings.name == RouteConstant.BottomNavigationBarScreen);

      placeFoodOrderResponse.value = ApiResponse.complete(response);
      AppLoader.hide();
      selectedFoodVariants.clear();
      cartQuantities.clear();
      cartBusinessInfo.clear();
      cartProductIds.clear();
      // Was missing — left the variant→thumbnail map populated
      // across sessions, leaking memory and stale image refs.
      cartProductImages.clear();
    } catch (e) {
      AppLoader.hide();
      placeFoodOrderResponse.value = ApiResponse.error('error');
    } finally {
      isPlaceFoodOrderLoading.value = false;
    }
  }
}
