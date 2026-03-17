import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class DiscountBadge extends StatelessWidget {
  final String discountText;

  const DiscountBadge({
    super.key,
    required this.discountText,
  });

  @override
  Widget build(BuildContext context) {
    // If the string is empty or null, don't show the badge at all
    if (discountText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: AppColors.greenShade.withValues(alpha: 0.1),
        border: Border.all(
          color: AppColors.greenShade.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Prevents badge from taking full width
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.discountTagIcon,
            height: 12,
            width: 12,
          ),
          const SizedBox(width: 4),
          CustomText(
            discountText,
            fontSize: 10,
            color: AppColors.green00,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}