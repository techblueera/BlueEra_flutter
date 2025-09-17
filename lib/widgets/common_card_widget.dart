import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class CommonCardWidget extends StatelessWidget {
  final Widget child;
  final double? padding;
  final double? borderRadius;
  final double? cardMargin;
  final Color? shadowColor;

  const CommonCardWidget({super.key, required this.child, this.padding, this.borderRadius, this.shadowColor, this.cardMargin});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius??10),
        side: BorderSide.none,
      ),
      margin: EdgeInsets.only(top: cardMargin??10),
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(padding ?? SizeConfig.size15),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10.0),
        ),
        child: child,
      ),
    );
  }
}
