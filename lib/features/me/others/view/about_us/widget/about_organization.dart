import 'dart:io';

import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';
import '../../../../../../core/constants/app_strings.dart';
class AboutOrganization extends StatefulWidget {
  const AboutOrganization({super.key});

  @override
  State<AboutOrganization> createState() => _AboutOrganizationState();
}
class _AboutOrganizationState extends State<AboutOrganization> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "About Organization",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// Course Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.whiteE5),

              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(AppStrings.uploadPhotos,
                      fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
                  SizedBox(height: SizeConfig.size8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.whiteE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                        vertical: 16
                    ),
                    child: Center(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LocalAssets(imagePath: AppIconAssets.uploadIcon,height: 18,width: 18,),
                          SizedBox(width: 8,),
                          CustomText(
                            "Upload Photo",
                            fontSize: 16,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size16),
                  CustomText(
                    "Title (Optional)",
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  /// Apply Button
                  CommonTextField(
                    hintText: "E-g„ How do you commute to work?",
                  ),
                  SizedBox(height: SizeConfig.size16),
                  CustomText(
                    "Description",
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  /// Apply Button
                  CommonTextField(
                    maxLine: 4,
                    hintText: "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  ),
                  SizedBox(height: SizeConfig.size18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: (){}, // disabled like screenshot
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: CustomText(
                        "Continue",
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Add course action
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20,color: AppColors.primaryColor),
                  label: CustomText(
                      "Add More",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
