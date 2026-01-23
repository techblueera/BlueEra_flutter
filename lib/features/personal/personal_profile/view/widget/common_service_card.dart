import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/core/constants/size_config.dart';

class CommonServiceCard extends StatelessWidget {
  final CollapsibleGridModel service;
  final VoidCallback? onTap;
  final double spacing;
  final bool isSelected;

  const CommonServiceCard({
    Key? key,
    required this.service,
    this.onTap,
    this.spacing = 8.0,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      // splashColor: Colors.red,
      // highlightColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size4),
        decoration: BoxDecoration(
          color: AppColors.white,
          // color: service.bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [AppShadows.textFieldShadow],
          border: Border.all(
              color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
              width: 1.5
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: SizeConfig.size45,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: LocalAssets(
                    imagePath: service.icon,
                    boxFix: BoxFit.cover,
                    height: SizeConfig.size45,
                    // width: SizeConfig.size40,
                ),
              ),
            ),
            SizedBox(height: spacing),
            Flexible(
              child: CustomText(
                service.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
