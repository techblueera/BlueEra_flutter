import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/website_update_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebsiteTab extends StatelessWidget {
  const WebsiteTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ViewBusinessDetailsController>();

    return Obx(() {
      final websiteUrl =
          controller.businessProfileDetails.value?.data?.websiteUrl ?? '';

      if (websiteUrl.isNotEmpty) {
        return Column(
          children: [
            Container(
              color: AppColors.white,
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size8,
              ),
              child: Row(
                children: [
                  Icon(Icons.language_rounded,
                      size: 18, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CustomText(
                      websiteUrl,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  GestureDetector(
                    onTap: () => showUpdateWebsiteBottomSheet(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size10,
                        vertical: SizeConfig.size4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomText(
                        'Update',
                        fontSize: SizeConfig.extraSmall,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CommonWebView(
                urlLink: websiteUrl,
                urlTitle: '',
                hideAppBar: true,
              ),
            ),
          ],
        );
      }

      return Center(
        child: GestureDetector(
          onTap: () => showUpdateWebsiteBottomSheet(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                size: 64,
                color: AppColors.greyE5,
              ),
              SizedBox(height: SizeConfig.size15),
              CustomText(
                'Add Website',
                fontSize: SizeConfig.large,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      );
    });
  }
}
