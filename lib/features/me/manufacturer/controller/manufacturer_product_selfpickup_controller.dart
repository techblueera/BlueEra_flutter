import 'package:BlueEra/features/me/product/model/order_checkout_payload.dart';
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
import 'package:BlueEra/features/me/manufacturer/repo/manufacturer_product_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// Session-scoped cart for the product self-pickup flow.
///
/// Mirrors [FoodSelfPickupController] / [GrocerySelfPickupConsumerController]
/// but for [GetProductData] (the shape returned by
/// `ManufacturerInventoryController.fetchProductsByCategory`). Registered when the
/// user enters [ManufacturerProductsStoreScreen] (the products entry point) and
/// deleted on exit so cart state is scoped to a browsing session.
///
/// Keyed by the first variant id of each product — that variant is what
/// carries the selling price / MRP used for totals.
class ManufacturerProductSelfPickupController extends GetxController {
  // One idempotency key per checkout ATTEMPT. The `isPlacing…` guard already
  // in this controller stops a double-tap inside one session, but it cannot
  // survive a lost response — the request lands, the reply doesn't come back,
  // the user taps again, and the shop gets two orders. This key is what makes
  // that retry safe: the second POST resolves to the SAME order with a 200.
  // See lib/docs/FLUTTER_ORDER_FLOW_UI_GUIDE.md §4.1.
  final CheckoutAttempt _checkoutAttempt = CheckoutAttempt();

  /// Call when the checkout sheet OPENS — not on every tap.
  void beginCheckoutAttempt() => _checkoutAttempt.begin();

  /// `cash` (default) or `upi`, chosen in the checkout sheet. With `upi` the
  /// customer is asked for money only AFTER the shop accepts — if the shop
  /// turns out to be closed, nobody has to be refunded (guide §5, §6.1).
  ///
  /// This vertical's service does not take doorstep orders yet, so the sheet
  /// offers no delivery step and `deliveryType` stays `self-pickup`.
  final RxString paymentMethod = OrderPaymentMethod.cash.obs;


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
        // The order endpoint keys off the per-variant inventory record id,
        // not the seller-classification id (which is empty here). Fall back to
        // sc.id only when the variant has no inventory id.
        'inventory': variant.inventoryId.isNotEmpty
            ? variant.inventoryId
            : (sc?.id ?? ''),
        'productVariant': variant.id,
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
        "deliveryType": OrderDeliveryType.selfPickup,
        "discount": totalSavings,
        // Cash is what this cart offers today. Sending it explicitly keeps the
        // order out of the UPI submit/verify flow rather than leaning on a
        // server-side default that could change.
        "paymentMethod": paymentMethod.value,
        "idempotencyKey": _checkoutAttempt.key,
      };

      final response =
          await ManufacturerProductRepo().placeBulkProductOrderApi(params: requestBody);

      if (!response.isSuccess) {
        AppLoader.hide();
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      placeProductOrderResponse.value = ApiResponse.complete(response);
      AppLoader.hide();
      // 201 = created, 200 = already created under this key. Both are success,
      // and both finish the attempt — a NEW order needs a NEW key.
      _checkoutAttempt.complete();
      clearCart();

      // Land on Discover (index 1) instead of the chat screen — the placed
      // order surfaces there in the "Orders in 12 Hrs." rail. The business
      // chat list is still refreshed so that rail has the new row.
      final bottomController = getOrPut(() => BottomBarController());
      bottomController.onChangeIndex(1);

      ChatViewController chatViewController =
          getOrPut(() => ChatViewController());
      chatViewController.emitEvent(ChatEmitEvents.ChatList, {ApiKeys.type: AppConstants.business_Chat_Type},);


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
