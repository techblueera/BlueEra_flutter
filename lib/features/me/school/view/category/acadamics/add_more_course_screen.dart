import 'package:BlueEra/core/api/model/school_course_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/course_controller.dart';
import 'package:BlueEra/features/me/school/view/common_ai_genereted_button.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AddMoreCourseScreen extends StatefulWidget {
  final bool isEdit;
  final SchoolCourseData?
      courseData; // Passing the model from your previous JSON

  AddMoreCourseScreen({super.key, this.isEdit = false, this.courseData});

  @override
  State<AddMoreCourseScreen> createState() => _AddMoreCourseScreenState();
}

class _AddMoreCourseScreenState extends State<AddMoreCourseScreen> {
  final courseController = Get.find<CourseController>();

  final courseNameEditController = TextEditingController();

  final admissionProcessEditController = TextEditingController();

  final eligibilityEditController = TextEditingController();

  final courseFeeEditController = TextEditingController();

  final courseDurationEditController = TextEditingController();

  final descriptionEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Listeners for all controllers to trigger validation
    [
      courseNameEditController,
      admissionProcessEditController,
      eligibilityEditController,
      courseFeeEditController,
      courseDurationEditController,
      descriptionEditController
    ].forEach((controller) => controller.addListener(_runValidation));
  }

  void _initializeData() {
    if (widget.isEdit && widget.courseData != null) {
      final data = widget.courseData!;

      // Determine fee type and value from API response
      String feeVal = "";
      if (data.courseFees?.monthly != null && data.courseFees!.monthly! > 0) {
        courseController.feeType.value = "Monthly";
        feeVal = data.courseFees!.monthly.toString();
      } else {
        courseController.feeType.value = "Yearly";
        feeVal = data.courseFees?.yearly.toString() ?? "";
      }

      // Populate TextFields
      courseNameEditController.text = data.name ?? "";
      admissionProcessEditController.text = data.admissionProcess ?? "";
      eligibilityEditController.text = data.eligibility ?? "";
      courseFeeEditController.text = feeVal;
      courseDurationEditController.text = data.duration ?? "";
      descriptionEditController.text = data.description ?? "";
      courseController.courseDescriptionText.value = data.description ?? "";
      // Save snapshot for comparison
      courseController.originalCourseData = {
        'name': data.name,
        'admissionProcess': data.admissionProcess,
        'eligibility': data.eligibility,
        'feeValue': feeVal,
        'feeType': courseController.feeType.value,
        'duration': data.duration,
        'description': data.description,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShowMoreInfoIcon: true,
        title: "Add More Course",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: CommonCardWidget(
          child: SingleChildScrollView(
            child: Column(
              children: [
                CommonTextField(
                  textEditController: courseNameEditController,
                  hintText: "E.g. B.Sc. Geography Honours....",
                  title: "Course Name",
                  maxLength: 100,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: admissionProcessEditController,
                  hintText: "E.g. Direct Admission ",
                  title: "Admission Process",
                  maxLength: 50,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: eligibilityEditController,
                  hintText: "E.g. 10th Pass",
                  title: "Eligibility",
                  maxLength: 30,
                  // onChange is another way to trigger validation
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                // Radio buttons with Obx to update UI immediately
                Obx(() => Row(
                      children: [
                        CustomText(
                          'Course Fee',
                        ),
                        Radio<String>(
                          value: 'Monthly',
                          groupValue: courseController.feeType.value,
                          onChanged: (val) {
                            courseController.setFeeType(val);
                            _runValidation();
                          },
                        ),
                        const CustomText("Monthly"),
                        Radio<String>(
                          value: 'Yearly',
                          groupValue: courseController.feeType.value,
                          onChanged: (val) {
                            courseController.setFeeType(val);
                            _runValidation();
                          },
                        ),
                        const CustomText("Yearly"),
                      ],
                    )),

                SizedBox(height: SizeConfig.paddingXSL),
                CommonTextField(
                  title: '',
                  textEditController: courseFeeEditController,
                  hintText: "E.g. ₹90,000",
                  keyBoardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: courseDurationEditController,
                  hintText: "E.g. 4 Years",
                  title: "Course Duration",
                  maxLength: 15,

                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      AppStrings.description,
                    ),
                    // The Reusable AI Widget
                    Obx(() {
                      return AIGeneratorButton(
                        type: "Course",
                        data: {
                          "course_name": courseNameEditController.text,
                          "admission_process":
                              admissionProcessEditController.text,
                          "eligibility": eligibilityEditController.text,
                          "admission_process": courseController.feeType.value,
                          "course_fee": courseFeeEditController.text,
                          "course_duration": courseDurationEditController.text
                        },
                        onSelected: (generatedText) {
                          descriptionEditController.text = generatedText;
                          courseController.courseDescriptionText.value =
                              generatedText;
                          _runValidation();
                        },
                      );
                    }),
                  ],
                ),
                CommonTextField(
                  textEditController: descriptionEditController,
                  title: "",
                  hintText:
                      "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  maxLine: 5,
                  maxLength: 1000,
                  isValidate: false,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChange: (value) {
                    String newVal = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                    courseController.courseDescriptionText.value = newVal;
                    _runValidation();
                  },
                ),
                SizedBox(height: SizeConfig.paddingXSL),

                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => CustomText(
                        "${courseController.courseDescriptionText.value.length}/1000",
                        color: Colors.grey,
                        fontSize: 12,
                      )),
                ),
                SizedBox(height: SizeConfig.paddingM),

                // Inside the Obx for CustomBtn in AddMoreCourseScreen
                Obx(() => CustomBtn(
                      onTap: courseController.isFormValid.value
                          ? () => courseController.submitCourse(
                                // Extract text from controllers to pass to the method
                                name: courseNameEditController.text,
                                admission: admissionProcessEditController.text,
                                eligibility: eligibilityEditController.text,
                                feeValue: courseFeeEditController.text,
                                duration: courseDurationEditController.text,
                                isEdit: widget.isEdit,
                                courseId: widget.courseData?.id,
                              )
                          : null,
                      title: widget.isEdit ? AppStrings.update : AppStrings.add,
                      isValidate: courseController.isFormValid.value,
                    )),
                SizedBox(height: SizeConfig.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper to trigger validation
  void _runValidation() {
    courseController.courseValidateForm(
      courseName: courseNameEditController.text,
      courseDuration: courseDurationEditController.text,
      courseFee: courseFeeEditController.text,
      eligibility: eligibilityEditController.text,
      admissionProcess: admissionProcessEditController.text,
      description: descriptionEditController.text,
    );
    setState(() {

    });
  }
}
