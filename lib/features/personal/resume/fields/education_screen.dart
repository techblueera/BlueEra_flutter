import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/education_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';


class EducationScreen extends StatefulWidget {
  final bool isEdit;
  const EducationScreen({Key? key, this.isEdit = false}) : super(key: key);

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final EducationController controller = Get.find<EducationController>();

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

  @override
  void initState() {
    super.initState();
    // Clear when adding new
    if (!widget.isEdit) {
      controller.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.isEdit ? AppStrings.editEducation : AppStrings.addEducation,
      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.education,
                    fontSize: SizeConfig.small,
                  ),
                  SizedBox(height: SizeConfig.size10),
  
                  Obx(() => CommonDropdownDialog<String>(
                        items: qualificationOptions,
                        selectedValue: controller.qualification.value.isEmpty
                            ? null
                            : controller.qualification.value,
                        hintText:AppStrings.selectQualification,
                        onChanged: (val) {
                          controller.qualification.value = val ?? '';
                          controller.validate();
                        },
                        displayValue: (item) => item,
                    title: AppStrings.education,

                  )),

                  SizedBox(height: SizeConfig.size20),

                  CommonTextField(
                    title: AppStrings.schoolCollegeName,
                    textEditController: controller.schoolController,
                    hintText:AppStrings.schoolCollegeHint,
                    fontSize: SizeConfig.small,
                  ),

                  SizedBox(height: SizeConfig.size18),

                  CommonTextField(
                    title:AppStrings.boardName,
                    textEditController: controller.boardController,
                    hintText:AppStrings.boardNameHint,
                    fontSize: SizeConfig.small,
                  ),

                  SizedBox(height: SizeConfig.size18),

                  CommonTextField(
                    title:AppStrings.passingYear,
                    textEditController: controller.yearController,
                    inputLength: 4,
                    hintText:AppStrings.passingYearHint,
                    fontSize: SizeConfig.small,
                    keyBoardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size18),

                  CommonTextField(
                    title: AppStrings.performanceScore,
                    textEditController: controller.scoreController,
                    hintText:AppStrings.performanceScoreHint,
                    fontSize: SizeConfig.small,
                    keyBoardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                      _MaxValueInputFormatter(100),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size30),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => CustomBtn(
                              title: controller.editingId.value == null
                                  ? AppStrings.save
                                  : AppStrings.update,
                              isValidate: controller.isFormValid.value,
                              onTap: controller.isFormValid.value
                                  ? () async {
                                      Map<String, dynamic> params = {
                                        "highestQualification": controller
                                            .qualification.value
                                            .trim(),
                                        "schoolOrCollegeName":
                                            controller.school.value.trim(),
                                        "boardName":
                                            controller.board.value.trim(),
                                        "passingYear": int.tryParse(
                                                controller.year.value.trim()) ??
                                            0,
                                        "percentage": controller.score.value
                                                .trim()
                                                .endsWith('%')
                                            ? controller.score.value.trim()
                                            : controller.score.value.trim() +
                                                '%',
                                      };

                                      await controller.saveEducation(params);
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
    );
  }
}

// Helper input formatter for max value 100
class _MaxValueInputFormatter extends TextInputFormatter {
  final int max;
  _MaxValueInputFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final int? value = int.tryParse(newValue.text);
    if (value == null || value > max) {
      return oldValue;
    }
    return newValue;
  }
}
