import 'package:BlueEra/features/me/product/model/get_product_model.dart';
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
}
