import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class ViewAllButton extends StatelessWidget {
  /// The function to call when the button is tapped.
  final VoidCallback onTap;
  final String? label;

  const ViewAllButton({
    super.key,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    // We use dynamic spacing for common widgets so they respect parent size
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Based on the image, the text has generous padding
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            // The soft, pale blue background
            color: AppColors.primaryColor.withAlpha(10),
            // The generous, rounded corners
            borderRadius: BorderRadius.circular(30),
          ),
          child: CustomText(
            label ?? AppStrings.viewAll,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
