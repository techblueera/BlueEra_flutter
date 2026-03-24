import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class WebsiteUrlWidget extends StatelessWidget {
  final String? websiteUrl;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  const WebsiteUrlWidget({
    super.key,
    this.websiteUrl,
    this.onTap,
    this.onAddTap,
  });

  bool get _hasUrl => websiteUrl != null && websiteUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _hasUrl
          ? (onTap ?? () => launchURL(websiteUrl!))
          : onAddTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: SizeConfig.size6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.skyBlueFF),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_rounded,
              size: 18,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              _hasUrl ? websiteUrl! : 'Add Website',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
