import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/qualification_contoller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HighestQualificationScreen extends StatefulWidget {
  final bool isEdit;
  final String? itemId;

  HighestQualificationScreen({Key? key, this.isEdit = false, this.itemId})
      : super(key: key);

  @override
  _HighestQualificationScreenState createState() =>
      _HighestQualificationScreenState();
}

class _HighestQualificationScreenState
    extends State<HighestQualificationScreen> {
  final QualificationContoller controller = Get.find<QualificationContoller>();
  final List<String> qualificationOptions = [
    "Below 10th",
    "10th Pass",
    "12th Pass",
    "Diploma",
    "Bachelor's degree",
    "Master's degree",
    "Doctorate",
    "Others"
  ];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.itemId != null) {
      final item = controller.educationList
          .firstWhereOrNull((e) => e['_id'] == widget.itemId);
      if (item != null) {
        controller.setEditFieldsFromCard(item);
      }
    } else {
      controller.clearAll();
      controller.editReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.isEdit
              ? 'Edit Highest Qualification'
              : 'Add Highest Qualification'),
      body: Padding(
        padding: EdgeInsets.all(SizeConfig.paddingL),
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
                    CustomText(
                      "Highest Qualification",
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.small,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    Obx(() => CommonDropdown<String>(
                          items: qualificationOptions,
                          selectedValue:
                              controller.highestQualification.value.isEmpty
                                  ? null
                                  : controller.highestQualification.value,
                          hintText: "Select Qualification",
                          onChanged: (val) {
                            controller.highestQualification.value = val ?? '';
                            controller.validateEducationForm();
                          },
                          displayValue: (item) => item,
                        )),
                    SizedBox(height: SizeConfig.size20),

                    // School/College
                    Obx(() => CommonTextField(
                          title: "School/College Name",
                          textEditController: controller.schoolController,
                          initialValue: controller.school.value,
                          onChange: (val) {
                            controller.school.value = val;
                            controller.validateEducationForm();
                          },
                          hintText: "E.g. Sagarbhanga High School",
                          borderColor: AppColors.greyE5,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingM,
                            vertical: SizeConfig.paddingS,
                          ),
                        )),
                    SizedBox(height: SizeConfig.size18),

                    // Board
                    Obx(() => CommonTextField(
                          title: "Board Name",
                          textEditController: controller.boardController,
                          initialValue: controller.board.value,
                          onChange: (val) {
                            controller.board.value = val;
                            controller.validateEducationForm();
                          },
                          hintText: "E.g. CBSE",
                          borderColor: AppColors.greyE5,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingM,
                            vertical: SizeConfig.paddingS,
                          ),
                        )),
                    SizedBox(height: SizeConfig.size18),

                    // Passing Year (formatting: digitsOnly, max length 4)
                    Obx(() => CommonTextField(
                          title: "Passing Year",
                          textEditController: controller.yearController,
                          initialValue: controller.year.value,
                          onChange: (val) {
                            controller.year.value = val;
                            controller.validateEducationForm();
                          },
                          inputLength: 4,
                          hintText: "E.g. 2020",
                          borderColor: AppColors.greyE5,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingM,
                            vertical: SizeConfig.paddingS,
                          ),
                          keyBoardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        )),
                    SizedBox(height: SizeConfig.size18),

                    // Performance Score (formatting: digitsOnly, max length 3, max value 100)
                    Obx(() => CommonTextField(
                          title: "Performance Score",
                          textEditController: controller.scoreController,
                          initialValue: controller.score.value,
                          onChange: (val) {
                            controller.score.value = val;
                            controller.validateEducationForm();
                          },
                          hintText: "E.g., 80%",
                          borderColor: AppColors.greyE5,
                          hintTextColor: AppColors.grey9B,
                          fontSize: SizeConfig.small,
                          keyBoardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                            _MaxValueInputFormatter(100),
                          ],
                          fontWeight: FontWeight.w400,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingM,
                            vertical: SizeConfig.paddingS,
                          ),
                        )),
                    SizedBox(height: SizeConfig.size30),

                    Row(
                      children: [
                        Expanded(
                    
                          child: Obx(() => CustomBtn(
                                title: widget.isEdit ? "Update" : "Save",
                                isValidate:
                                    controller.isEducationFormValid.value,
                                onTap: controller.isEducationFormValid.value
                                    ? () async {
                                        Map<String, dynamic> params = {
                                          "highestQualification": controller
                                              .highestQualification.value
                                              .trim(),
                                          "schoolOrCollegeName":
                                              controller.school.value.trim(),
                                          "boardName":
                                              controller.board.value.trim(),
                                          "passingYear": int.tryParse(controller
                                                  .year.value
                                                  .trim()) ??
                                              0,
                                          "percentage": controller.score.value
                                                  .trim()
                                                  .endsWith('%')
                                              ? controller.score.value.trim()
                                              : controller.score.value.trim() +
                                                  '%',
                                        };
                                        if (widget.isEdit &&
                                            widget.itemId != null) {
                                          await controller
                                              .updateEducation(params);
                                        } else {
                                          await controller.addEducation(params);
                                        }
                                      }
                                    : null,
                              )),
                        ),
                      ],
                    ),
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

class _MaxValueInputFormatter extends TextInputFormatter {
  final int max;
  _MaxValueInputFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final int? value = int.tryParse(newValue.text);
    if (value == null || value > max) {
      return oldValue;
    }
    return newValue;
  }
}
