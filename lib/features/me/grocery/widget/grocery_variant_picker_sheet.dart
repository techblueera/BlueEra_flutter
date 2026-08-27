import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/widgets/variant_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The label under a locked row, shared by every grocery entry point.
const String kGroceryStockedNote =
    'This variant is already in your store — edit its price from the Products '
    'tab.';

/// Opens the grocery variant picker for [product].
///
/// The "+" on a product card used to select the whole product, which meant
/// publishing every pack size the catalogue carries. This is the food-style
/// picker instead: the merchant ticks the packs they actually stock, and a
/// pack that is already on their shelf is locked rather than offered again.
///
/// [isSelected] / [onToggle] default to the catalogue cart
/// ([GroceryController.selectedProductVariants] kept in step with
/// `selectedGroceries`). Snap search overrides them — it keeps its own product
/// list rather than the product cart, so it must not touch `selectedGroceries`.
void showGroceryVariantPickerSheet({
  required BuildContext context,
  required GroceryProductData product,
  required GroceryController controller,
  bool Function(String variantId)? isSelected,
  void Function(ProductVariants variant)? onToggle,
  bool showAddMore = true,
}) {
  final productId = product.sId ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return VariantPickerSheet(
        productName: product.name ?? '',
        imageUrl: (product.images?.isNotEmpty ?? false)
            ? product.images!.first.url
            : null,
        description: product.description,
        stockedNote: kGroceryStockedNote,
        // Read straight off the controller: this runs inside the sheet's Obx,
        // so a tick repaints the rows and the "in cart" count together.
        rowsBuilder: () {
          final variants = product.variants ?? const <ProductVariants>[];
          return variants.map((v) {
            final price = v.pricing?.isNotEmpty == true ? v.pricing!.first : null;
            return VariantPickerRow(
              id: v.sId ?? '',
              title: (v.quantity?.trim().isNotEmpty ?? false)
                  ? v.quantity!
                  : (v.variantName ?? ''),
              sellingPrice: price?.sellingPrice != null
                  ? '₹${price!.sellingPrice}'
                  : null,
              mrp: price?.mrp != null ? '₹${price!.mrp}' : null,
              isStocked: controller.isVariantStocked(v.sId),
              isSelected: isSelected != null
                  ? isSelected(v.sId ?? '')
                  : controller.isVariantSelected(productId, v.sId ?? ''),
            );
          }).toList();
        },
        onToggle: (variantId) {
          final variant = (product.variants ?? const <ProductVariants>[])
              .firstWhereOrNull((v) => v.sId == variantId);
          if (variant == null) return;
          if (onToggle != null) {
            onToggle(variant);
          } else {
            controller.toggleVariantSelection(product, variant);
          }
        },
        // Creating a catalogue variant publishes into the merchant's own cart,
        // so it belongs to the catalogue flow only — snap search hides it.
        onAddMore: showAddMore
            ? () => controller.openAddVariantDialog(
                  context: context,
                  groceryItem: product,
                )
            : null,
      );
    },
  );
}
