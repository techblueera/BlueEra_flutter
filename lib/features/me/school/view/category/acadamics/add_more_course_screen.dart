import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AddMoreCourseScreen extends StatefulWidget {
  AddMoreCourseScreen({super.key});

  @override
  State<AddMoreCourseScreen> createState() => _AddMoreCourseScreenState();
}

class _AddMoreCourseScreenState extends State<AddMoreCourseScreen> {
  final aboutUsController = Get.find<SchoolController>();

  final courseNameEditController = TextEditingController();

  final admissionProcessEditController = TextEditingController();

  final eligibilityEditController = TextEditingController();

  final courseFeeEditController = TextEditingController();

  final courseDurationEditController = TextEditingController();

  final descriptionEditController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    courseNameEditController.addListener(_runValidation);
    admissionProcessEditController.addListener(_runValidation);
    eligibilityEditController.addListener(_runValidation);
    courseFeeEditController.addListener(_runValidation);
    courseDurationEditController.addListener(_runValidation);
    descriptionEditController.addListener(_runValidation);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
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
                Row(
                  children: [
                    CustomText(
                      'Course Fee',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    Container(
                      height: 30,
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'Monthly',
                            groupValue: aboutUsController.feeType.value,
                            onChanged: aboutUsController.setFeeType,
                            activeColor: AppColors.primaryColor,
                          ),
                          const CustomText("Monthly"),
                          Radio<String>(
                            value: 'Yearly',
                            groupValue: aboutUsController.feeType.value,
                            onChanged: aboutUsController.setFeeType,
                            activeColor: AppColors.primaryColor,
                          ),
                          const CustomText("Yearly"),
                        ],
                      ),
                    )
                  ],
                ),
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
                  maxLength: 30,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: descriptionEditController,
                  title: AppStrings.description,
                  hintText:
                      "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  maxLine: 5,
                  maxLength: 1000,
                  isValidate: false,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChange: (value) {
                    String newVal = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                    aboutUsController.courseDescriptionText.value = newVal;
                    _runValidation();
                  },
                ),
                SizedBox(height: SizeConfig.paddingXSL),

                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => CustomText(
                        "${aboutUsController.courseDescriptionText.value.length}/1000",
                        color: Colors.grey,
                        fontSize: 12,
                      )),
                ),
                SizedBox(height: SizeConfig.paddingM),

                // THE BUTTON
                Obx(() => CustomBtn(
                      onTap: aboutUsController.isFormValid.value ? () {} : null,
                      title: AppStrings.add,
                      // Pass the validation state to change button color/opacity
                      isValidate: aboutUsController.isFormValid.value,
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
    aboutUsController.courseValidateForm(
      courseName: courseNameEditController.text,
      courseDuration: courseDurationEditController.text,
      courseFee: courseFeeEditController.text,
      eligibility: eligibilityEditController.text,
      admissionProcess: admissionProcessEditController.text,
      description: descriptionEditController.text,
    );
  }
}
