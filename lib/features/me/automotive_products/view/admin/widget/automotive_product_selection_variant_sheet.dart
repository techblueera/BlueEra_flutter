import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_controller.dart';
import 'package:BlueEra/features/me/automotive_products/model/automotive_product_catalog_response.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Variant picker for the admin automotive-product-selection flow. Mirrors
/// the food flow's `ProductVariantBottomSheet`: every tick / untick commits
/// straight into the controller's `selectedProducts` (one
/// [AutomotiveSelectedVariant] per ticked variant) — no separate "save"
/// step — so the floating cart on the parent screen reflects it live.
class AutomotiveProductSelectionVariantSheet extends StatelessWidget {
  final AutomotiveProduct product;
  final AutomotiveProductController controller;

  const AutomotiveProductSelectionVariantSheet({
    super.key,
    required this.product,
    required this.controller,
  });

  /// Opens the picker as a scroll-controlled bottom sheet.
  static Future<void> show({
    required AutomotiveProduct product,
    required AutomotiveProductController controller,
  }) {
    return Get.bottomSheet(
      AutomotiveProductSelectionVariantSheet(
          product: product, controller: controller),
      isScrollControlled: true,
    );
  }

  /// Human-readable variant label from its attributes (e.g. "Black · M"),
  /// falling back to the free-form quantity, then "Default".
  String _variantLabel(AutomotiveVariant v) {
    final parts = <String>[];
    v.attributes.forEach((key, value) {
      final s = (value ?? '').toString();
      if (s.isNotEmpty) parts.add(s);
    });
    if (parts.isEmpty && v.quantity.trim().isNotEmpty) {
      parts.add(v.quantity.trim());
    }
    return parts.isEmpty ? AppStrings.automotiveDefaultLabel.tr : parts.join(' · ');
  }

  void _toggle(AutomotiveVariant variant) {
    controller.toggleProductSelection(
      AutomotiveSelectedVariant(product: product, variant: variant),
    );
  }

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
          final count = controller.selectedVariantCountForProduct(product.id);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(count),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: product.variants.map(_variantRow).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _header(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: CustomText(
                  product.name,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(
                    AppStrings.automotiveCountInCart
                        .trParams({'count': '$count'}),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  Widget _variantRow(AutomotiveVariant variant) {
    final isSelected = controller.isProductSelected(variant.id);
    final discount = variant.mrp > 0
        ? ((variant.mrp - variant.sellingPrice) / variant.mrp * 100).round()
        : 0;
    return InkWell(
      onTap: () => _toggle(variant),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              side: BorderSide(
                color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
                width: 1.5,
              ),
              activeColor: AppColors.primaryColor,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) => _toggle(variant),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    _variantLabel(variant),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CustomText(
                        '₹${variant.sellingPrice.toStringAsFixed(0)}',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 8),
                        CustomText(
                          '₹${variant.mrp.toStringAsFixed(0)}',
                          fontSize: 13,
                          color: AppColors.secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                        const SizedBox(width: 8),
                        CustomText(
                          // `off` reads as "switched off" in hi/kn — the
                          // discount word is `offCaps`.
                          '$discount% ${AppStrings.offCaps.tr}',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green7F,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
