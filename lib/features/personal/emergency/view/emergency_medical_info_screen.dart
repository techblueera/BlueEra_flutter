import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../emergency/controller/emergency_basic_info_controller.dart';

class EmergencyMedicalInfoScreen extends StatefulWidget {
  const EmergencyMedicalInfoScreen({super.key});

  @override
  State<EmergencyMedicalInfoScreen> createState() =>
      _EmergencyMedicalInfoScreenState();
}

class _EmergencyMedicalInfoScreenState
    extends State<EmergencyMedicalInfoScreen> {
  late final EmergencyBasicInfoController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => EmergencyBasicInfoController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.emergencyMedicalTitle.tr,
        actionText: AppStrings.emergencyStep2Of4.tr,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: CommonCardWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(AppStrings.emergencyBloodGroup.tr),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => CommonDropdownDialog<String>(
                            title: AppStrings.emergencyBloodGroup.tr,
                            hintText: AppStrings.emergencyBloodGroupHint.tr,
                            items: controller.bloodGroupTypes,
                            selectedValue:
                                controller.selectedBloodGroupType.value,
                            displayValue: (val) => val,
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedBloodGroupType.value = value;
                              }
                            },
                          )),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => CommonDropdownDialog<String>(
                            title: AppStrings.emergencySign.tr,
                            hintText: AppStrings.emergencySignHint.tr,
                            items: controller.bloodGroupSigns,
                            selectedValue:
                                controller.selectedBloodGroupSign.value,
                            displayValue: (val) => val == '+'
                                ? AppStrings.emergencyPositive.tr
                                : AppStrings.emergencyNegative.tr,
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedBloodGroupSign.value = value;
                              }
                            },
                          )),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: AppStrings.emergencyKnownAllergies.tr,
                  hintText: AppStrings.emergencyKnownAllergiesHint.tr,
                  textEditController: controller.allergiesController,
                ),
                SizedBox(height: 16),
                CommonTextField(
                  title: AppStrings.emergencyKnownDisease.tr,
                  hintText: AppStrings.emergencyKnownDiseaseHint.tr,
                  textEditController: controller.diseaseController,
                ),
                SizedBox(height: 24),
                Obx(() => CustomBtn(
                      isValidate: controller.isValidMedical.value &&
                          !controller.isMedicalSaving.value,
                      onTap: controller.isValidMedical.value &&
                              !controller.isMedicalSaving.value
                          ? controller.submitMedical
                          : null,
                      title: AppStrings.next.tr,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
