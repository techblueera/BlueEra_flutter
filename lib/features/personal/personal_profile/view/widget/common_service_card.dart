import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/service_item.dart';

class CommonServiceCard extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final bool isSelected;

  const CommonServiceCard({
    Key? key,
    required this.service,
    this.onTap,
    this.padding,
    this.spacing = 12.0,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      // splashColor: Colors.red,
      // highlightColor: Colors.white,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: service.bgColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [AppShadows.textFieldShadow],
                  border: isSelected ? Border.all(
                    color: AppColors.primaryColor,
                    width: 1.5
                  ) : null,
                ),
                alignment: Alignment.center,
                child: LocalAssets(imagePath: service.icon, imgColor: service.labelColor),
              ),
            ),
            SizedBox(height: spacing),
            CustomText(
              service.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: service.labelColor,
            ),
          ],
        ),
      ),
    );
  }
}
