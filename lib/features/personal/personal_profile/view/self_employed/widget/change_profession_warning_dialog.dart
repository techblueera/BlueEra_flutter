import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/constants/app_colors.dart';

class ChangeProfessionWarningDialog extends StatelessWidget {
  // final EarnServiceTypes serviceSubType;
  // final String designation;
  final String title;
  final String description;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const ChangeProfessionWarningDialog({
    super.key,
    // required this.serviceSubType,
    // required this.designation,
    this.title = "Change Profession",
    this.description = "If you change your profession, old data will be deleted and your profession will be updated.",
    this.confirmText = "Confirm",
    this.cancelText = "Cancel",
    required this.onConfirm,
  });

  static void show(
      BuildContext context, {
        // required EarnServiceTypes serviceSubType,
        // required String designation,
        required VoidCallback onConfirm,
      }) {
    showDialog(
      context: context,
      builder: (context) => ChangeProfessionWarningDialog(
        // serviceSubType: serviceSubType,
        // designation: designation,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      backgroundColor: Colors.white,
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Warning Icon ---
            LocalAssets(
            imagePath: AppIconAssets.warningRedIcon,
            width: 50.0,
            height: 50.0,
           ),
            SizedBox(height: SizeConfig.paddingM),

            // --- Title ---
            CustomText(
              title,
              textAlign: TextAlign.center,
              fontSize: SizeConfig.extraLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.paddingS),

            // --- Description ---
            CustomText(
              description,
              textAlign: TextAlign.center,
              fontSize: SizeConfig.medium,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.paddingXL),

            // --- Buttons ---
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: CustomBtn(
                    onTap: () => Navigator.of(context).pop(),
                    title: cancelText,
                    textColor: AppColors.blackMite,
                    bgColor: AppColors.greyDF
                  ),
                ),

                SizedBox(width: SizeConfig.size8),

                // Confirm Button
                Expanded(
                  child: CustomBtn(
                    onTap: () {
                      Navigator.of(context).pop(); // Close dialog first
                      onConfirm(); // Trigger action
                    },
                    title: confirmText,
                    bgColor: AppColors.red33
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}