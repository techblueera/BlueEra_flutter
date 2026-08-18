import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart'
    as medical show Pricing;
import 'package:BlueEra/features/me/medical/widget/rx_badge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/fallback_network_image.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/card_name_slack.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The pharmacy Top Selling card.
///
/// ## Why this is not the grocery card
///
/// It used to be. `medical-service/inventory/business-products` ships grocery's
/// exact response shape (docs/backend/MEDICAL_TOP_SELLING_BACKEND_GUIDE.md), so
/// medical rendered [GroceryTopSellingProductCard] directly — but the two
/// modules only agree on the DATA, not on how to read it, and every difference
/// had to be bolted onto the grocery widget as a hook:
///
///  * pricing — grocery min/maxes every city in `pricing[]`; medical has one
///    row per city and only the one matching the shop's pincode is this shop's
///    price. That needed a `priceResolver` callback on the grocery card, plus a
///    helper that mapped grocery's `Pricing`/`PriceResult` to medical's
///    structurally-identical-but-distinct types and back again.
///  * the grocery card falls back to `Get.put(GroceryController())` when none
///    is registered, so opening a pharmacy screen span up a grocery controller.
///
/// The hooks are gone from both sides now: medical resolves its own price
/// through [MedicalController.getPriceDetails] directly (one mapping, not two),
/// and the grocery card is back to being grocery's.
///
/// The MODELS are still shared, deliberately — the endpoint really does return
/// that shape, and duplicating the parsing would only create a second thing to
/// keep in step with the backend.
class MedicalTopSellingProductCard extends StatelessWidget {
  final BusinessProductData product;
  final List<ProductVariants> variants;

  /// Cover height. Matches grocery's so the two merchant homes keep the same
  /// rhythm at the same rail height.
  final double imageHeight;

  const MedicalTopSellingProductCard({
    super.key,
    required this.product,
    required this.variants,
    this.imageHeight = 130,
  });

  /// The single price entry the card displays: the pharmacy's first inventory
  /// batch, falling back to the catalog price when the variant has no batches
  /// yet.
  ///
  /// ONE entry, not all of them — [MedicalController.getPriceDetails] renders a
  /// min–max range, so feeding it every variant produced unreadable cards
  /// ("₹99 - ₹512" struck through "₹120 - ₹2249"). A single entry makes
  /// min == max, so it formats as a plain price. Trade-off: the card tracks the
  /// FIRST variant only.
  List<medical.Pricing>? _displayPricing(ProductVariants? variant) {
    if (variant == null) return null;

    final batches = variant.inventory?.batches;
    if (batches != null && batches.isNotEmpty) {
      final batch = batches.first;
      return [medical.Pricing(mrp: batch.mrp, sellingPrice: batch.sellingPrice)];
    }

    final pricing = variant.pricing;
    if (pricing == null || pricing.isEmpty) return null;
    // Carry the whole list across: medical's resolver picks the row matching
    // the shop's pincode, so handing it only the first row would show another
    // city's price whenever the rows come back in a different order.
    return pricing
        .map((p) => medical.Pricing(
              pincode: p.pincode,
              cityName: p.cityName,
              mrp: p.mrp,
              sellingPrice: p.sellingPrice,
            ))
        .toList();
  }

  /// Whether the product reads as in stock — true when ANY variant is
  /// sellable. One available pack still means a customer can buy it, so only a
  /// wholly-flagged product reads as out.
  bool get _inStock =>
      variants.isEmpty ||
      variants.any((v) => v.inventory?.isOutOfStock != true);

  /// The pack label: `form · variantName`, e.g. "Spray · Standard Pack" or
  /// "450 g".
  ///
  /// This used to be `variant.quantity` alone, which is the WRONG field to
  /// read. It is the bare magnitude with the unit stripped off ("450", not
  /// "450 g"), and for anything not sold by weight or volume the API sends it
  /// empty — a spray's row carries `quantity: ""` with `variantName: "Standard
  /// Pack"`, so those cards rendered no pack line at all. `variantName` is the
  /// label the backend composes for display, and it is what the customer-facing
  /// [MedicalProductCard] shows.
  ///
  /// `quantity + unit` is kept as the fallback for a variant that somehow has
  /// no name, and bare `quantity` after that.
  String _packLabel(ProductVariants? variant) {
    final parts = <String>[];
    final form = product.product?.productForm ?? '';
    if (form.isNotEmpty) parts.add(form);

    final name = variant?.variantName ?? '';
    if (name.isNotEmpty) {
      parts.add(name);
    } else {
      final quantity = variant?.quantity ?? '';
      final unit = variant?.unit ?? '';
      if (quantity.isNotEmpty) {
        parts.add(unit.isNotEmpty ? '$quantity $unit' : quantity);
      }
    }
    return parts.join(' · ');
  }

