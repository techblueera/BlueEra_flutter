import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  ProfessionalProfileScreen({super.key});

  @override
  State<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final controller = Get.find<AiProfessionalsController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.clearAboutProfessional();

    About? about = controller.getProfessionalServiceRes?.value.data?.about;

    controller.expYearController.text =
        about?.totalExperience?.years.toString() ?? "";
    controller.expMonthController.text =
        about?.totalExperience?.months.toString() ?? "";
    controller.descriptionController.text = about?.description ?? "";
    controller.description.value = about?.description ?? "";

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "About Professional"),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText("Total Experience", fontWeight: FontWeight.bold),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      textEditController: controller.expYearController,
                      hintText: "E.g. 1 Year",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: CommonTextField(
                      textEditController: controller.expMonthController,
                      hintText: "E.g. 2 Months",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() {
                // Accessing .value here tells Obx to listen for changes

                return AiDescriptionField(
                  label: "Major Projects (Description)",
                  hintText: "Tell us more about your projects...",
                  controller: controller.descriptionController,
                  // Ensure the widget itself is designed to handle RxString
                  rxValue: controller.description,
                  aiType: "Professional",
                  aiData: {
                    // Accessing nameController.text here won't trigger a rebuild
                    // unless you wrap it in a reactive variable
                    // "title": controller.nameController.text,
                    // "desc_length": currentDescription.length.toString(),
                  },
                );
              }),
              const SizedBox(height: 40),
              Obx(() => CustomBtn(
                    title: "Save",
                    isValidate: controller.isProfessionalValid.value,
                    onTap: controller.isProfessionalValid.value
                        ? () async {
                            if (int.parse(controller.expYearController.text) >
                                100) {
                              commonSnackBar(
                                  message:
                                      "Please enter valid years of experience");
                              return;
                            } else if (int.parse(
                                    controller.expMonthController.text) >
                                12) {
                              commonSnackBar(
                                  message:
                                      "Please enter valid experience in month");
                              return;
                            } else {
                              await controller.saveAboutProfessional();
                            }
                          }
                        : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
