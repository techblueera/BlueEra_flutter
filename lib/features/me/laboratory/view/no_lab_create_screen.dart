import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/ai_lab_profile_dialoge.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoLabCreateScreen extends StatelessWidget {
  NoLabCreateScreen({super.key});

  final controller = Get.put(LabServiceAiController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.createLaboratory.tr, isLeading: false),
      body: SafeArea(
        child: SizedBox(
          width: Get.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LocalAssets(
                imagePath: AppImageAssets.noMeContent,
              ),
              SizedBox(
                height: SizeConfig.size10,
              ),
              CustomText(AppStrings.noActiveProfile.tr),
              InkWell(
                onTap: () {
                  controller.clearFiled();

                  Get.dialog(
                    AILabProfileDialog(),
                    barrierDismissible: true, // User can click outside to close
                  );
                },
                child: CustomText(
                  AppStrings.kindlyCreate.tr,
                  color: AppColors.primaryColor,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
