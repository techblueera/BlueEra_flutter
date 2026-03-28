import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class BusinessCommonSubCategoryWidget extends StatelessWidget {
  final String? label;
  final Color? borderColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;

  const BusinessCommonSubCategoryWidget({
    super.key,
    this.label,
    this.borderColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (label == null || label!.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor ?? AppColors.secondaryTextColor,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: CustomText(
        label,
        fontSize: fontSize ?? 12,
        color: textColor ?? AppColors.secondaryTextColor,
        fontWeight: fontWeight ?? FontWeight.w400,
      ),
    );
  }
}
