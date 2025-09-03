import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class SkillSection extends StatelessWidget {
  final String title;
  final List<String> skills;
  final VoidCallback onAddPressed;

  const SkillSection({
    this.title = "Skills",
    required this.skills,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(title, color: AppColors.grey72, fontSize: SizeConfig.medium),
          SizedBox(height: SizeConfig.size15),
          Wrap(
            spacing: SizeConfig.size10,
            runSpacing: SizeConfig.size10,
            children: skills
                .map((skill) => Container(
              decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: AppColors.primaryColor,

                )
              ),
              padding: EdgeInsets.all(6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(skill, color: AppColors.primaryColor, fontSize: SizeConfig.large),
                  SizedBox(width: SizeConfig.size8),
                  InkWell(
                      onTap: (){},
                      child: Icon(Icons.close, color: AppColors.primaryColor, size: SizeConfig.size20)
                  )
                ],
              ),
            ))
                .toList(),
          ),
          SizedBox(height: SizeConfig.size15),
          InkWell(
            onTap: onAddPressed,
            child: Row(
              children: [
                LocalAssets(imagePath: AppIconAssets.addBlueIcon),
                SizedBox(width: SizeConfig.size4),
                CustomText("Add $title", color: AppColors.primaryColor, fontSize: SizeConfig.large),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
