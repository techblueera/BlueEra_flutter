import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<GroceryController>() ? Get.find<GroceryController>() : Get.put(GroceryController());
    final firstVariant = variants.isNotEmpty ? variants.first : product.productVariant;
    // Show the MERCHANT'S INVENTORY price (variant.inventory.batches — what the
    // store actually sells at), NOT the catalog variant price
    // (variant.pricing). Fall back to the variant pricing only when the variant
    // has no inventory batches yet.
    final invBatches = firstVariant?.inventory?.batches;
    final pricingSource = (invBatches != null && invBatches.isNotEmpty)
        ? invBatches
            .map((b) => Pricing(mrp: b.mrp, sellingPrice: b.sellingPrice))
            .toList()
        : firstVariant?.pricing;
    final price = controller.getPriceDetails(pricingSource);
    // Variant image first, product image as fallback (handles missing OR
    // broken variant images).
    final variantImageUrl =
        (firstVariant?.images?.isNotEmpty ?? false) ? firstVariant!.images!.first.url : null;
    final productImageUrl =
        (product.product?.images?.isNotEmpty ?? false) ? product.product!.images!.first.url : null;
    final quantity = firstVariant?.quantity ?? '';

    return Container(
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
              ],
            ),
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(SizeConfig.size8, SizeConfig.size6, SizeConfig.size8, SizeConfig.size10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${product.product?.name ?? ''}",
                  fontSize: SizeConfig.small,
                  maxLines: 1,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if (firstVariant?.isVegetarian != null) ...[
                      FoodTypeIndicator(isVegetarian: firstVariant?.isVegetarian ?? false),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: const EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration:
                            BoxDecoration(borderRadius: BorderRadius.circular(7), color: AppColors.green00),
                      ),
                    ),
                    if (quantity.isNotEmpty) ...[
                      SizedBox(width: SizeConfig.size6),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(width: 0.5, color: AppColors.greyE5)),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Network image that walks an ordered list of candidate [urls] — the first
/// non-empty one is tried, and on load-error it falls through to the next, then
/// to a local placeholder. Used so a missing/broken variant image falls back to
/// the product image (and, if that's broken too, any sibling variant image)
/// instead of just rendering a placeholder.
class GroceryFallbackImage extends StatelessWidget {
  final List<String?> urls;
  final BoxFit fit;

  const GroceryFallbackImage({
    super.key,
    required this.urls,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Keep non-empty, de-duped urls in order.
    final seen = <String>{};
    final candidates = <String>[];
    for (final u in urls) {
      final t = (u ?? '').trim();
      if (t.isNotEmpty && seen.add(t)) candidates.add(t);
    }
    return _build(candidates, 0);
  }

  Widget _build(List<String> candidates, int index) {
    if (index >= candidates.length) return _placeholder();
    return CachedNetworkImage(
      imageUrl: candidates[index],
      fit: fit,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) => _build(candidates, index + 1),
    );
  }

  // Placeholder fills the box (cover) regardless of [fit], so the fallback
  // image doesn't get letterboxed with left/right padding.
  Widget _placeholder() => LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.cover,
      );
}
