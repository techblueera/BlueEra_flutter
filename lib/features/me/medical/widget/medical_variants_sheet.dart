import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variants_sheet.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet listing **all variants** of one medical product, with
/// edit (MRP / selling price) and swipe-to-delete.
///
/// The UI is the grocery sheet — `medical-service/inventory/business-products`
/// ships grocery's exact response shape (see
/// docs/backend/MEDICAL_TOP_SELLING_BACKEND_GUIDE.md), so the same widget
/// renders both and there is nothing to gain from a second copy of 600 lines.
///
/// What is **not** shared is the service the edit and delete actions write to.
/// This entry point pins them to `medical-service`:
///
/// * `PUT medical-service/inventory/{inventoryId}`
/// * `DELETE medical-service/inventory/{inventoryId}`
///
/// and refreshes the medical business-products list afterwards. Calling
/// `showGroceryVariantsSheet` from a medical screen sent a medical inventory
/// id to `grocery-service/api/inventory/{id}` — the wrong service entirely,
/// and the medical rail never refreshed either.
Future<void> showMedicalVariantsSheet({
  required BuildContext context,
  required String productName,
  String? productImageUrl,
  required List<ProductVariants> variants,
}) {
  return showGroceryVariantsSheet(
    context: context,
    productName: productName,
    productImageUrl: productImageUrl,
    variants: variants,
    inventoryService: medicalVariantInventoryService(),
  );
}

/// Restores `batches[].quantity` to a **number** on the way out.
///
/// The two services mean different things by that field: in grocery it is a
/// pack size ("2 kg"), in medical it is the stock count (`quantity: 1`, which
/// is what `totalStock` sums). The shared sheet models it as a string because
/// grocery's does, so a medical price edit would otherwise post `"1"` — or,
/// worse, the pack-size text the sheet falls back to — into a numeric stock
/// field.
///
/// A value that isn't a number is dropped rather than guessed at: this form
/// edits price only, so leaving the key out keeps whatever stock the server
/// already holds.
Map<String, dynamic> _numericBatchQuantities(Map<String, dynamic> params) {
  final batches = params['batches'];
  if (batches is! List) return params;

  return {
    ...params,
    'batches': batches.map((batch) {
      if (batch is! Map) return batch;
      final normalised = Map<String, dynamic>.from(batch);
      final quantity = normalised['quantity'];
      if (quantity is num) return normalised;
      final parsed = num.tryParse(quantity?.toString().trim() ?? '');
      if (parsed != null) {
        normalised['quantity'] = parsed;
      } else {
        normalised.remove('quantity');
      }
      return normalised;
    }).toList(),
  };
}

/// The medical-service binding for the shared variants sheet.
VariantInventoryService medicalVariantInventoryService() {
  return VariantInventoryService(
    update: ({required inventoryId, required params}) =>
        MedicalRepo().updateMedicalInventoryRepo(
      inventoryId: inventoryId,
      params: _numericBatchQuantities(params),
    ),
    delete: ({required inventoryId}) =>
        MedicalRepo().deleteMedicalInventoryRepo(inventoryId: inventoryId),
    // Same set-semantics contract as grocery, on medical-service. This is what
    // turns the sheet's stock pill from read-only into the in/out switch.
    toggleOutOfStock: ({required inventoryIds, required isOutOfStock}) =>
        MedicalRepo().toggleOutOfStockRepo(
      inventoryIds: inventoryIds,
      isOutOfStock: isOutOfStock,
    ),
    refreshOwner: () {
      if (Get.isRegistered<MedicalController>()) {
        // Nudges the rail behind the sheet, drops the freshness stamp so the
        // next tab entry re-reads rather than trusting the edited copy, and
        // deletes the saved snapshot + refetches — without that last part the
        // edit would be undone by disk on the next open. See
        // [MedicalController.markInventoryChanged].
        Get.find<MedicalController>().markInventoryChanged();
      }
    },
  );
}
