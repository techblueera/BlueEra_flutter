import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class PriceRow extends StatelessWidget {
  final String sellingPrice;
  final String mrp;
  final String? discount;

  /// Name both figures — "Selling: ₹99   MRP: ₹120".
  ///
  /// Opt-in, and only the merchant's own **pre-publish** screens turn it on:
  /// that row is the last thing read before a price goes live, and a bare
  /// number beside a struck-through one leaves which-is-which to inference.
  /// A shopper browsing a catalogue card reads the same pair by convention and
  /// doesn't need the labels, so those keep the compact form.
  final bool showLabels;

  const PriceRow({
    super.key,
    required this.sellingPrice,
    required this.mrp,
    this.discount,
    this.showLabels = false,
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
          if (showLabels)
            CustomText(
              'Selling: ',
              fontSize: 11,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),

          // --- Selling Price ---
          CustomText(
            sellingPrice,
            fontSize: 14,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.bold,
          ),

          const SizedBox(width: 4.0),

          // The label stays upright; only the figure is struck through, so
          // "MRP" reads as a heading rather than as a cancelled value.
          if (showLabels)
            CustomText(
              'MRP: ',
              fontSize: 11,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),

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