  // The card deliberately ENDS at the price row: name → pack → price, nothing
  // after it and nothing conditional in between. Every other field the
  // response carries (brand, pack count, units in stock, category) was tried
  // here and taken back out — each one is present on some rows and absent on
  // others, so each one made the cards in the rail different heights. The
  // variants sheet behind a tap is where the rest of a product's detail lives.

  @override
  Widget build(BuildContext context) {
    final firstVariant =
        variants.isNotEmpty ? variants.first : product.productVariant;

    final controller = Get.isRegistered<MedicalController>()
        ? Get.find<MedicalController>()
        : Get.put(MedicalController());
    final price = controller.getPriceDetails(_displayPricing(firstVariant));

    // Variant image first, product image as fallback (missing OR broken).
    final variantImageUrl = (firstVariant?.images?.isNotEmpty ?? false)
        ? firstVariant!.images!.first.url
        : null;
    final productImageUrl = (product.product?.images?.isNotEmpty ?? false)
        ? product.product!.images!.first.url
        : null;
    final packLabel = _packLabel(firstVariant);
    // Prescription-only medicines carry the red Rx chip. Absent flag means
    // "not prescription-only", so nothing renders — which is also what happens
    // if the business-products response turns out not to send the field.
    final isRx = product.product?.isPrescriptionRequired == true;

    // Measures the name against this card's own width so the line it doesn't
    // use can be spent at the BOTTOM of the card instead of as a gap under the
    // title. `SizeConfig.size8 * 2` is the details block's horizontal padding.
    return CardNameSlack(
      text: product.product?.name ?? '',
      fontSize: SizeConfig.small,
      horizontalPadding: SizeConfig.size8 * 2,
      builder: (context, nameSlack) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: FallbackNetworkImage(
                    urls: [variantImageUrl, productImageUrl],
                  ),
                ),
                // Stock state on the photo, where the eye lands first when
                // scanning a rail.
                Positioned(
                  left: SizeConfig.size6,
                  bottom: SizeConfig.size6,
                  child: StockStatusPill(inStock: _inStock, onImage: true),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size8, SizeConfig.size6,
                SizeConfig.size8, SizeConfig.size10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Natural height — medicine names run long ("Simply Raw :
                // Chaat Masala (Pack of 900 Gram)") and wrap to two lines,
                // short ones take one. The card still matches its neighbours
                // because the unused line is added at the END of the card (see
                // the SizedBox after the price row).
                CustomText(
                  product.product?.name ?? '',
                  fontSize: SizeConfig.small,
                  maxLines: 2,
                  height: 1.3,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                // Rx marker + pack label. No veg/non-veg dot here — that is a
                // grocery concern the pharmacy card was carrying for no
                // reason; the leading slot it occupied belongs to Rx instead,
                // exactly as on the customer-facing [MedicalProductCard].
                if (isRx || packLabel.isNotEmpty)
                  Row(
                    children: [
                      if (isRx) ...[
                        const RxBadge(),
                        if (packLabel.isNotEmpty)
                          SizedBox(width: SizeConfig.size6),
                      ],
                      if (packLabel.isNotEmpty)
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  width: 0.5, color: AppColors.greyE5),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: CustomText(
                              packLabel,
                              fontSize: 11,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: '${price.sellingRange}',
                  mrp: '${price.mrpRange}',
                  discount: '${price.discountRange}',
                ),
                // The name line this card didn't need, spent here so every
                // card in the rail is the same height with the blank at the
                // bottom rather than under the title.
                if (nameSlack > 0) SizedBox(height: nameSlack),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
