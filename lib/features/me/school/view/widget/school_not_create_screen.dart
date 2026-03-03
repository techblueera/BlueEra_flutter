import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/me/school/view/widget/ai_profile_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolNotCreateScreen extends StatelessWidget {
  const SchoolNotCreateScreen({super.key, required this.controller});

  final SchoolController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return controller.isAiLoading.value
            ? Center(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 15),
                    CustomText("Data fetching from AI"),
                    const CustomText("Please wait for 10-15 sec",
                       fontSize: 12),
                  ],
                ),
            )
            : SizedBox(
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
                    CustomText(AppStrings.noActiveProfile),
                    InkWell(
                      onTap: () {
                        controller.clearAiGenerateFiled();

                        Get.dialog(
                          AIProfileDialog(),
                          barrierDismissible:
                              true, // User can click outside to close
                        );
                      },
                      child: CustomText(
                        AppStrings.kindlyCreate,
                        color: AppColors.primaryColor,
                      ),
                    )
                  ],
                ),
              );
      }),
    );
  }
}
