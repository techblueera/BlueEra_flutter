import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class FoodTypeOrCookingMethod extends StatelessWidget {
  final String label;
  final String? icon;

  const FoodTypeOrCookingMethod({
    super.key,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon!=null) ...[
            LocalAssets(
              imagePath: icon!,
              height: 15,
              width: 15,
              boxFix: BoxFit.scaleDown,
              imgColor: AppColors.secondaryTextColor,
            ),
            SizedBox(width: 4.0),
          ],
          CustomText(
            label,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
            fontSize: SizeConfig.extraSmall,
          ),
        ],
      ),
    );
  }
}