import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared product-info section (below the image) used by both the horizontal
/// top-selling list on [VisitGroceryStoreScreen] and the grid on
/// [AllTopSellingGroceryProductsScreen].
///
/// Tapping the section opens a [SimpleDialog] with the full details.
class GroceryTopSellingInfoSection extends StatelessWidget {
  final BusinessProductData item;

  const GroceryTopSellingInfoSection({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailsDialog(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 9.0, vertical: SizeConfig.size6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              "${item.product?.name}",
              fontSize: SizeConfig.medium,
              maxLines: 2,
              color: AppColors.mainTextColor,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: SizeConfig.size6),
            Row(
              children: [
                if (item.productVariant?.isVegetarian != null) ...[
                  FoodTypeIndicator(
                      isVegetarian:
                          item.productVariant?.isVegetarian! ?? false),
                  SizedBox(width: SizeConfig.size6),
                ],
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            width: 0.5, color: AppColors.greyE5)),
                    padding: EdgeInsets.symmetric(
                        horizontal: 2, vertical: 0.5),
                    child: CustomText(
                      '${item.category?.name ?? ''}',
                      fontSize: 11,
                      color: Colors.grey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            // Discount lives on the image (top-left badge) now, so the
            // inline price row only shows selling price + MRP — no
            // duplicate "X% OFF" text here.
            PriceRow(
              sellingPrice: "${AppConstants.rupeeSymbol}${item.minSellingPrice}",
              mrp: "${AppConstants.rupeeSymbol}${item.minMrp}",
              discount: '',
            ),
            SizedBox(height: SizeConfig.size4),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        contentPadding: const EdgeInsets.all(16),
        children: [
          CustomText(
            "${item.product?.name}",
            fontSize: 14,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (item.productVariant?.isVegetarian != null) ...[
                FoodTypeIndicator(
                    isVegetarian:
                        item.productVariant?.isVegetarian! ?? false),
                SizedBox(width: SizeConfig.size6),
              ],
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(width: 0.5, color: AppColors.greyE5)),
                padding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: CustomText(
                  '${item.category?.name ?? ''}',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PriceRow(
            sellingPrice:
                "${AppConstants.rupeeSymbol}${item.minSellingPrice}",
            mrp: "${AppConstants.rupeeSymbol}${item.minMrp}",
            discount: "${item.avgDiscount}% OFF",
          ),
        ],
      ),
    );
  }
}

/// Shared product image widget with optional cart overlay.
class GroceryTopSellingImage extends StatelessWidget {
  final BusinessProductData item;

  /// The image widget (add/remove overlay built externally).
  final Widget? cartOverlay;

  const GroceryTopSellingImage({
    super.key,
    required this.item,
    this.cartOverlay,
  });

  /// Format the discount percent without trailing decimals when the value
  /// is effectively whole (e.g. 8.0 → "8"), otherwise keep 1 decimal place
  /// (e.g. 8.316 → "8.3"). Caps the upper bound at 99 so an outlier
  /// payload can't overflow the badge.
  String? _formattedDiscount() {
    final raw = item.avgDiscount;
    if (raw == null) return null;
    final value = raw.toDouble();
    if (value <= 0) return null;
    final clamped = value > 99 ? 99.0 : value;
    final isWhole = clamped == clamped.roundToDouble();
    return isWhole
        ? clamped.toStringAsFixed(0)
        : clamped.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    // Resolve via the shared fallback (variant images → product images)
    // so products that only carry variant-level images render here too —
    // previously this read product-level images only and showed the
    // placeholder for variant-only products (which the cart shows fine).
    final imageUrl = item.primaryImageUrl ?? '';
    final hasImage = imageUrl.isNotEmpty;
    final discountText = _formattedDiscount();

    final imageChild = ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.cover,
              ),
            )
          : LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
            ),
    );

    // Skip the Stack if there's nothing to overlay — keeps the simple case
    // cheap, falls into the layered build only when needed.
    if (cartOverlay == null && discountText == null) return imageChild;

    return Stack(
      children: [
        Positioned.fill(child: imageChild),
        if (discountText != null)
          Positioned(
            top: 0,
            left: 0,
            child: _DiscountBadge(text: discountText),
          ),
        if (cartOverlay != null)
          Positioned(
            top: 0,
            right: 0,
            child: cartOverlay!,
          ),
      ],
    );
  }
}

/// Mirrors the gradient discount pill from `store_product_card.dart` —
/// diagonal green sheen, thin inner stroke, on-brand drop shadow.
class _DiscountBadge extends StatelessWidget {
  final String text;
  const _DiscountBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 6, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1ED693), Color(0xFF008F5F)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D008E5E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.discountTagWhiteIcon,
            height: 12,
            width: 12,
          ),
          const SizedBox(width: 5),
          Text(
            '$text% ${AppStrings.off.tr.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
