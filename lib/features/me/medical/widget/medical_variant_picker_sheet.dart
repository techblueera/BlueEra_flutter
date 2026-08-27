import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart';
import 'package:BlueEra/widgets/variant_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The label under a locked row, shared by every medical entry point.
const String kMedicalStockedNote =
    'This variant is already in your store — edit its price from the Products '
    'tab.';

/// Opens the medical variant picker for [product].
///
/// The Add button on a product card used to select the whole product, which
/// meant publishing every pack the catalogue carries. This is the food-style
/// picker instead: the pharmacy ticks the packs it actually stocks, and a pack
/// already on its shelf is locked rather than offered again.
///
/// [isSelected] / [onToggle] default to the catalogue cart
/// ([MedicalController.selectedProductVariants] kept in step with
/// `selectedMedicalProducts`). Snap search overrides them — it publishes from
/// its own map and must not touch the catalogue cart.
void showMedicalVariantPickerSheet({
  required BuildContext context,
  required MedicalProductData product,
  required MedicalController controller,
  bool Function(String variantId)? isSelected,
  void Function(VariantsData variant)? onToggle,
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
        stockedNote: kMedicalStockedNote,
        rowsBuilder: () {
          final variants = product.variants ?? const <VariantsData>[];
          return variants.map((v) {
            // The pricing row for THIS shop's pincode, not `pricing[0]` —
            // that is whichever city the catalog happened to list first, and
            // it is not what gets published.
            final price = controller.resolvePublishPricing(v.pricing);
            return VariantPickerRow(
              id: v.sId ?? '',
              title: medicalPackLabel(v),
              sellingPrice: price?.sellingPrice != null
                  ? controller.formatMoney(price!.sellingPrice)
                  : null,
              mrp: price?.mrp != null ? controller.formatMoney(price!.mrp) : null,
              isStocked: controller.isVariantStocked(v.sId),
              isSelected: isSelected != null
                  ? isSelected(v.sId ?? '')
                  : controller.isVariantSelected(productId, v.sId ?? ''),
            );
          }).toList();
        },
        onToggle: (variantId) {
          final variant = (product.variants ?? const <VariantsData>[])
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

/// Pack size — "10 tablet", or just the unit when the catalog has no number
/// for it. `weight` is genuinely absent on plenty of medical products (a spray
/// has a unit but no quantity), and interpolating it straight through is where
/// the literal "null spray" on the cards came from.
String medicalPackLabel(VariantsData variant) {
  final unit = (variant.unit ?? '').trim();
  final weight = variant.weight;
  if (weight != null && weight > 0) {
    final amount =
        weight == weight.roundToDouble() ? weight.round().toString() : '$weight';
    return unit.isEmpty ? amount : '$amount $unit';
  }
  if (unit.isNotEmpty) return unit;
  return (variant.variantName ?? '').trim();
}
