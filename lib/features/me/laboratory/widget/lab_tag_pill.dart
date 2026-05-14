import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Compact, pill-shaped tag tinted with [AppColors.primaryColor].
///
/// Used in laboratory list rows to surface short labelled values (price,
/// discount, start time, fees, report duration, etc.).
class LabTagPill extends StatelessWidget {
  final String text;

  const LabTagPill(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.small,
        color: AppColors.primaryColor,
      ),
    );
  }
}
