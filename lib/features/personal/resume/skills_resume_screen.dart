import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller/skills_controller.dart';

class SkillsResumeScreen extends StatefulWidget {
  const SkillsResumeScreen({super.key});

  @override
  State<SkillsResumeScreen> createState() => _SkillsResumeScreenState();
}

class _SkillsResumeScreenState extends State<SkillsResumeScreen> {
  final SkillsController controller = Get.find<SkillsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Add Skills",
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: SingleChildScrollView(
            child: CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Skills",
                    color: AppColors.black1A,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size8),

                  // Text field for adding skills
                  Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          hintText: "Enter skill name",
                          textEditController: controller.skillController,
                          isValidate: false,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      CustomBtn(
                        onTap: () {
                          controller
                              .addSkill(controller.skillController.text.trim());
                        },
                        title: "Add",
                        isValidate: true,
                        width: 80,
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size15),

                  // Display selected skills as chips
                  Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.skillsList.map((skill) {
                          return CommonChip(
                            label: skill,
                            onDeleted: () {
                              controller.removeSkill(skill);
                            },
                          );
                        }).toList(),
                      )),

                  SizedBox(height: SizeConfig.size20),

                  // Save Button
                  Obx(() => CustomBtn(
                        onTap: controller.isValidate.value
                            ? () async {
                                await controller.saveSkills();
                              }
                            : null,
                        title: "Save",
                        isValidate: controller.isValidate.value,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
