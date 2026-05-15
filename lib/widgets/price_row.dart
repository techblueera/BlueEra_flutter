import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class PriceRow extends StatelessWidget {
  final String sellingPrice;
  final String mrp;
  final String? discount;

  const PriceRow({
    super.key,
    required this.sellingPrice,
    required this.mrp,
    this.discount,
  });

  @override
  Widget build(BuildContext context) {
    final showDiscount = (discount ?? '').isNotEmpty;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft, // Ensures it stays left-aligned when scaling
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // --- Selling Price ---
          CustomText(
            sellingPrice,
            fontSize: 14,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.bold,
          ),

          const SizedBox(width: 4.0),

          // --- MRP (Strikethrough) ---
          CustomText(
            mrp,
            fontSize: 11,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.secondaryTextColor,
          ),

          if (showDiscount) ...[
            const SizedBox(width: 8.0),
            // --- Discount Badge ---
            DiscountBadge(discountText: discount!),
          ],
        ],
      ),
    );
  }
}