import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/widget/medical_product_card.dart';

/// Adapts the pharmacy home payload's product shapes onto the flat
/// [MedicalCardProduct] that [MedicalProductCard] renders.
///
/// The payload carries two different product shapes — [CategoryProduct] (rich:
/// nested in the category tree, with variants, form and the prescription flag)
/// and [PopularProduct] (flat: one pre-picked variant + batch). Both feed the
/// same card, so the mapping lives here rather than being re-written per screen.
extension CategoryProductCardAdapter on CategoryProduct {
  /// Variants with no `_id` are dropped — [MedicalCardVariant.variantId] is
  /// required and the cart is keyed by it, so a null id could never be added,
  /// removed or counted.
  MedicalCardProduct toCardProduct() {
    final productImage = images?.firstOrNull?.url;

    final cardVariants = <MedicalCardVariant>[];
    for (final v in variants ?? const <CategoryProductVariant>[]) {
      final id = v.sId;
      if (id == null || id.isEmpty) continue;

      // Prefer this pharmacy's own batch pricing over the catalog list price —
      // the same rule GroceryProductCard applies (inventory batches first,
      // catalog `pricing` only as a fallback).
      final batch = v.inventory?.batches?.firstOrNull;
      final catalog = v.pricing?.firstOrNull;
      final variantImage = v.images?.firstOrNull?.url;

      cardVariants.add(MedicalCardVariant(
        variantId: id,
        variantName: v.variantName,
        inventoryId: v.inventory?.inventoryId,
        mrp: batch?.mrp ?? catalog?.mrp,
        sellingPrice: batch?.sellingPrice ?? catalog?.sellingPrice,
        imageUrl: (variantImage ?? '').isNotEmpty ? variantImage : productImage,
      ));
    }

    return MedicalCardProduct(
      productId: sId,
      name: name,
      brand: brand,
      form: productForm,
      isPrescriptionRequired: isPrescriptionRequired ?? false,
      imageUrl: productImage,
      variants: cardVariants,
    );
  }
}

extension PopularProductCardAdapter on PopularProduct {
  /// [PopularProduct] has no `productForm` and no prescription flag, so the
  /// card can't show the Rx badge for these — see
  /// docs/backend/PHARMACY_CUSTOMER_FLOW_INTEGRATION.md.
  ///
  /// Returns null when there's no usable variant id, which would leave the card
  /// with nothing to add to the cart.
  MedicalCardProduct? toCardProduct() {
    // Fall back to the popular-product entry's own id when the API omits an
    // explicit `variant._id`.
    final variantId = variant?.sId ?? sId;
    if (variantId == null || variantId.isEmpty) return null;

    final productImage = product?.images?.firstOrNull?.url;
    final variantImage = variant?.images?.firstOrNull?.url;

    return MedicalCardProduct(
      productId: product?.sId,
      name: product?.name ?? variant?.variantName,
      brand: product?.brand,
      imageUrl: (productImage ?? '').isNotEmpty ? productImage : variantImage,
      variants: [
        MedicalCardVariant(
          variantId: variantId,
          variantName: variant?.variantName,
          inventoryId: sId,
          mrp: batches?.mrp ?? variant?.pricing?.firstOrNull?.mrp,
          sellingPrice: batches?.sellingPrice ??
              variant?.pricing?.firstOrNull?.sellingPrice,
          imageUrl:
              (variantImage ?? '').isNotEmpty ? variantImage : productImage,
        ),
      ],
    );
  }
}
