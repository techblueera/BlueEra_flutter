import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
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
                SizedBox(height: SizeConfig.size8),
                // Own Obx so the button reflects selection changes even when the
                // host list doesn't observe selectedVariantsMap.
                Obx(() {
                  final count =
                      (controller.selectedVariantsMap[product.id] ?? []).length;
                  final bool added = count > 0;
                  return CustomBtn(
                    height: SizeConfig.size36,
                    onTap: () => onShowVariants(product),
                    title: added ? '$count Added' : 'Add',
                    textColor:
                        added ? AppColors.white : AppColors.primaryColor,
                    bgColor: added ? AppColors.primaryColor : AppColors.white,
                    radius: 6.0,
                    borderColor: AppColors.primaryColor,
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
