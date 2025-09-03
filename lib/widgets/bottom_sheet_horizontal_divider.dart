import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class BottomSheetHorizontalDivider extends StatelessWidget {
  const BottomSheetHorizontalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: SizeConfig.size70,
        height: SizeConfig.size2,
        decoration: BoxDecoration(
          color: AppColors.greyD3,
          borderRadius: BorderRadius.circular(SizeConfig.size10),
        ),
      ),
    );
  }
}
