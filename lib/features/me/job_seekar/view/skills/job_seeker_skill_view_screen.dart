import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/skills_controller.dart';
import 'package:BlueEra/features/personal/resume/skills_resume_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerSkillViewScreen extends StatefulWidget {
  const JobSeekerSkillViewScreen({super.key});

  @override
  State<JobSeekerSkillViewScreen> createState() =>
      _JobSeekerSkillViewScreenState();
}

class _JobSeekerSkillViewScreenState extends State<JobSeekerSkillViewScreen> {
  final skillsController = Get.put(SkillsController());
  final getResumeController = Get.find<ProfilePicController>();

  @override
  void initState() {
    // TODO: implement initState
    getResumeController.getMyResume();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.skills,
      ),
      body: Obx(() {
        return CommonCardWidget(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (skillsController.skillsList.isEmpty)
                // Empty state - Career Objective jaisa design
                GestureDetector(
                  onTap: () => navigatePushTo(context, SkillsResumeScreen()),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 8),
                      CustomText(
                        AppStrings.addSkills,
                        color: AppColors.primaryColor,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skillsController.skillsList
                          .where((skill) => skill.trim().isNotEmpty)
                          .map((skill) => CommonChip(
                                label: skill,
                                onDeleted: () {
                                  showConfirmDialog(
                                    context,
                                    () {
                                      skillsController.deleteSkillsApi(skill);
                                      Navigator.of(context).pop();
                                    },
                                    title: AppStrings.deleteSkill,
                                    content:
                                        "${AppStrings.deleteConfirm.tr} '$skill'?",
                                  );
                                },
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () =>
                          navigatePushTo(context, SkillsResumeScreen()),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 8),
                          CustomText(
                            AppStrings.addSkills,
                            color: AppColors.primaryColor,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      }),
    );
  }
}
