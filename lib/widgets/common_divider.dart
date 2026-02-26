import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class CommonVerticalDivider extends StatelessWidget {
  final Color? color;
  final double? height;
  final double? width;
  const CommonVerticalDivider({super.key, this.color, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size5),
      child: Container(
        width: width ?? 0.5,
        height: height ?? SizeConfig.size20,
        color: color ?? AppColors.secondaryTextColor,
      ),
    );
  }
}
