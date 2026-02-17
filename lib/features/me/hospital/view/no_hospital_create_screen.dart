import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/ai_hospital_profile_dialoge.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoHospitalCreateScreen extends StatelessWidget {
  NoHospitalCreateScreen({super.key});

  final controller = Get.put(HospitalServiceAiController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Create Hospital", isLeading: false),
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
              CustomText("You Have Not Any Active Profile"),
              InkWell(
                onTap: () {
                  controller.clearFiled();

                  Get.dialog(
                    AIHospitalProfileDialog(),
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
      ),
    );
  }
}
