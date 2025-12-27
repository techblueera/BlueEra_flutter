import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/profile_dialog_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolHomeScreen extends StatelessWidget {
  const SchoolHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteE91.withValues(alpha: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppImageAssets.noMeContent,
          ),
          SizedBox(
            height: SizeConfig.size10,
          ),
          CustomText("You Have Not Any Active Profile"),
          InkWell(
            onTap: () {
              Get.dialog(
                AIProfileDialog(),
                barrierDismissible: true, // User can click outside to close
              );
            },
            child: CustomText(
              "Kindly Create!",
              color: AppColors.primaryColor,
            ),
          )
        ],
      ),
    );
  }
}

class AIProfileDialog extends StatelessWidget {
  AIProfileDialog({super.key});

  final controller = Get.put(ProfileDialogController());

  @override
  Widget build(BuildContext context) {
    // Inject the controller

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.extraLarge22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText("Create Your profile Via AI",
                fontSize: SizeConfig.size20, fontWeight: FontWeight.bold),
            SizedBox(height: SizeConfig.size20),

            CommonTextField(
              title: "Search Your Profile On Google",
              textEditController: controller.searchController,
              hintText: "E.g. Bharati Public School...",
            ),
            SizedBox(height: SizeConfig.size20),
            HttpsTextField(
              title: "Organization Website",
              controller: controller.websiteController,
              hintText: "E.g. https://bhartipublic.com",
            ),

            SizedBox(height: SizeConfig.size30),

            // Buttons Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PositiveCustomBtn(
                    onTap: controller.generateProfile,
                    title: AppStrings.generate,
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  flex: 1,
                  child: CustomBtn(
                    onTap: () {
                      Get.back();
                    },
                    title: AppStrings.skip,
                    bgColor: AppColors.greyLite,
                    textColor: AppColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
