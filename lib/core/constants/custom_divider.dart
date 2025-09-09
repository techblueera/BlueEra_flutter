import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

Divider horizontalDivider({
  double indent = 10,
  double endIndent = 10,
  double height = 1,
  double thickness = 0.8,
  Color color = AppColors.greyE5,
}) {
  return Divider(
    indent: indent,
    endIndent: endIndent,
    height: height,
    thickness: thickness,
    color: color,
  );
}

VerticalDivider verticalDivider({
  double indent = 10,
  double endIndent = 10,
  double width = 1,
  double thickness = 0.8,
  Color color = AppColors.greyE5,
}) {
  return VerticalDivider(
    indent: indent,
    endIndent: endIndent,
    width: width,
    thickness: thickness,
    color: color,
  );
}

// Divider get horizontalDivider => const Divider(
//       indent: 10,
//       endIndent: 10,
//       height: 1,
//       thickness: 0.8,   // was 0.2
//       color: AppColors.greyE5, // darker grey than grey99
//     );
