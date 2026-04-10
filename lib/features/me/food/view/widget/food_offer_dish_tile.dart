import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Shared product-info section (below the image) used by both the horizontal
/// offer-dish list on [VisitFoodStoreDetailsScreen] and the grid on
/// [AllOfferDishScreen].
///
/// Tapping the section opens a [SimpleDialog] with full details.
class FoodOfferDishInfoSection extends StatelessWidget {
  final CategoryFoodProductData item;

  const FoodOfferDishInfoSection({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasVariants =
        item.variants != null && item.variants!.isNotEmpty;
    final int variantCount = item.variants?.length ?? 0;
    final bool isMultiVariant = variantCount > 1;

    final sellingPrice =
        hasVariants ? item.variants![0].baseSellingPrice : null;
    final mrp = hasVariants ? item.variants![0].mrp : null;

    return GestureDetector(
      onTap: () => _showDetailsDialog(context),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              item.name ?? "",
              fontWeight: FontWeight.w600,
              maxLines: 2,
              fontSize: 13,
              color: AppColors.mainTextColor,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  RatingBadge(rating: '4.5'),
                  const SizedBox(width: 4),
                  Flexible(
                    child: CustomText(
                      '1.2 K Reviews',
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      color: AppColors.secondaryTextColor,
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                CustomText(
                  "${AppConstants.rupeeSymbol}${sellingPrice ?? 0}",
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                if (mrp != null &&
                    sellingPrice != null &&
                    mrp > sellingPrice) ...[
                  const SizedBox(width: 6),
                  CustomText(
                    "${AppConstants.rupeeSymbol}$mrp",
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.secondaryTextColor,
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CustomText(
                  isMultiVariant
                      ? "+${variantCount - 1} more variant"
                      : '$variantCount variant',
                  fontSize: 10,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    final bool hasVariants =
        item.variants != null && item.variants!.isNotEmpty;
    final int variantCount = item.variants?.length ?? 0;
    final bool isMultiVariant = variantCount > 1;

    final sellingPrice =
        hasVariants ? item.variants![0].baseSellingPrice : null;
    final mrp = hasVariants ? item.variants![0].mrp : null;

    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        contentPadding: const EdgeInsets.all(16),
        children: [
          CustomText(
            item.name ?? "",
            fontSize: 14,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FoodTypeIndicator(
                isVegetarian: item.dietaryType?.toLowerCase() == "veg",
                size: 8,
              ),
              if (item.category?.name != null) ...[
                SizedBox(width: SizeConfig.size6),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          width: 0.5, color: AppColors.greyE5),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    child: CustomText(
                      '${item.category?.name}',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CustomText(
                "${AppConstants.rupeeSymbol}${sellingPrice ?? 0}",
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              if (mrp != null &&
                  sellingPrice != null &&
                  mrp > sellingPrice) ...[
                const SizedBox(width: 6),
                CustomText(
                  "${AppConstants.rupeeSymbol}$mrp",
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.secondaryTextColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: CustomText(
              isMultiVariant
                  ? "+${variantCount - 1} more variant"
                  : '$variantCount variant',
              fontSize: 10,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
