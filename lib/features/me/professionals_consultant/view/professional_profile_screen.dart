import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expertise_ai_genereted_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  ProfessionalProfileScreen({super.key});

  @override
  State<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState
    extends State<ProfessionalProfileScreen> {
  final controller = Get.find<AiProfessionalsController>();

  @override
  void initState() {
    controller.clearAboutProfessional();
    About? about =
        controller.getProfessionalServiceRes?.value.data?.about;
    controller.expYearController.text =
        about?.totalExperience?.years.toString() ?? "";
    controller.expMonthController.text =
        about?.totalExperience?.months.toString() ?? "";
    controller.descriptionController.text =
        about?.description ?? "";
    controller.description.value = about?.description ?? "";
    controller.expertiseController.text =
        about?.expertise?.join(',') ?? "";
    controller.expertiseText.value =
        about?.expertise?.join(',') ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "About Professional"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size14),
          child: Column(
            children: [
              // --- Expertise ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.star_outline,
                                color: AppColors.primaryColor,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomText("Your Expertise",
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.medium),
                          ),
                          AIExpertiseGeneratorButton(
                            onSelected: (generatedText) {
                              controller.expertiseText.value =
                                  generatedText;
                              controller.expertiseController.text =
                                  generatedText;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CommonTextField(
                        title: "",
                        textEditController:
                            controller.expertiseController,
                        hintText:
                            "E.g. Tax Filing, GST, Compliance...",
                        maxLine: 3,
                        maxLength: 400,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size14),

              // --- Experience ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.work_history_outlined,
                                color: AppColors.primaryColor,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          CustomText("Total Experience",
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CommonTextField(
                              title: "Years",
                              textEditController:
                                  controller.expYearController,
                              hintText: "E.g. 5",
                              keyBoardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: CommonTextField(
                              title: "Months",
                              textEditController:
                                  controller.expMonthController,
                              hintText: "E.g. 6",
                              keyBoardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size14),

              // --- Major Projects ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.description_outlined,
                                color: AppColors.primaryColor,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          CustomText("Major Projects",
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AiDescriptionField(
                        label: "",
                        hintText:
                            "Tell us about your major projects...",
                        controller:
                            controller.descriptionController,
                        rxValue: controller.description,
                        aiType: "Professional",
                        aiData: {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- Save ---
              Obx(() => CustomBtn(
                    title: AppStrings.save.tr,
                    isValidate:
                        controller.isProfessionalValid.value,
                    onTap: controller.isProfessionalValid.value
                        ? () async {
                            if (int.tryParse(controller
                                        .expYearController.text) !=
                                    null &&
                                int.parse(controller
                                        .expYearController.text) >
                                    100) {
                              commonSnackBar(
                                  message:
                                      "Please enter valid years of experience");
                              return;
                            } else if (int.tryParse(controller
                                        .expMonthController.text) !=
                                    null &&
                                int.parse(controller
                                        .expMonthController.text) >
                                    12) {
                              commonSnackBar(
                                  message:
                                      "Please enter valid months");
                              return;
                            }
                            await controller
                                .saveAboutProfessional();
                          }
                        : null,
                  )),
              SizedBox(height: SizeConfig.size20),
            ],
          ),
        ),
      ),
    );
  }
}
