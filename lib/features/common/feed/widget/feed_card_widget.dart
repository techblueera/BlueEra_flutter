import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';

class FeedCardWidget extends StatelessWidget {
  const FeedCardWidget({super.key, required this.childWidget, this.horizontalPadding});
  final Widget childWidget;
  final double? horizontalPadding;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.paddingXSL, left: horizontalPadding??SizeConfig.paddingXS, right: horizontalPadding??SizeConfig.paddingXS),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [AppShadows.cardShadow],

      ),
      child: childWidget,
    );
  }
}
