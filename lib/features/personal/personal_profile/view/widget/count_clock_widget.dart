
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class StatBlock extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? callback;

  const StatBlock({required this.count, required this.label, this.callback});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        if(callback!=null) callback!();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            count,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
            fontSize: SizeConfig.medium,
            fontFamily: AppConstants.OpenSans,
          ),
          const SizedBox(width: 4,),
          CustomText(
            label,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            fontSize: SizeConfig.medium,
            fontFamily: AppConstants.OpenSans,
          ),
        ],
      ),
    );
  }
}