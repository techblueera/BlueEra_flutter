import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/experience_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddFullTimeExperienceScreen extends StatefulWidget {
  final bool isEdit;
  final String? experienceId;

  AddFullTimeExperienceScreen(
      {Key? key, this.isEdit = false, this.experienceId})
      : super(key: key);

  @override
  _AddFullTimeExperienceScreenState createState() =>
      _AddFullTimeExperienceScreenState();
}

class _AddFullTimeExperienceScreenState
    extends State<AddFullTimeExperienceScreen> {
  // final ExperienceController controller = Get.put(ExperienceController(isFullTime: true));
  final controller = Get.find<ExperienceController>(tag: 'fullTime');

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
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.isEdit
              ? "Edit Full-Time Experience"
              : "Add Full-Time Experience"),
      body: Padding(
        padding: EdgeInsets.all(SizeConfig.paddingM),
        child: SingleChildScrollView(
          child: Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SizeConfig.size20),
            ),
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.size20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.size30),

                    CommonTextField(
                      title: "Previous Company Name",
                      hintText: "e.g., BlueCS Limited",
                      fontSize: SizeConfig.small,
                      textEditController: controller.previousCompanyController,
                    ),

                    SizedBox(height: SizeConfig.size24),

                    CommonTextField(
                      title: "Designation",
                      hintText: "e.g., Software Engineer",
                      fontSize: SizeConfig.small,
                      textEditController: controller.designationController,
                    ),

                    SizedBox(height: SizeConfig.size24),

                    CustomText("Job Type", fontSize: SizeConfig.small),
                    SizedBox(height: SizeConfig.size10),
                    Obx(() => CommonDropdown<String>(
                          items: controller.jobTypeOptions,
                          selectedValue: controller.selectedJobType.value,
                          hintText: "e.g., Full Time",
                          onChanged: (val) =>
                              controller.selectedJobType.value = val,
                          displayValue: (item) => item,
                        )),

                    SizedBox(height: SizeConfig.size24),

                    CustomText("Work Mode", fontSize: SizeConfig.small),
                    SizedBox(height: SizeConfig.size10),
                    Obx(() => CommonDropdown<String>(
                          items: controller.workTypeOptions,
                          selectedValue: controller.selectedWorkType.value,
                          hintText: "e.g., Remote",
                          onChanged: (val) =>
                              controller.selectedWorkType.value = val,
                          displayValue: (item) => item,
                        )),

                    SizedBox(height: SizeConfig.size24),

                    CommonTextField(
                      title: "Location",
                      hintText: "e.g., Bangalore",
                      fontSize: SizeConfig.small,
                      textEditController: controller.locationController,
                    ),

                    SizedBox(height: SizeConfig.size24),

                    CustomText("Start Date", fontSize: SizeConfig.small),
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

                    CustomText("End Date", fontSize: SizeConfig.small),
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

                    CommonTextField(
                      title: "Description Of Your Job Role In This Company",
                      hintText: "Yorem ipsum dolor sit ame…",
                      fontSize: SizeConfig.small,
                      maxLine: 4,
                      textEditController: controller.descriptionController,
                    ),

                    SizedBox(height: SizeConfig.size20),

                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => CustomBtn(
                                title: widget.isEdit ? "Update" : "Save",
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

                    SizedBox(height: SizeConfig.size30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
