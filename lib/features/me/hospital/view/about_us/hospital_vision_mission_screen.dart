import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_vision_mission_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalVisionMissionScreen extends StatefulWidget {
  const HospitalVisionMissionScreen({
    super.key,
  });

  @override
  State<HospitalVisionMissionScreen> createState() =>
      _HospitalVisionMissionScreenState();
}

class _HospitalVisionMissionScreenState
    extends State<HospitalVisionMissionScreen> {
  late final HospitalVisionMissionController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalVisionMissionController());
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Vision & Mission",
        isLeading: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        return Padding(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            children: [
              CommonCardWidget(
                cardMargin: 0,
                padding: 0,
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 12.0,vertical: 5),
                  child: AiDescriptionField(
                    label: "Describe your hospital's vision and mission",
                    hintText: "Tell us more about the Hospital vision and mission...",
                    controller: controller.visionController,
                    rxValue: controller.descriptionTest,
                    // Your RX variable from the controller
                    aiType: "Hospital vision and mission",
                    aiData: {},
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size20),
              PositiveCustomBtn(
                onTap:
                    controller.isSaving.value ? null : controller.saveOrUpdate,
                title: controller.data.value == null ? "Save" : "Update",
                width: double.infinity,
                height: SizeConfig.size45,
                bgColor: AppColors.primaryColor,
                borderColor: AppColors.primaryColor,
              ),
            ],
          ),
        );
      }),
    );
  }
}
