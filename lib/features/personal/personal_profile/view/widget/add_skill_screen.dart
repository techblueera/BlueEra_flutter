import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_chip.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddSkillsScreen extends StatefulWidget {
  const AddSkillsScreen({super.key});

  @override
  State<AddSkillsScreen> createState() => _AddSkillsScreenState();
}

class _AddSkillsScreenState extends State<AddSkillsScreen> {
  final personalProfileController = Get.find<PersonalCreateProfileController>();

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
                          textEditController:
                              personalProfileController.skillController,
                          isValidate: false,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      CustomBtn(
                        onTap: () {
                          personalProfileController.addSkill(
                              personalProfileController.skillController.text
                                  .trim());
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
                        children:
                            personalProfileController.skillsList.map((skill) {
                          return CommonChip(
                            label: skill,
                            onDeleted: () {
                              if (personalProfileController.skillsList.length !=
                                  1) {
                                personalProfileController.removeSkill(skill);
                              } else {
                                commonSnackBar(
                                    message:
                                        "You need add at least one skill is required");
                              }
                            },
                          );
                        }).toList(),
                      )),

                  SizedBox(height: SizeConfig.size20),

                  // Save Button
                  Obx(() => CustomBtn(
                        onTap: personalProfileController.isValidate.value
                            ? () async {
                                await personalProfileController
                                    .updateUserProfileDetails(
                                  params: {
                                    ApiKeys.id: userId,
                                    ApiKeys.skills: personalProfileController
                                        .skillsList
                                        .toList()
                                  },
                                );
                              }
                            : null,
                        title: "Save",
                        isValidate: personalProfileController.isValidate.value,
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
