import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

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
          label: CustomText(buttonName??"Add More",
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
