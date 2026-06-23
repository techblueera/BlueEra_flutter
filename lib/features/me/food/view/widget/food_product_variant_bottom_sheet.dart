import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/add_or_update_variant_bottom_sheet.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Variant selection sheet.
///
/// Behavior: every tick / untick is committed straight into
/// `controller.selectedVariantsMap` — there is no "Save Selection"
/// step. This way the floating cart counter on the parent screen
/// reflects the selection live, and the review-and-publish flow lives
/// entirely on the dedicated [FoodCartScreen]. Price editing also moves
/// to the cart screen so this sheet is purely a picker.
class ProductVariantBottomSheet extends StatelessWidget {
  final CategoryFoodProductData product;
  final FoodServiceController controller;
  final bool isSnapSearch;

  const ProductVariantBottomSheet({
    super.key,
    required this.product,
    required this.controller,
    required this.isSnapSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Obx(() {
          final String pId = product.id ?? "";
          final liveProduct = controller.categoryFoundProductDataList
                  .firstWhereOrNull((p) => p.id == pId) ??
              product;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(pId),
              _buildProductInfo(liveProduct),
              const Divider(),
              _buildVariantList(liveProduct, pId),
              _buildAddVariantButton(liveProduct),
              const SizedBox(height: 16),
              _buildDoneButton(pId),
              const SizedBox(height: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(String pId) {
    final selectedCount =
        (controller.selectedVariantsMap[pId] ?? []).length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CustomText(
              AppStrings.foodAllVariantLabel.tr,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            if (selectedCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomText(
                  '$selectedCount in cart',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  Widget _buildProductInfo(CategoryFoodProductData liveProduct) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductImageWidget(
          imageUrl: liveProduct.images?.firstOrNull,
          height: 60,
          width: 60,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                liveProduct.name,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ProductDescriptionWidget(
                description: liveProduct.description,
              ),
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

  Widget _buildVariantList(CategoryFoodProductData liveProduct, String pId) {
    final displayVariants = liveProduct.variants ?? [];
    final selected = controller.selectedVariantsMap[pId] ?? const [];

    return Column(
      children: displayVariants.map((item) {
        final isSelected = selected.any((v) => v.id == item.id);
        return InkWell(
          onTap: () => _toggleVariantInCart(pId, item),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? AppColors.primaryColor : AppColors.greyE5,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.greyE5,
                    width: 1.5,
                  ),
                  activeColor: AppColors.primaryColor,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => _toggleVariantInCart(pId, item),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "${item.variantName} - ${item.quantityLabel}",
                        fontSize: 16,
                        color: AppColors.secondaryTextColor,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: CustomText(
                              "Selling-₹${item.baseSellingPrice}",
                              fontSize: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPriceDivider(),
                          const SizedBox(width: 8),
                          CustomText(
                            "₹${item.mrp}",
                            fontSize: 14,
                            color: AppColors.secondaryTextColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddVariantButton(CategoryFoodProductData liveProduct) {
    return InkWell(
      onTap: () {
        // Keep this variant sheet mounted underneath: it's an Obx bound to the
        // Source-of-Truth list, so when the add sheet closes it reveals this
        // list already showing the newly added variant (no reopen needed).
        controller.clearAllField();
        addOrVariantBottomSheet(
          foodID: liveProduct.id ?? "",
          onAdd: (foodVariants) {},
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.add, color: AppColors.primaryColor),
          CustomText("Add More Variant", color: AppColors.primaryColor),
        ],
      ),
    );
  }

  Widget _buildDoneButton(String pId) {
    final selectedCount =
        (controller.selectedVariantsMap[pId] ?? []).length;
    return PositiveCustomBtn(
      onTap: () => Get.back(),
      title: selectedCount > 0
          ? 'Done  •  $selectedCount in cart'
          : 'Done',
    );
  }

  void _toggleVariantInCart(String productId, FoodVariants variant) {
    final current = List<FoodVariants>.from(
      controller.selectedVariantsMap[productId] ?? <FoodVariants>[],
    );
    final idx = current.indexWhere((v) => v.id == variant.id);
    if (idx != -1) {
      current.removeAt(idx);
    } else {
      current.add(variant);
    }
    if (current.isEmpty) {
      controller.selectedVariantsMap.remove(productId);
    } else {
      controller.selectedVariantsMap[productId] = current;
    }
    controller.selectedVariantsMap.refresh();
  }

  Widget _buildPriceDivider() {
    return Container(height: 15, width: 1.5, color: Colors.grey.shade300);
  }
}
