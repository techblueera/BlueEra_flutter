import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class CommonHorizontalDivider extends StatelessWidget {
  final Color? color;
  final double? height;
  const CommonHorizontalDivider({super.key, this.color, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SizeConfig.screenWidth,
      height: height ?? 1.0,
      color: color ?? AppColors.grey17,
    );
  }
}
