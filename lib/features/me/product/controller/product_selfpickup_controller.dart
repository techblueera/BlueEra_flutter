import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/order_checkout_payload.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
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

  // ── Checkout attempt ──────────────────────────────────────────────────
  //
  // One idempotency key per checkout ATTEMPT. `isPlaceProductOrderLoading`
  // below already guards a double-tap within one session, but it cannot
  // survive a lost response — the request reaches the server, the reply never
  // comes back, the user taps again, and the shop gets two orders. The key is
  // what makes that retry safe. See lib/docs/FLUTTER_ORDER_FLOW_UI_GUIDE.md §4.1.
  final CheckoutAttempt _checkoutAttempt = CheckoutAttempt();

  /// Call when the checkout sheet OPENS — not on every tap.
  void beginCheckoutAttempt() => _checkoutAttempt.begin();

  // ── Delivery & payment choice (set by the checkout sheet) ─────────────

  /// `self-pickup` (default) or `rider`.
  final RxString deliveryType = OrderDeliveryType.selfPickup.obs;

  /// `cash` (default) or `upi`. With `upi` the customer is asked for money
  /// only AFTER the shop accepts — if the shop turns out to be closed, nobody
  /// has to be refunded.
  final RxString paymentMethod = OrderPaymentMethod.cash.obs;

  /// Address + quote details for a rider order. Required when
  /// [deliveryType] is `rider`, sent whenever it is known.
  final Rxn<OrderDeliveryDetails> deliveryDetails =
      Rxn<OrderDeliveryDetails>();

  /// The quote the customer was actually shown. Kept so the checkout sheet can
  /// render the fee / ETA / economics note and so the order records it.
  final Rxn<DeliveryQuote> deliveryQuote = Rxn<DeliveryQuote>();

  bool get isDelivery => deliveryType.value == OrderDeliveryType.rider;

  /// Fetch a delivery quote for the current address. Debounce the caller ~400
  /// ms on address change. An out-of-radius address answers `feasible:false`
  /// — a UI state, not an error: the sheet disables the delivery option and
  /// falls back to self-pickup.
  Future<DeliveryQuote?> refreshDeliveryQuote({
    required double shopLat,
    required double shopLng,
    required double dropLat,
    required double dropLng,
    num? orderValue,
  }) async {
    final quote = await OrderLifecycleController.instance.fetchDeliveryQuote(
      shopLat: shopLat,
      shopLng: shopLng,
      dropLat: dropLat,
      dropLng: dropLng,
      orderValue: orderValue ?? totalSellingPrice,
    );
    deliveryQuote.value = quote;
    if (quote != null && !quote.feasible) {
      // Never leave the user on an option that cannot be fulfilled.
      deliveryType.value = OrderDeliveryType.selfPickup;
    }
    return quote;
  }

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
    String? userId,
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
      if (userId != null) {
        cartBusinessInfo[id] = {
          'businessId': userId,
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

  // ═══════════════════════════════════════════════════════════════════════
  //  MULTI-STORE (Zomato-style) — products from different stores stack into
  //  separate per-store carts; the floating cart previews them and the user
  //  checks out from the cart screen. Built on top of cartBusinessInfo.
  // ═══════════════════════════════════════════════════════════════════════

  bool get isEmpty => selectedProductVariants.isEmpty;

  String? _businessIdOf(GetProductData p) =>
      cartBusinessInfo[_variantIdOf(p)]?['businessId'];

  /// Distinct business ids currently in the cart, in first-added order.
  List<String> get storeKeys {
    final seen = <String>[];
    for (final p in selectedProductVariants) {
      final bid = _businessIdOf(p);
      if (bid != null && bid.isNotEmpty && !seen.contains(bid)) seen.add(bid);
    }
    return seen;
  }

  int get storeCount => storeKeys.length;

  /// Store metadata map ({businessName, logo, address}) for a business id,
  /// read off any of its products.
  Map<String, String> storeInfoOf(String businessId) {
    for (final p in selectedProductVariants) {
      final info = cartBusinessInfo[_variantIdOf(p)];
      if (info != null && info['businessId'] == businessId) return info;
    }
    return const {};
  }

  List<GetProductData> variantsOf(String businessId) => selectedProductVariants
      .where((p) => _businessIdOf(p) == businessId)
      .toList();

  int itemCountOf(String businessId) {
    int c = 0;
    for (final p in variantsOf(businessId)) {
      c += cartQuantities[_variantIdOf(p)] ?? 0;
    }
    return c;
  }

  /// Product thumbnail — prefers the product-level media, then falls back to
  /// the first variant's media. Delegates to [GetProductData.primaryImageUrl]
  /// so the cart and every other product surface resolve the same image.
  String? imageOf(GetProductData p) => p.primaryImageUrl;

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

      // Guard: the order endpoint rejects items with a blank `inventory`.
      // When the products API response doesn't carry the per-variant
      // inventory id, the payload would otherwise go out with an empty
      // string and the server returns a generic failure ("order not
      // placed") with no actionable reason. Catch it here instead.
      final hasEmptyInventory = itemsList.isEmpty ||
          itemsList.any((it) =>
              (it['inventory']?.toString().isEmpty ?? true) ||
              (it['productVariant']?.toString().isEmpty ?? true));
      if (hasEmptyInventory) {
        AppLoader.hide();
        logs('placeProductOrderApi aborted — bad items payload: $itemsList');
        commonSnackBar(
          message: AppStrings.somethingWentWrong,
        );
        return;
      }

      // The three new fields are all backwards compatible — the old
      // three-field payload still creates an order — but sending them is what
      // makes the delivery path reachable, the UPI flow reachable, and a
      // retry safe.
      final delivery = deliveryDetails.value;
      final quote = deliveryQuote.value;
      final Map<String, dynamic> requestBody = {
        "items": itemsList,
        "deliveryType": deliveryType.value,
        "discount": totalSavings,
        if (delivery != null && !delivery.isEmpty)
          "delivery": {
            ...delivery.toJson(),
            // Record what the customer was shown, not what we can recompute.
            if (quote != null) ...{
              if (quote.distanceKm != null) 'distanceKm': quote.distanceKm,
              if (quote.deliveryFee != null) 'feeEstimate': quote.deliveryFee,
              if (quote.etaMinutes != null) 'etaMinutes': quote.etaMinutes,
            },
          },
        "paymentMethod": paymentMethod.value,
        "idempotencyKey": _checkoutAttempt.key,
      };

      logs('placeProductOrderApi request: $requestBody');

      final response =
          await ProductRepo().placeBulkProductOrderApi(params: requestBody);

      if (!response.isSuccess) {
        AppLoader.hide();
        logs('placeProductOrderApi failed: '
            'status=${response.response?.statusCode} '
            'message=${response.message} body=${response.response?.data}');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      // 201 = created, 200 = you already created this one (the idempotency key
      // matched an earlier attempt). Both are success, and both mean this
      // attempt is finished — a NEW order needs a NEW key.
      _checkoutAttempt.complete();

      placeProductOrderResponse.value = ApiResponse.complete(response);
      AppLoader.hide();
      clearCart();
      deliveryDetails.value = null;
      deliveryQuote.value = null;
      deliveryType.value = OrderDeliveryType.selfPickup;
      paymentMethod.value = OrderPaymentMethod.cash;

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
      logs('placeProductOrderApi exception: $e');
      placeProductOrderResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isPlaceProductOrderLoading.value = false;
    }
  }
}
