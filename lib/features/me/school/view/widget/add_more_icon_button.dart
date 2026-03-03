import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

class AddMoreIconButton extends StatelessWidget {
   AddMoreIconButton({super.key, required this.onTapEvent,  this.buttonName});
  final VoidCallback onTapEvent;
  final String? buttonName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onTapEvent,
          icon: const Icon(Icons.add_circle_outline,
              size: 20, color: AppColors.primaryColor),
          label: CustomText(buttonName??"${AppStrings.addMore.tr}",
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
