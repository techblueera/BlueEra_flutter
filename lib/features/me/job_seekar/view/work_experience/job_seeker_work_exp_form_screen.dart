import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/experience_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerWorkExpFormScreen extends StatefulWidget {
  final bool isEdit;
  final String? experienceId;

  JobSeekerWorkExpFormScreen(
      {Key? key, this.isEdit = false, this.experienceId})
      : super(key: key);

  @override
  _JobSeekerWorkExpFormScreenState createState() =>
      _JobSeekerWorkExpFormScreenState();
}

class _JobSeekerWorkExpFormScreenState
    extends State<JobSeekerWorkExpFormScreen> {
  // final controller = Get.find<ExperienceController>(tag: 'fullTime');
  final controller = getOrPut(() => ExperienceController(isFullTime: true));

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (!widget.isEdit) {
      controller.clearAllFields();
    } else {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: "Work Experience"
              ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: CommonCardWidget(

            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  CommonTextField(
                    title: AppStrings.previousCompanyName,
                    hintText: AppStrings.previousCompanyHint,
                    fontSize: SizeConfig.small,
                    textEditController: controller.previousCompanyController,
                  ),

                  SizedBox(height: SizeConfig.size24),

                  CommonTextField(
                    title: AppStrings.designation,
                    hintText: AppStrings.designationHint,
                    fontSize: SizeConfig.small,
                    textEditController: controller.designationController,
                  ),

                  SizedBox(height: SizeConfig.size24),

                  CustomText(AppStrings.jobType, fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size10),
                  Obx(() => CommonDropdownDialog<String>(
                        items: controller.jobTypeOptions,
                        selectedValue: controller.selectedJobType.value,
                        hintText: AppStrings.jobTypeHint,
                        onChanged: (val) =>
                            controller.selectedJobType.value = val,
                        displayValue: (item) => item,
                    title: AppStrings.jobType,
                      )),

                  SizedBox(height: SizeConfig.size24),

                  CustomText(AppStrings.workMode, fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size10),
                  Obx(() => CommonDropdownDialog<String>(
                        items: controller.workTypeOptions,
                        selectedValue: controller.selectedWorkType.value,
                        hintText: AppStrings.workModeHint,
                    title:AppStrings.workMode,

                        onChanged: (val) =>
                            controller.selectedWorkType.value = val,
                        displayValue: (item) => item,
                      )),

                  SizedBox(height: SizeConfig.size24),

                  CommonTextField(
                    title: AppStrings.location,
                    hintText:AppStrings.locationHint,
                    fontSize: SizeConfig.small,
                    textEditController: controller.locationController,
                  ),

                  SizedBox(height: SizeConfig.size24),

                  CustomText(AppStrings.startDate, fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size10),
                  Obx(() => NewDatePicker(
                        selectedDay: controller.selectedStartDay.value,
                        selectedMonth: controller.selectedStartMonth.value,
                        selectedYear: controller.selectedStartYear.value,
                        onDayChanged: (val) =>
                            controller.selectedStartDay.value = val,
                        onMonthChanged: (val) =>
                            controller.selectedStartMonth.value = val,
                        onYearChanged: (val) =>
                            controller.selectedStartYear.value = val,
                      )),

                  SizedBox(height: SizeConfig.size24),

                  CustomText(AppStrings.endDate, fontSize: SizeConfig.small),
                  SizedBox(height: SizeConfig.size10),
                  Obx(() => NewDatePicker(
                        selectedDay: controller.selectedEndDay.value,
                        selectedMonth: controller.selectedEndMonth.value,
                        selectedYear: controller.selectedEndYear.value,
                        onDayChanged: (val) =>
                            controller.selectedEndDay.value = val,
                        onMonthChanged: (val) =>
                            controller.selectedEndMonth.value = val,
                        onYearChanged: (val) =>
                            controller.selectedEndYear.value = val,
                      )),

                  SizedBox(height: SizeConfig.size24),
                  AiDescriptionField(
                    label: AppStrings.jobRoleDescription.tr,
                    hintText: AppStrings.jobRoleDescriptionHint,
                    controller: controller.descriptionController,
                    rxValue: "".obs,
                    // Your RX variable from the controller
                    aiType: "job role description",
                    aiData: {
                      "name": controller.previousCompanyController.text,
                      "designation": controller.designationController.text,
                      "jobtype":controller.selectedJobType.value,
                      "workmode":controller.selectedWorkType.value,
                      "location": controller.locationController.text
                      // "title": controller.title.value,
                    },
                  ),


                  SizedBox(height: SizeConfig.size20),

                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => CustomBtn(
                              title: widget.isEdit ? AppStrings.update : AppStrings.save,
                              isValidate: controller.isFormValid.value,
                              onTap: controller.isFormValid.value
                                  ? () async {
                                      if (_formKey.currentState!.validate()) {
                                        await controller.saveExperience(
                                          isEdit: widget.isEdit,
                                          id: widget
                                              .experienceId, // Pass the experience id here
                                        );
                                      }
                                    }
                                  : null,
                            )),
                      ),
                    ],
                  ),

                  // SizedBox(height: SizeConfig.size30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
