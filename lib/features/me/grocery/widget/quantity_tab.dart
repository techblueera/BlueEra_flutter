import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class QuantityTab extends StatelessWidget {
  final String label;

  const QuantityTab({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          width: 0.5,
          color: AppColors.greyE5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
      child: CustomText(
        label,
        fontSize: 12,
        color: AppColors.secondaryTextColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}