import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/fallback_network_image.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/card_name_slack.dart';
import 'package:BlueEra/widgets/stock_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared grocery product card used by BOTH the admin home top-selling rail
/// (`grocery_home_screen_v2.dart`) and the "all top-selling" grid
/// (`all_top_selling_grocery_products_screen.dart`) so the two surfaces look
/// identical. Styled to match `grocery_products_selection_screen.dart`'s
/// `groceryCard`: cover image, name, veg + quantity row, price range.
///
/// [imageOverlay] is shown top-right over the image (customer add-to-cart
/// stepper); omit it for the owner/admin view. The whole card is meant to be
/// wrapped in a tap handler by the caller (→ variants sheet).
/// The single price entry the card displays: the variant's first inventory
/// batch, falling back to its first catalog price. Returns null when the
/// variant has neither, which [GroceryController.getPriceDetails] renders as
/// zeroes.
List<Pricing>? _firstPrice(ProductVariants? variant) {
  if (variant == null) return null;
  final batches = variant.inventory?.batches;
  if (batches != null && batches.isNotEmpty) {
    final batch = batches.first;
    return [Pricing(mrp: batch.mrp, sellingPrice: batch.sellingPrice)];
  }
  final pricing = variant.pricing;
  if (pricing != null && pricing.isNotEmpty) return [pricing.first];
  return null;
}

class GroceryTopSellingProductCard extends StatelessWidget {
  final BusinessProductData product;
  final List<ProductVariants> variants;
  final Widget? imageOverlay;
  final double imageHeight;
  final VoidCallback? onShare;

  const GroceryTopSellingProductCard({
    super.key,
    required this.product,
    required this.variants,
    this.imageOverlay,
    this.imageHeight = 130,
    this.onShare,
  });

  /// Whether the product reads as in stock — true when ANY variant is
  /// sellable. One available pack still means a customer can buy it, so only a
  /// wholly-flagged product reads as out.
  ///
  /// Reads `variants[].inventory.isOutOfStock`, the only place the flag lives —
  /// the row's own top level carries no such field, and its representative
  /// `productVariant` has no `inventory` object at all.
  bool get _inStock =>
      variants.isEmpty ||
      variants.any((v) => v.inventory?.isOutOfStock != true);

  @override
  Widget build(BuildContext context) {
    final firstVariant =
        variants.isNotEmpty ? variants.first : product.productVariant;
    // Show the MERCHANT'S INVENTORY price (variant.inventory.batches — what the
    // store actually sells at), NOT the catalog variant price
    // (variant.pricing). Fall back to the catalog pricing only when the variant
    // has no inventory batches yet.
    //
    // ONE entry — the first variant's first price. getPriceDetails renders a
    // min–max range, so feeding it every variant produced unreadable cards
    // ("₹199.0 - ₹512.0" struck through "₹999.0 - ₹2249.0", with a meaningless
    // blended discount). A single entry makes min == max, so it formats as a
    // plain price. Trade-off: the card tracks the FIRST variant only, so an
    // edit to any other variant won't move it.
    final pricingSource = _firstPrice(firstVariant);
    final price = (Get.isRegistered<GroceryController>()
            ? Get.find<GroceryController>()
            : Get.put(GroceryController()))
        .getPriceDetails(pricingSource);
    // Variant image first, product image as fallback (handles missing OR
    // broken variant images).
    final variantImageUrl = (firstVariant?.images?.isNotEmpty ?? false)
        ? firstVariant!.images!.first.url
        : null;
    final productImageUrl = (product.product?.images?.isNotEmpty ?? false)
        ? product.product!.images!.first.url
        : null;
    final quantity = firstVariant?.quantity ?? '';

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
                  child: GroceryFallbackImage(
                    urls: [variantImageUrl, productImageUrl],
                  ),
                ),
                if (onShare != null)
                  Positioned(
                    top: SizeConfig.size6,
                    left: SizeConfig.size6,
                    child: GestureDetector(
                      onTap: onShare,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 4),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: LocalAssets(
                          imagePath: AppIconAssets.share_bold,
                          imgColor: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                if (imageOverlay != null)
                  Positioned(
                    top: SizeConfig.size6,
                    right: SizeConfig.size6,
                    child: imageOverlay!,
                  ),
                // Stock state on the photo, where the eye lands first when
                // scanning a rail. Bottom-LEFT: the top corners already carry
                // share / cart controls.
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
                // Natural height — one line or two. The card still matches its
                // neighbours because the unused line is added at the END of the
                // card (see the SizedBox after the price row).
                CustomText(
                  "${product.product?.name ?? ''}",
                  fontSize: SizeConfig.small,
                  maxLines: 2,
                  height: 1.3,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if (firstVariant?.isVegetarian != null) ...[
                      FoodTypeIndicator(
                          isVegetarian: firstVariant?.isVegetarian ?? false),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: const EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00),
                      ),
                    ),
                    if (quantity.isNotEmpty) ...[
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                width: 0.5, color: AppColors.greyE5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: CustomText(
                          quantity,
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: "${price.sellingRange}",
                  mrp: "${price.mrpRange}",
                  discount: "${price.discountRange}",
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

/// Grocery's name for [FallbackNetworkImage].
///
/// The implementation moved to `widgets/fallback_network_image.dart` when
/// medical grew its own card — a pharmacy screen importing a `Grocery*` widget
/// to draw a picture was the kind of cross-module borrowing this split is
/// undoing. Kept as an alias so grocery's existing call sites need no edit.
class GroceryFallbackImage extends FallbackNetworkImage {
  const GroceryFallbackImage({
    super.key,
    required super.urls,
    super.fit,
  });
}
