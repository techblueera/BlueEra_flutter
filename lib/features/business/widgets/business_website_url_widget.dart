import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class WebsiteUrlWidget extends StatelessWidget {
  final String websiteUrl;
  final VoidCallback? onTap;

  const WebsiteUrlWidget({
    super.key,
    required this.websiteUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (websiteUrl.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap ?? () => launchURL(websiteUrl),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(
          SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.skyBlueFF
          )
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, size: 16, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              websiteUrl,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
