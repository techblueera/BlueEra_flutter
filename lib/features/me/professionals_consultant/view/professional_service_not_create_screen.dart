import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalServiceNotCreateScreen extends StatelessWidget {
  const ProfessionalServiceNotCreateScreen(
      {super.key, required this.controller});

  final AiProfessionalsController controller;

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
            CustomText("You Have Not Any Active Service"),
            InkWell(
              onTap: () async {


                await showCommonDialog(
                    context: context,
                    text: 'Are you sure you want to create via Blue Era AI ?',
                    confirmCallback: () async {
                      Get.back();
                      await controller.aiGenerateServiceFetchController();
                    },
                    cancelCallback: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    confirmText: AppStrings.yes,
                    cancelText: AppStrings.no);
              },
              child: CustomText(
                "Kindly Create Via Blue Era AI",
                color: AppColors.primaryColor,
              ),
            )
          ],
        ),
      ),
    );
  }
}
