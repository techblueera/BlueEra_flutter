import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Which service the sheet's edit / delete actions write to.
///
/// The sheet is shared by more than one me-section module because the
/// business-products response shape is identical across them — but the
/// **endpoints are not**. Without this, a pharmacy editing a variant from the
/// medical Top Selling rail posted a medical inventory id to
/// `grocery-service`, which is simply the wrong service.
///
/// [refreshOwner] nudges whichever controller owns the list behind the sheet,
/// since mutating an element in place doesn't notify an RxList.
class VariantInventoryService {
  final Future<ResponseModel> Function({
    required String inventoryId,
    required Map<String, dynamic> params,
  }) update;

  final Future<ResponseModel> Function({required String inventoryId}) delete;

  /// Marks inventory records in / out of stock. **Optional** — a service that
  /// leaves it null simply doesn't get the stock toggle, which is how the
  /// medical binding opts out until its own endpoint is confirmed.
  final Future<ResponseModel> Function({
    required List<String> inventoryIds,
    required bool isOutOfStock,
  })? toggleOutOfStock;

  final VoidCallback refreshOwner;

  const VariantInventoryService({
    required this.update,
    required this.delete,
    required this.refreshOwner,
    this.toggleOutOfStock,
  });

  /// `grocery-service/api/inventory/{id}` — the default, so every existing
  /// grocery call site keeps working untouched.
  factory VariantInventoryService.grocery() {
    return VariantInventoryService(
      update: ({required inventoryId, required params}) =>
          GroceryRepo().updateInventoryVariantRepo(
        inventoryId: inventoryId,
        params: params,
      ),
      delete: ({required inventoryId}) =>
          GroceryRepo().deleteInventoryVariantRepo(inventoryId: inventoryId),
      toggleOutOfStock: ({required inventoryIds, required isOutOfStock}) =>
          GroceryRepo().toggleOutOfStockRepo(
        inventoryIds: inventoryIds,
        isOutOfStock: isOutOfStock,
      ),
      // Called after every accepted write in this sheet — price edit, delete,
      // stock toggle. The sheet has already patched its own copy of the
      // variant; this is what repairs everything it cannot reach: the owner's
      // lists (a deleted variant used to linger in `groceryBusinessProductsList`
      // until something forced a real fetch), the freshness guard, and the
      // saved snapshot on disk. See [GroceryController.markInventoryChanged].
      refreshOwner: () {
        if (Get.isRegistered<GroceryController>()) {
          Get.find<GroceryController>().markInventoryChanged();
        }
      },
    );
  }
}
