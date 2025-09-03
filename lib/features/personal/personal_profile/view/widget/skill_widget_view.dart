import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/add_skill_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SkillWidgetView extends StatelessWidget {
  SkillWidgetView({super.key, required this.isSelfPortfolio});

  final bool isSelfPortfolio;

  final personalProfileController = Get.find<PersonalCreateProfileController>();

  final viewPersonaDetailsController =
      Get.find<ViewPersonalDetailsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: Get.width,
        child: CommonCardWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Skills",
                fontWeight: FontWeight.bold,
                fontSize: SizeConfig.medium15,
              ),
              SizedBox(height: 16),

              // Content based on skills availability
              if ((personalProfileController.skillsList.isEmpty)&&!isSelfPortfolio)
                CustomText("No skills found"),
              if (personalProfileController.skillsList.isEmpty &&
                  isSelfPortfolio)
                // Empty state - Career Objective jaisa design
                addSkillButton()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: personalProfileController.skillsList
                          .where((skill) => skill.trim().isNotEmpty)
                          .map((skill) => CommonChip(
                                label: skill,
                                onDeleted: null,
                              ))
                          .toList(),
                    ),
                    if (isSelfPortfolio) ...[
                      SizedBox(height: SizeConfig.size16),
                      addSkillButton(),
                    ]
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget addSkillButton() {
    return GestureDetector(
      onTap: () => Get.to(AddSkillsScreen()),
      child: Row(
        children: [
          Icon(
            Icons.add,
            size: 16,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: 8),
          CustomText(
            "Add Skills",
            color: AppColors.primaryColor,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}
