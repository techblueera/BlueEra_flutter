import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class CommonServiceCard<T> extends StatelessWidget {
  final T service;
  final String Function(T) getName;
  final String Function(T) getIcon;
  final Function(T) onTap;
  final bool isSelected;
  final double? iconHeight;
  final double? spacing;
  final double? borderWidth;

  const CommonServiceCard({
    Key? key,
    required this.service,
    required this.getName,
    required this.getIcon,
    required this.onTap,
    this.isSelected = false,
    this.iconHeight,
    this.spacing,
    this.borderWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap(service),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [AppShadows.textFieldShadow],
          border: Border.all(
              color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
              width: borderWidth ?? 1.0
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: getIcon(service),
              height: iconHeight ?? SizeConfig.size50,
            ),
            SizedBox(height: spacing ?? SizeConfig.paddingXSL),
            CustomText(
              getName(service),
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          ],
        ),
      ),
    );
  }
}
