import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> showFoodProductVariantSheet(
  BuildContext context, {
  required CategoryFoodProductData product,
}) {
  return Get.bottomSheet(
    FoodProductVariantSheet(product: product),
    isScrollControlled: true,
  );
}

class FoodProductVariantSheet extends StatelessWidget {
  final CategoryFoodProductData product;

  const FoodProductVariantSheet({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            _ProductInfo(product: product),
            const Divider(),
            _VariantList(product: product),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          'All Variant',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final CategoryFoodProductData product;

  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductImageWidget(
          imageUrl: product.images?.firstOrNull,
          width: 60,
          height: 60,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                product.name,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ProductDescriptionWidget(description: product.description),
              const SizedBox(height: 8),
              FoodDietaryAndTagRow(
                dietaryType: product.dietaryType,
                cookingMethods: product.cookingMethod,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VariantList extends StatelessWidget {
  final CategoryFoodProductData product;

  const _VariantList({required this.product});

  @override
  Widget build(BuildContext context) {
    final variants = product.variants ?? const [];

    if (variants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: CustomText(
          'No variants available',
          color: AppColors.secondaryTextColor,
        ),
      );
    }

    return Column(
      children: variants.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppColors.greyE5.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Blue vertical accent line
                  Container(
                    width: 4,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  // Variant content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            '${item.variantName ?? ''}'
                            '${(item.quantityLabel ?? '').isNotEmpty ? ' - ${item.quantityLabel}' : ''}',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Selling price chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: CustomText(
                                  '₹${item.baseSellingPrice ?? 0}',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // MRP strikethrough
                              if ((item.mrp ?? 0) >
                                  (item.baseSellingPrice ?? 0))
                                CustomText(
                                  '₹${item.mrp ?? 0}',
                                  fontSize: 12,
                                  color: AppColors.secondaryTextColor
                                      .withValues(alpha: 0.7),
                                  decoration: TextDecoration.lineThrough,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
