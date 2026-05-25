import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/customer/food_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Context for opening the food self-pickup variants bottom sheet.
class FoodSelfPickupSheetArgs {
  final String? productId;
  final String? name;
  final String? description;
  final String? imageUrl;
  final List<FoodVariants> variants;

  /// Needed so cart entries can be tagged with the business that owns them
  /// — mirrors the grocery cart shape.
  final String? visitBusinessId;
  final String? visitBusinessName;
  final String? visitBusinessLogo;
  final String? visitBusinessAddress;

  const FoodSelfPickupSheetArgs({
    required this.productId,
    required this.variants,
    this.name,
    this.description,
    this.imageUrl,
    this.visitBusinessId,
    this.visitBusinessName,
    this.visitBusinessLogo,
    this.visitBusinessAddress,
  });

  factory FoodSelfPickupSheetArgs.fromCategoryProduct(
    CategoryFoodProductData product, {
    String? visitBusinessId,
    String? visitBusinessName,
    String? visitBusinessLogo,
    String? visitBusinessAddress,
  }) {
    return FoodSelfPickupSheetArgs(
      productId: product.id,
      name: product.name,
      description: product.description,
      imageUrl: product.images?.firstOrNull,
      variants: product.variants ?? const [],
      visitBusinessId: visitBusinessId,
      visitBusinessName: visitBusinessName,
      visitBusinessLogo: visitBusinessLogo,
      visitBusinessAddress: visitBusinessAddress,
    );
  }
}

/// Opens a bottom sheet listing all variants of [args.productId]. Each row
/// has an ADD/REMOVE affordance wired straight to [FoodSelfPickupController]
/// — the same pattern grocery uses in its variants sheet.
Future<void> showFoodSelfPickupVariantsSheet(
  BuildContext context, {
  required FoodSelfPickupSheetArgs args,
}) {
  final controller = Get.find<FoodSelfPickupController>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FoodSelfPickupVariantsSheet(
      args: args,
      controller: controller,
    ),
  );
}

class _FoodSelfPickupVariantsSheet extends StatelessWidget {
  final FoodSelfPickupSheetArgs args;
  final FoodSelfPickupController controller;

  const _FoodSelfPickupVariantsSheet({
    required this.args,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  args.name ?? AppStrings.foodAllVariantsLabel.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageWidget(
                  imageUrl: args.imageUrl,
                  height: 60,
                  width: 60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        args.name ?? '',
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ProductDescriptionWidget(description: args.description),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: args.variants
                      .map((v) => _variantRow(context, v))
                      .toList(),
                ),
              ),
            ),
            _inSheetCartStrip(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Sticky strip at the bottom of the sheet that confirms items are
  /// landing in the cart (the screen's floating cart is hidden behind the
  /// sheet, so we surface the same info inline). Tapping "View Cart"
  /// closes the sheet and pushes the self-pickup cart screen.
  Widget _inSheetCartStrip(BuildContext context) {
    return Obx(() {
      final cart = controller.selectedFoodVariants;
      final count = cart.length;
      if (count == 0) return const SizedBox.shrink();

      final subtotal = cart.fold<int>(
        0,
        (sum, v) => sum + (v.baseSellingPrice ?? 0),
      );

      return AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const FoodSelfPickUpCartScreen());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          '$count ${count == 1 ? "item" : "items"} in cart',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          'Subtotal ${AppConstants.rupeeSymbol}$subtotal',
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          'View Cart',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _variantRow(BuildContext context, FoodVariants variant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  '${variant.variantName ?? ''} '
                  '${variant.quantityLabel != null ? '- ${variant.quantityLabel}' : ''}',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                const SizedBox(height: 4),
                PriceRow(
                    sellingPrice: '${AppConstants.rupeeSymbol}${variant.baseSellingPrice ?? 0}',
                    mrp: '${AppConstants.rupeeSymbol}${variant.mrp}',
                    discount: calculateDiscount(
                        (variant.baseSellingPrice ?? 0).toString(),
                        (variant.mrp ?? 0).toString()
                    ).toStringAsFixed(2),
                )
                // Row(
                //   children: [
                //     CustomText(
                //       '${AppConstants.rupeeSymbol}${variant.baseSellingPrice ?? 0}',
                //       fontWeight: FontWeight.w700,
                //       fontSize: 14,
                //     ),
                //     const SizedBox(width: 6),
                //     if ((variant.mrp ?? 0) > (variant.baseSellingPrice ?? 0))
                //       CustomText(
                //         '${AppConstants.rupeeSymbol}${variant.mrp}',
                //         fontSize: 12,
                //         fontWeight: FontWeight.w400,
                //         color: AppColors.secondaryTextColor,
                //         decoration: TextDecoration.lineThrough,
                //         decorationColor: AppColors.secondaryTextColor,
                //       ),
                //   ],
                // ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            // `.length` is a tracked accessor — explicit read guarantees
            // this Obx is subscribed to mutations.
            final cart = controller.selectedFoodVariants;
            final _ = cart.length;
            final added = variant.id != null &&
                cart.any((v) => v.id == variant.id);
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (added) {
                  controller.removeFromCart(variant);
                } else {
                  controller.addToCart(
                    variant,
                    productId: args.productId,
                    businessId: args.visitBusinessId,
                    businessName: args.visitBusinessName,
                    businessLogo: args.visitBusinessLogo,
                    businessAddress: args.visitBusinessAddress,
                    productImage: args.imageUrl,
                  );
                }
              },
              child: Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  color: added
                      ? AppColors.red.withValues(alpha: 0.08)
                      : AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: added ? AppColors.red : AppColors.primaryColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      added ? Icons.remove : Icons.add,
                      size: 14,
                      color: added ? AppColors.red : AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    CustomText(
                      added ? 'REMOVE' : 'ADD',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: added ? AppColors.red : AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
