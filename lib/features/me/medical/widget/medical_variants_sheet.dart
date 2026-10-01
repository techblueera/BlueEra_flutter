import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variants_sheet.dart';
import 'package:BlueEra/features/me/medical/service/medical_variant_inventory_service.dart';
import 'package:flutter/material.dart';

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
