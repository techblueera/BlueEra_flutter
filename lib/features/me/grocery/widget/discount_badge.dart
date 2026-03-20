import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class DiscountBadge extends StatelessWidget {
  final String discountText;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;

  const DiscountBadge({
    super.key,
    required this.discountText,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (discountText.isEmpty) return const SizedBox.shrink();

    // Default Fallbacks
    final finalBgColor = backgroundColor ?? AppColors.greenShade.withValues(alpha: 0.1);
    final finalBorderColor = borderColor ?? AppColors.greenShade.withValues(alpha: 0.2);
    final finalTextColor = textColor ?? AppColors.green00;
    final finalIconColor = iconColor ?? AppColors.green00;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: finalBgColor,
        border: Border.all(
          color: finalBorderColor,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.discountTagIcon,
            height: 12,
            width: 12,
            imgColor: finalIconColor,
          ),
          const SizedBox(width: 4),
          CustomText(
            discountText,
            fontSize: 10,
            color: finalTextColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}