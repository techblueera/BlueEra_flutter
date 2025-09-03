import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/current_job_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCurrentJobScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? jobData;

  AddCurrentJobScreen({Key? key, this.isEdit = false, this.jobData})
      : super(key: key);

  @override
  _AddCurrentJobScreenState createState() => _AddCurrentJobScreenState();
}

class _AddCurrentJobScreenState extends State<AddCurrentJobScreen> {
  final CurrentJobController controller = Get.find<CurrentJobController>();
  final _formKey = GlobalKey<FormState>();

  bool isDateValid() {
    final day = controller.selectedDay.value;
    final month = controller.selectedMonth.value;
    final year = controller.selectedYear.value;

    if (day == null || month == null || year == null) {
      return false;
    }
    final enteredDate = DateTime(year, month, day);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    if (enteredDate.isAfter(todayDateOnly)) {
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();

    //   if (!widget.isEdit) {
    //     controller.clearAllFields();
    //   }else {
    //   // no clear to preserve fields set before navigating
    // }
    if (widget.isEdit && widget.jobData != null) {
      controller.setFieldsFromBackend(widget.jobData!);
    } else {
      controller.clearAllFields();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.isEdit ? "Edit Current Job" : "Add Current Job"),
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
                    CustomText(
                      "Your Experience",
                      fontSize: SizeConfig.small,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    Obx(() => CommonDropdown<String>(
                          items: controller.experienceOptions,
                          selectedValue: controller.selectedExperience.value,
                          hintText: 'E.g. experienced',
                          onChanged: (val) {
                            controller.selectedExperience.value = val;
                            setState(() {});
                          },
                          displayValue: (item) => item,
                        )),
                    SizedBox(height: SizeConfig.size24),
                    if (controller.selectedExperience.value != "Fresher") ...[
                      CustomText(
                        "Job Mode",
                        fontSize: SizeConfig.small,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Obx(() => CommonDropdown<String>(
                            items: controller.jobModeOptions,
                            selectedValue: controller.selectedJobMode.value,
                            hintText: 'E.g. Full-Time',
                            onChanged: (val) =>
                                controller.selectedJobMode.value = val,
                            displayValue: (item) => item,
                          )),
                      SizedBox(height: SizeConfig.size24),
                      CommonTextField(
                        fontSize: SizeConfig.small,
                        title: "Current Company Name",
                        hintText: 'E.g. BlueCS Limited',
                        textEditController: controller.currentCompanyController,
                      ),
                      SizedBox(height: SizeConfig.size24),
                      CustomText(
                        "Current You Are Working Here",
                        fontSize: SizeConfig.small,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Obx(() => CommonDropdown<String>(
                            items: controller.yesNoOptions,
                            selectedValue: controller.selectedCurrent.value,
                            hintText: 'E.g. Yes',
                            onChanged: (val) =>
                                controller.selectedCurrent.value = val,
                            displayValue: (item) => item,
                          )),
                      SizedBox(height: SizeConfig.size24),
                      CommonTextField(
                        fontSize: SizeConfig.small,
                        title: "Designation",
                        hintText: 'E.g., Software Engineer',
                        textEditController: controller.designationController,
                      ),
                      SizedBox(height: SizeConfig.size24),
                      CustomText(
                        "Work Type",
                        fontSize: SizeConfig.small,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Obx(() => CommonDropdown<String>(
                            items: controller.workTypeOptions,
                            selectedValue: controller.selectedWorkType.value,
                            hintText: 'E.g., Remote',
                            onChanged: (val) =>
                                controller.selectedWorkType.value = val,
                            displayValue: (item) => item,
                          )),
                      SizedBox(height: SizeConfig.size24),

                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteHelper.getSearchLocationScreenRoute(),
                            arguments: {
                              'onPlaceSelected': (double? lat, double? lng,
                                  String? address) {
                                if (address != null) {
                                  controller.locationController.text = address;
                                  setState(() {

                                  });
                                }
                              },
                              ApiKeys.fromScreen: ""
                            },
                          );
                        },
                        child: CommonTextField(
                          textEditController: controller.locationController,
                          hintText: "E.g., Rajiv Chowk, Delhi",
                          isValidate: false,
                          title: "Location",

                          // onChange: (value) => controller.validateForm(),
                          readOnly: true,
                          // Make it read-only since we'll use the search screen
                        ),
                      ),
                      SizedBox(height: SizeConfig.size24),
                      CustomText(
                        "Start Date",
                        fontSize: SizeConfig.small,
                      ),
                      SizedBox(height: SizeConfig.size10),

                      Obx(() => RestrictedDatePicker(
                            selectedDay: controller.selectedDay.value,
                            selectedMonth: controller.selectedMonth.value,
                            selectedYear: controller.selectedYear.value,
                            onDayChanged: (day) =>
                                controller.selectedDay.value = day,
                            onMonthChanged: (month) =>
                                controller.selectedMonth.value = month,
                            onYearChanged: (year) =>
                                controller.selectedYear.value = year,
                            isFutureYear: false,
                            // disallow future years
                            maxDate: DateTime
                                .now(), // optional: limit max date to today
                          )),

                      SizedBox(height: SizeConfig.size24),
                    ],
                    CommonTextField(
                      fontSize: SizeConfig.small,
                      title: "Description",
                      hintText:
                          'Strong communication, teamwork, and analytical skills, with the ability to grasp new concepts quickly.',
                      textEditController: controller.descriptionController,
                      maxLine: 4,
                    ),
                    SizedBox(height: SizeConfig.size20),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => CustomBtn(
                                onTap: (controller.selectedExperience.value !=
                                        "Fresher")
                                    ? controller.isCurrentJobFormValid.value
                                        ? () async {
                                            Map<String, dynamic> params = {
                                              "experience": controller
                                                  .selectedExperience.value,
                                              "jobType": controller
                                                  .selectedJobMode.value,
                                              "currentCompanyName": controller
                                                  .currentCompanyController.text
                                                  .trim(),
                                              "currentlyWorkingHere": controller
                                                      .selectedCurrent.value ==
                                                  "Yes",
                                              "designation": controller
                                                  .designationController.text
                                                  .trim(),
                                              "workMode": controller
                                                  .selectedWorkType.value,
                                              "location": controller
                                                  .locationController.text
                                                  .trim(),
                                              "description": controller
                                                  .descriptionController.text
                                                  .trim(),
                                              "startDate": {
                                                "date": controller
                                                    .selectedDay.value,
                                                "month": controller
                                                    .selectedMonth.value,
                                                "year": controller
                                                    .selectedYear.value
                                              },
                                            };
                                            await controller
                                                .saveCurrentJob(params);
                                          }
                                        : null
                                    : () async {
                                  Map<String, dynamic> params = {
                                    "experience": controller
                                        .selectedExperience.value,
                                    "description": controller
                                        .descriptionController.text
                                        .trim(),
                                  };
                                  await controller
                                      .saveCurrentJob(params);
                                },
                                title: widget.isEdit ? "Update" : "Save",
                                isValidate:
                                    (controller.selectedExperience.value !=
                                            "Fresher")
                                        ? controller.isCurrentJobFormValid.value
                                        : true,
                                textColor: Colors.white,
                                radius: SizeConfig.size8,
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
