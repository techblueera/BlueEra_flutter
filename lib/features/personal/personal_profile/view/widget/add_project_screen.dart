import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddProjectScreen extends StatefulWidget {
  AddProjectScreen({super.key, required this.isEdit, this.projectId});

  final bool isEdit;
  final String? projectId;

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
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
        title: widget.isEdit ? "Edit Project" : "Add Project",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              CommonTextField(
                textEditController: personalController.titleController,
                title: "Project Title",
                hintText: "E.g., E-commerce Platform",
                maxLength: 100,
                isValidate: false,
                onChange: (value) {
                  personalController.validateProjectForm();
                },
              ),
              SizedBox(height: SizeConfig.size16),

              // Description Field
              CommonTextField(
                textEditController: personalController.descriptionController,
                title: "Project Description",
                hintText: "Describe your project and technologies used",
                maxLine: 5,
                maxLength: 200,
                isValidate: false,
                onChange: (value) {
                  personalController.validateProjectForm();
                },
              ),
              SizedBox(height: SizeConfig.size24),

              // Save Button
              CustomBtn(
                title: widget.isEdit ? "Update" : "Save",
                onTap: personalController.isFormValid.value
                    ? () async {
                        await personalController.updateUserProfileDetails(
                          params: {
                            ApiKeys.projects: [{
                              ApiKeys.title:
                              personalController.titleController.text,
                              ApiKeys.description:
                              personalController.descriptionController.text,
                            }]
                          },
                        );
                      }
                    : null,
                isValidate: personalController.isFormValid.value,
              )
            ],
          );
        }),
      ),
    );
  }
}
