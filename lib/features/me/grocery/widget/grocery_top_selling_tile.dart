import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
            PriceRow(
              sellingPrice:
                  "${AppConstants.rupeeSymbol}${item.minSellingPrice}",
              mrp: "${AppConstants.rupeeSymbol}${item.minMrp}",
              discount: "${item.avgDiscount}% OFF",
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

  @override
  Widget build(BuildContext context) {
    final hasImage = item.product?.images?.isNotEmpty ?? false;
    final imageUrl =
        hasImage ? item.product?.images!.first.url ?? '' : '';

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

    if (cartOverlay == null) return imageChild;

    return Stack(
      children: [
        Positioned.fill(child: imageChild),
        Positioned(
          top: 0,
          right: 0,
          child: cartOverlay!,
        ),
      ],
    );
  }
}
