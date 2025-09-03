import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common_box_shadow.dart';

class BusinessTypeCard extends StatelessWidget {
  final BusinessType type;
  final String icon;
  final String title;
  final String subtitle;
  final BusinessType selectedType;
  final Function(BusinessType) onSelect;

  const BusinessTypeCard({
    Key? key,
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedType,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(type),
        child: Container(
          // width: 120,
          height: 110,
          padding: EdgeInsets.all(SizeConfig.paddingXSmall),
          decoration: BoxDecoration(
            color: AppColors.white,
            // color: isSelected ? AppColors.primaryColor : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              AppShadows.textFieldShadow
            ],
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              LocalAssets(
                imagePath: icon,
                imgColor: isSelected ? AppColors.primaryColor : AppColors.black,
              ),
              CustomText(
                title,
                textAlign: TextAlign.center,
                color: isSelected ? AppColors.primaryColor : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: SizeConfig.size10,
              ),
              CustomText(
                "(${subtitle})",
                textAlign: TextAlign.center,
                color: isSelected ? AppColors.primaryColor : Colors.black,
                fontSize: SizeConfig.size8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
