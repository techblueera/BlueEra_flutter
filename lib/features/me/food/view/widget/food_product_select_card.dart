import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/product_select_plus_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodProductSelectCard extends StatelessWidget {
  final CategoryFoodProductData product;
  final FoodServiceController controller;
  final void Function(CategoryFoodProductData) onShowVariants;
  final double? width;

  const FoodProductSelectCard({
    super.key,
    required this.product,
    required this.controller,
    required this.onShowVariants,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = product.images?.firstOrNull ?? '';
    final firstVariant =
        (product.variants?.isNotEmpty ?? false) ? product.variants!.first : null;
    final num selling = product.displayPrice ?? firstVariant?.baseSellingPrice ?? 0;
    final num mrp = (product.displayMrp ?? firstVariant?.mrp ?? 0).toDouble();
    final int discount = (mrp > 0 && selling > 0 && selling < mrp)
        ? ((mrp - selling) / mrp * 100).round()
        : 0;
    final bool isVeg = (product.dietaryType ?? '').toLowerCase() == 'veg';

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: SizedBox(
                  height: SizeConfig.size140,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
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
                ),
              ),
              // Top-right add button overlaid on the image (replaces the old
              // full-width "Add" button). A filled brand circle with a white
              // ring; once variants are selected it shows the count.
              Positioned(
                top: SizeConfig.size8,
                right: SizeConfig.size8,
                child: Obx(() {
                  final count =
                      (controller.selectedVariantsMap[product.id] ?? []).length;
                  // Every variant of this dish is already on the merchant's own
                  // menu, so the plus would open a sheet with nothing tickable.
                  // Say so on the card instead — the merchant can see it without
                  // opening anything.
                  if (controller.isProductFullyStocked(product)) {
                    return const _InMenuBadge();
                  }
                  return ProductSelectPlusButton(
                    added: count > 0,
                    count: count,
                    onTap: () => onShowVariants(product),
                  );
                }),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 8.0, vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Natural height (up to 2 lines): a single-line name lets the
                // content below sit right under it instead of leaving a gap.
                CustomText(
                  "${product.name}",
                  fontSize: SizeConfig.small,
                  height: 1.3,
                  maxLines: 2,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if ((product.dietaryType ?? '').isNotEmpty) ...[
                      FoodTypeIndicator(isVegetarian: isVeg),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(width: 0.5, color: AppColors.greyE5),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: CustomText(
                          '${product.variants?.length ?? 0} variants',
                          fontSize: 11,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: '₹${selling.toStringAsFixed(0)}',
                  mrp: '₹${mrp.toStringAsFixed(0)}',
                  discount: '$discount% off',
                ),
                // "2 of 5 already added" — the PARTIAL case, which the corner
                // badge cannot show: that only appears once every variant is
                // stocked. Without this the merchant opens the sheet, finds two
                // rows greyed out and no explanation on the card that sent them
                // there.
                Obx(() {
                  final total = product.variants?.length ?? 0;
                  final stocked = controller.stockedVariantCount(product);
                  if (stocked == 0 || stocked >= total) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 12, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: CustomText(
                            '$stocked of $total already added',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size4),
        ],
      ),
    );
  }
}

/// "Already added" — the corner badge on a dish whose every variant the
/// merchant already stocks.
///
/// Occupies the same corner the add button would, at the same size, so a rail
/// of cards keeps one alignment whichever state each card is in.
class _InMenuBadge extends StatelessWidget {
  const _InMenuBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          CustomText(
            'Already added',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
