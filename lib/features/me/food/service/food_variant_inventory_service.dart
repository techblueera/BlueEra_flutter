import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:get/get.dart';

/// The owner's edits to a published dish's variants — price, stock and delete —
/// for the food variant sheet. The food counterpart of the grocery and medical
/// `VariantInventoryService`.
///
/// Each edit goes to `kitchen-inventory`, then mirrors onto the [product] the
/// screen behind the sheet is showing (so it reflects the change on return
/// without a refetch) and tells [RestaurantController] the menu changed. The
/// mirror happens whenever the server accepted the edit, even if the sheet was
/// closed meanwhile.
///
/// Every method returns null on success, or the message to show on failure.
class FoodVariantInventoryService {
  FoodVariantInventoryService({FoodRepo? repo}) : _repo = repo ?? FoodRepo();

  final FoodRepo _repo;

  /// Writes a new selling price / MRP pair.
  ///
  /// READ, merge, then write. `PUT kitchen-inventory/{id}` replaces the whole
  /// `price` subdocument, so sending only `{mrp, sellingPrice}` silently reset
  /// `packingCharges` to 0 (verified against the live service — 20 became 0).
  /// The variant models parsed from the listing endpoints carry neither
  /// `currency` nor `packingCharges`, so the only way to send them back
  /// unchanged is to fetch the record first.
  ///
  /// A failed pre-read ABORTS rather than writing what it has: a price edit
  /// must not be able to zero a charge the merchant never touched.
  Future<String?> updatePrice(
    CategoryFoodProductData product,
    FoodVariants item, {
    required int sellingPrice,
    required int mrp,
  }) async {
    final inventoryId = item.inventoryId ?? '';
    final current =
        await _repo.getKitchenInventoryByIdRepo(inventoryId: inventoryId);
    final existingPrice = current.isSuccess
        ? (current.response?.data?['data']?['price'] as Map?)
        : null;
    if (existingPrice == null) {
      return "Couldn't read the current price. Please try again.";
    }

    final res = await _repo.updateKitchenInventoryVariantRepo(
      inventoryId: inventoryId,
      params: {
        'price': {
          // Everything the record already had, with only the two edited
          // numbers replaced.
          ...Map<String, dynamic>.from(existingPrice),
          'mrp': mrp,
          'sellingPrice': sellingPrice,
        },
      },
    );
    if (!res.isSuccess) return res.message ?? "Couldn't update the price.";

    item.baseSellingPrice = sellingPrice;
    item.mrp = mrp;
    for (final v in product.variants ?? const <FoodVariants>[]) {
      if (v.inventoryId == inventoryId) {
        v.baseSellingPrice = sellingPrice;
        v.mrp = mrp;
      }
    }
    // Repairs what this in-place patch cannot reach: the freshness guard, the
    // sibling rails still holding the old row, and the saved snapshot on disk —
    // a stale snapshot would put the old price straight back on the next open.
    _markMenuChanged();
    return null;
  }

  /// Flips one variant's manual out-of-stock flag via
  /// `PATCH kitchen-inventory/stock/flip-out-of-stock`.
  ///
  /// A FLIP, not a set — no value goes up. That is safe because
  /// `StockStatusPill` only ever calls back with `!currentFlag`, so
  /// [markOutOfStock] IS the inverse of what the server holds, and applying it
  /// here matches what the flip just did.
  Future<String?> setOutOfStock(
    CategoryFoodProductData product,
    FoodVariants item,
    bool markOutOfStock,
  ) async {
    final inventoryId = item.inventoryId ?? '';
    final res = await _repo.flipOutOfStockRepo(inventoryIds: [inventoryId]);
    if (!res.isSuccess) return res.message ?? "Couldn't update stock.";

    item.isOutOfStock = markOutOfStock;
    for (final v in product.variants ?? const <FoodVariants>[]) {
      if (v.inventoryId == inventoryId) v.isOutOfStock = markOutOfStock;
    }
    // See [RestaurantController.markMenuChanged].
    _markMenuChanged();
    return null;
  }

  /// `DELETE kitchen-inventory/{inventoryId}`, then drops the variant from
  /// [product].
  Future<String?> delete(
      CategoryFoodProductData product, FoodVariants item) async {
    final inventoryId = item.inventoryId ?? '';
    final res =
        await _repo.deleteKitchenInventoryRepo(inventoryId: inventoryId);
    if (!res.isSuccess) return res.message ?? 'Could not delete the variant.';

    product.variants?.removeWhere((v) => v.inventoryId == inventoryId);
    // Ask the food screens to refetch on return so counts stay in sync, and
    // drop the saved snapshot — a deleted variant must not survive on disk.
    _markMenuChanged();
    // A deleted variant is stockable again, so the add screens must start
    // offering it once more — the mirror of the refresh a publish triggers.
    if (Get.isRegistered<FoodServiceController>()) {
      Get.find<FoodServiceController>().markStockedVariantsChanged();
    }
    return null;
  }

  void _markMenuChanged() {
    if (Get.isRegistered<RestaurantController>()) {
      Get.find<RestaurantController>().markMenuChanged();
    }
  }
}
