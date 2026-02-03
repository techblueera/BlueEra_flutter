import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/skills_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class JobSeekerSkillsFormScreen extends StatefulWidget {
  const JobSeekerSkillsFormScreen({super.key});

  @override
  State<JobSeekerSkillsFormScreen> createState() => _JobSeekerSkillsFormScreenState();
}

class _JobSeekerSkillsFormScreenState extends State<JobSeekerSkillsFormScreen> {
  final controller = getOrPut(() => SkillsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.addSkills,
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
                    AppStrings.skills,
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
                          hintText: AppStrings.enterSkillName,
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
                        title: AppStrings.add,
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
                        title: AppStrings.save,
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
