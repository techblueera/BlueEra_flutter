import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/custom_add_button_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodProductCard extends StatelessWidget {
  final CategoryFoodProductData product;
  final Function(CategoryFoodProductData) onShowVariants;

  const FoodProductCard({
    super.key,
    required this.product,
    required this.onShowVariants,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ProductImageWidget(
                  imageUrl: product.images?.firstOrNull,
                ),
                const SizedBox(width: 12),

                // Product Details
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
                      ProductDescriptionWidget(
                        description: product.description,
                      ),
                      const SizedBox(height: 8),
                      FoodDietaryAndTagRow(
                        dietaryType: product.dietaryType,
                        cookingMethods: product.cookingMethod,
                      ),
                    ],
                  ),
                )
              ],
            ),

            // Variants and Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => onShowVariants(product),
                  child: CustomText(
                    "${product.variants?.length ?? 0} Variants",
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() {
                  final controller = Get.find<FoodServiceController>();
                  final bool currentlyAdded = (controller.selectedVariantsMap[product.id] ?? []).isNotEmpty;

                  return CustomAddButton(
                    isAdded: currentlyAdded,
                    onTap: () => onShowVariants(product),
                  );
                })
              ],
            )
          ],
        ),
      ),
    );
  }

}