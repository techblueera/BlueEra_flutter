import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class CommonCardWidget extends StatelessWidget {
  final Widget child;
  final double? padding;
  final double? borderRadius;
  final double? cardMargin;
  final Color? shadowColor;
  final Color? bgColor;
  final Color? borderColorColor;

  const CommonCardWidget(
      {super.key,
      required this.child,
      this.padding,
      this.borderColorColor,
      this.borderRadius,
      this.shadowColor,
      this.cardMargin,
      this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor ?? AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 10),
        side: BorderSide.none,
      ),
      margin: EdgeInsets.all(cardMargin ?? 10),
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(padding ?? SizeConfig.size15),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: borderColorColor ?? Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? AppColors.grey6D,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
