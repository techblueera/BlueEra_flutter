import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class FoodTagWidget extends StatelessWidget {
  final String label;
  final String? iconPath;
  final Color? borderColor;
  final Color? textColor;

  const FoodTagWidget({
    super.key,
    required this.label,
    this.iconPath,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty || label.toLowerCase() == "n/a") {
      return const SizedBox.shrink();
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor ?? AppColors.whiteE5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: iconPath ?? AppIconAssets.boiled,
            ),
            const SizedBox(width: 5),
            CustomText(
              label,
              color: textColor ?? AppColors.secondaryTextColor,
              fontSize: 10,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}