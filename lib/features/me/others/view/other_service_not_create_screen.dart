import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/view/ai_other_profile_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherServiceNotCreateScreen extends StatelessWidget {
  const OtherServiceNotCreateScreen({super.key, required this.controller});

  final BusinessProfileFullController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: Get.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: AppImageAssets.noMeContent,
            ),
            SizedBox(
              height: SizeConfig.size10,
            ),
            CustomText("You Have Not Any Active Other Service"),
            InkWell(
              onTap: () {
                controller.clearAiGenerateFiled();

                Get.dialog(
                  AiOtherProfileDialog(),
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
      ),
    );
  }
}
