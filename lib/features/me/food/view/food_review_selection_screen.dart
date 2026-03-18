import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/custom_btn.dart';

class FoodReviewSelectionScreen extends GetView<FoodCustomerController> {
  const FoodReviewSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Review Selection",
        buildCustomActionWidget: () => IconButton(
          onPressed: () => _showClearAllDialog(),
          icon: const Icon(Icons.delete_sweep, color: AppColors.red),
        ),
      ),
      body: Obx(() {
        if (controller.selectedVariantsMap.isEmpty) {
          return const Center(
            child: EmptyStateWidget(message: "No items in your selection"),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                itemCount: controller.selectedVariantsMap.length,
                itemBuilder: (context, index) {
                  // NEW LOGIC: Pull directly from map values (SelectedFoodItem wrapper)
                  final selection = controller.selectedVariantsMap.values.elementAt(index);

                  return _buildProductGroupCard(
                      selection.product,
                      selection.selectedVariants
                  );
                },
              ),
            ),
            _buildBottomActionPanel(),
          ],
        );
      }),
    );
  }

  Widget _buildProductGroupCard(CategoryFoodProductData product, List<FoodVariants> variants) {
    return CustomFormCard(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0, bottom: 0.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Product Info Header
          Row(
            children: [
              ProductImageWidget(
                imageUrl: product.images?.firstOrNull,
                height: 50,
                width: 50,
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
              )
            ],
          ),
          const Divider(height: 16),

          // Selected Variants List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: variants.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildVariantRow(variants[index]);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildVariantRow(FoodVariants variant) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppShadows.textFieldShadow],
        border: Border.all(color: AppColors.greyE5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color Accent
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      variant.variantName ?? "Standard",
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomText(
                      variant.quantityLabel ?? "",
                      fontSize: 12,
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText(
                            "₹${variant.baseSellingPrice}",
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        CustomText(
                          "₹${variant.mrp}",
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(color: AppColors.greyE5, width: 1, indent: 10, endIndent: 10),
            // Delete Action
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _removeVariant(variant),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: PositiveCustomBtn(
          onTap: () {
            // Proceed to final checkout logic
          },
          title: "Checkout (${controller.totalVariantsCount})",
        ),
      ),
    );
  }

  void _removeVariant(FoodVariants variant) {
    String? pId = variant.product;
    if (pId != null && controller.selectedVariantsMap.containsKey(pId)) {
      // Logic adjusted for Wrapper class
      controller.selectedVariantsMap[pId]!.selectedVariants.removeWhere((v) => v.id == variant.id);

      if (controller.selectedVariantsMap[pId]!.selectedVariants.isEmpty) {
        controller.selectedVariantsMap.remove(pId);
      }
      controller.selectedVariantsMap.refresh();
    }
  }

  void _showClearAllDialog() {
    Get.dialog(
      AlertDialog(
        title: const CustomText("Clear Selection?", fontWeight: FontWeight.bold),
        content: const CustomText("Do you want to remove all selected items?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const CustomText("No")),
          TextButton(
            onPressed: () {
              controller.selectedVariantsMap.clear();
              Get.back();
            },
            child: const CustomText("Yes, Clear", color: Colors.red),
          ),
        ],
      ),
    );
  }
}