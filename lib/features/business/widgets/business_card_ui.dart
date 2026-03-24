import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class BusinessCardUi extends StatelessWidget {
  final String? cardIcon;
  final String? shareIcon;
  final double? height;
  final Color? borderColor;
  final VoidCallback? onTap;

  const BusinessCardUi({
    super.key,
    this.cardIcon,
    this.shareIcon,
    this.height,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: borderColor ?? AppColors.greyE5,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6.0),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 1),
              blurRadius: 2.0,
              color: AppColors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: cardIcon ?? AppIconAssets.businessCardIcon,
              height: height ?? 14,
              width: 22,
              boxFix: BoxFit.cover,
            ),
            const SizedBox(width: 4.0),
            LocalAssets(
              imagePath: shareIcon ?? AppIconAssets.reelShare,
              height: height ?? 14,
              width: 18,
              boxFix: BoxFit.cover,
              imgColor: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
