import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddExperienceScreen extends StatefulWidget {
  AddExperienceScreen({super.key, required this.isEdit, this.projectId});

  final bool isEdit;
  final String? projectId;

  @override
  State<AddExperienceScreen> createState() => _AddExperienceScreenState();
}

class _AddExperienceScreenState extends State<AddExperienceScreen> {
  final personalController = Get.find<PersonalCreateProfileController>();

  @override
  void initState() {
    // TODO: implement initState
    personalController.clearProjectFields();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.isEdit ? AppStrings.editExperience.tr : AppStrings.addExperience.tr,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              CommonTextField(
                textEditController: personalController.companyNameController,
                title: AppStrings.companyName.tr,
                hintText: AppStrings.egCompanyName.tr,
                maxLength: 100,
                isValidate: false,
                onChange: (value) {
                  personalController.validateExperienceForm();
                },
              ),
              SizedBox(height: SizeConfig.size16),

              // Description Field
              CommonTextField(
                textEditController: personalController.roleResController,
                title: AppStrings.rolesResponsibilities.tr,
                hintText:
                    AppStrings.describeKeyResponsibilities.tr,
                maxLine: 5,
                maxLength: 200,
                isValidate: false,
                onChange: (value) {
                  personalController.validateExperienceForm();
                },
              ),
              SizedBox(height: SizeConfig.size24),

              // Save Button
              CustomBtn(
                title: widget.isEdit ? AppStrings.update.tr : AppStrings.save.tr,
                onTap: personalController.isFormExperienceValid.value
                    ? () async {
                        await personalController.updateUserProfileDetails(
                          params: {
                            ApiKeys.experiences: [
                              {
                                ApiKeys.companyName: personalController
                                    .companyNameController.text,
                                ApiKeys.rolesAndResponsibility:
                                    personalController.roleResController.text,
                              }
                            ]
                          },
                        );
                      }
                    : null,
                isValidate: personalController.isFormExperienceValid.value,
              )
            ],
          );
        }),
      ),
    );
  }
}
