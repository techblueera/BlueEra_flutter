import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/repo/inventory_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// Session-scoped cart for the product self-pickup flow.
///
/// Mirrors [FoodSelfPickupController] / [GrocerySelfPickupConsumerController]
/// but for [GetProductData] (the shape returned by
/// `InventoryController.fetchProductsByCategory`). Registered when the
/// user enters [ProductsStoreScreen] (the products entry point) and
/// deleted on exit so cart state is scoped to a browsing session.
///
/// Keyed by the first variant id of each product — that variant is what
/// carries the selling price / MRP used for totals.
class ProductSelfPickupController extends GetxController {
  RxBool isPlaceProductOrderLoading = false.obs;
  Rx<ApiResponse> placeProductOrderResponse = ApiResponse.initial('Initial').obs;

  /// Flat list of products currently in the cart.
  RxList<GetProductData> selectedProductVariants = <GetProductData>[].obs;

  /// Quantity per variant id.
  var cartQuantities = <String, int>{}.obs;

  /// Business info per variant id so the cart can be grouped by store.
  /// Shape: `{ variantId: { businessId, businessName, logo, address } }`.
  var cartBusinessInfo = <String, Map<String, String>>{}.obs;

  // ─────────────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────────────

  /// First variant id of a product (used as the cart key).
  String? _variantIdOf(GetProductData product) {
    final variants = product.product.sellerClassification?.variants;
    if (variants == null || variants.isEmpty) return null;
    final id = variants.first.id;
    return id.isEmpty ? null : id;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Mutations
  // ─────────────────────────────────────────────────────────────────────

  void addToCart(
    GetProductData product, {
    String? businessId,
    String? businessName,
    String? businessLogo,
    String? businessAddress,
  }) {
    final id = _variantIdOf(product);
    if (id == null) return;

    if (cartQuantities.containsKey(id)) {
      cartQuantities[id] = cartQuantities[id]! + 1;
    } else {
      selectedProductVariants.add(product);
      cartQuantities[id] = 1;
      if (businessId != null) {
        cartBusinessInfo[id] = {
          'businessId': businessId,
          'businessName': businessName ?? '',
          'logo': businessLogo ?? '',
          'address': businessAddress ?? '',
        };
      }
    }
  }

  void removeFromCart(GetProductData product) {
    final id = _variantIdOf(product);
    if (id == null || !cartQuantities.containsKey(id)) return;

    final currentQty = cartQuantities[id]!;
    if (currentQty > 1) {
      cartQuantities[id] = currentQty - 1;
    } else {
      cartQuantities.remove(id);
      cartBusinessInfo.remove(id);
      selectedProductVariants.removeWhere(
        (p) => _variantIdOf(p) == id,
      );
    }
  }

  /// Full wipe of the cart. Called by the entry point on back so
  /// selections don't leak across browsing sessions.
  void clearCart() {
    selectedProductVariants.clear();
    cartQuantities.clear();
    cartBusinessInfo.clear();
  }

  bool isVariantInCart(String? variantId) {
    if (variantId == null || variantId.isEmpty) return false;
    return cartQuantities.containsKey(variantId);
  }

  int getQuantity(String? variantId) {
    if (variantId == null || variantId.isEmpty) return 0;
    return cartQuantities[variantId] ?? 0;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Totals / bill
  // ─────────────────────────────────────────────────────────────────────

  double get totalMRP {
    double total = 0;
    for (final product in selectedProductVariants) {
      final variants = product.product.sellerClassification?.variants ?? [];
      if (variants.isEmpty) continue;
      final qty = cartQuantities[variants.first.id] ?? 0;
      total += variants.first.mrp.toDouble() * qty;
    }
    return total;
  }

  double get totalSellingPrice {
    double total = 0;
    for (final product in selectedProductVariants) {
      final variants = product.product.sellerClassification?.variants ?? [];
      if (variants.isEmpty) continue;
      final qty = cartQuantities[variants.first.id] ?? 0;
      total += variants.first.sellingPrice.toDouble() * qty;
    }
    return total;
  }

  double get totalSavings => totalMRP - totalSellingPrice;

  int get totalItemsCount {
    int count = 0;
    cartQuantities.forEach((_, value) => count += value);
    return count;
  }

  /// Build order payload per the integration guide.
  List<Map<String, dynamic>> buildBulkOrderItems() {
    final items = <Map<String, dynamic>>[];
    for (final product in selectedProductVariants) {
      final sc = product.product.sellerClassification;
      final variants = sc?.variants ?? [];
      if (variants.isEmpty) continue;

      final variant = variants.first;
      final qty = cartQuantities[variant.id] ?? 0;
      if (qty <= 0) continue;

      items.add({
        'inventory': sc?.id ?? '',
        'variantId': variant.id,
        'quantity': qty,
        'mrp': variant.mrp.toDouble(),
        'sellingPrice': variant.sellingPrice.toDouble(),
      });
    }
    return items;
  }

  /// Place a bulk product self-pickup order.
  Future<void> placeProductOrderApi() async {
    try {
      isPlaceProductOrderLoading.value = true;
      AppLoader.show();

      final itemsList = buildBulkOrderItems();

      final Map<String, dynamic> requestBody = {
        "items": itemsList,
        "deliveryType": "self-pickup",
        "discount": totalSavings,
      };

      final response =
          await InventoryRepo().placeBulkProductOrderApi(params: requestBody);

      if (!response.isSuccess) {
        AppLoader.hide();
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      placeProductOrderResponse.value = ApiResponse.complete(response);
      AppLoader.hide();
      clearCart();

      final bottomController = getOrPut(() => BottomBarController());
      bottomController.onChangeIndex(3);

      ChatViewController chatViewController =
          getOrPut(() => ChatViewController());
      chatViewController.onSelectChatTab(3);
      chatViewController.emitEvent(
        ChatEmitEvents.ChatList,
        {ApiKeys.type: AppConstants.order_Chat_Type},
      );

      Get.until((route) =>
          route.settings.name == RouteConstant.BottomNavigationBarScreen);
    } catch (e) {
      AppLoader.hide();
      placeProductOrderResponse.value = ApiResponse.error('error');
    } finally {
      isPlaceProductOrderLoading.value = false;
    }
  }
}
