import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class CommonSwitchCard extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CommonSwitchCard({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.whiteFE,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.whiteE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title,
            fontSize: SizeConfig.medium,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
          ),
          CustomSwitch(
            value: value,
            onChanged: onChanged,
            containerHeight: SizeConfig.size24,
            containerWidth: SizeConfig.size50,
            circleSize: SizeConfig.size18,
          ),
        ],
      ),
    );
  }
}