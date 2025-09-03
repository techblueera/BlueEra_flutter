import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';

class FeedCardWidget extends StatelessWidget {
  const FeedCardWidget({super.key, required this.childWidget});
  final Widget childWidget;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.paddingXSL, left: SizeConfig.paddingXS, right: SizeConfig.paddingXS),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [AppShadows.cardShadow]
      ),
      child: childWidget,
    );
  }
}
