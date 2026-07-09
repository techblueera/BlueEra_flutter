import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Circular add affordance overlaid on the top-right of a product/grocery/food
/// selection card's image (replaces the old full-width "Add" button).
///
/// Default state: white fill, primary border, primary `+`. Once selected it
/// flips to a filled brand circle — showing the selected-variant [count] when
/// provided (multi-variant products) or a check for a plain toggle.
class ProductSelectPlusButton extends StatelessWidget {
  const ProductSelectPlusButton({
    super.key,
    required this.added,
    required this.onTap,
    this.count,
  });

  final bool added;
  final VoidCallback onTap;

  /// When non-null, the selected state shows this number; otherwise a check.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: added ? AppColors.primaryColor : AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: added
            ? (count != null
                ? CustomText(
                    '$count',
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  )
                : const Icon(Icons.check, color: AppColors.white, size: 18))
            : Icon(Icons.add, color: AppColors.primaryColor, size: 20),
      ),
    );
  }
}
