import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class SubscriptionSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onBtnPressed;

  const SubscriptionSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onBtnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.greenShade,
            width: 0.5
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Success Icon with Circle
            LocalAssets(imagePath: AppIconAssets.subscriptionSuccessIcon),

            SizedBox(height: SizeConfig.paddingM),

            // 2. Title
            CustomText(
              title,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.mainTextColor
            ),
            SizedBox(height: SizeConfig.paddingS),

            // 3. Message
            CustomText(
              message,
              textAlign: TextAlign.center,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor
            ),
            SizedBox(height: SizeConfig.paddingM),

            // 4. Action Button
            CustomBtn(
              width: double.infinity,
              textColor: AppColors.white,
              bgColor: AppColors.primaryColor,
              title: "Go to Hom",
              onTap: onBtnPressed,
            )

          ],
        ),
      ),
    );
  }
}