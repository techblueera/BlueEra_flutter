import 'dart:io';

import 'package:BlueEra/core/api/model/school_course_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
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
  final courseController = Get.isRegistered<CourseController>()
      ? Get.find<CourseController>()
      : Get.put(CourseController());

  final courseNameEditController = TextEditingController();

  final admissionProcessEditController = TextEditingController();

  final eligibilityEditController = TextEditingController();

  final courseFeeEditController = TextEditingController();

  final courseDurationEditController = TextEditingController();

  final descriptionEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset image state for a fresh form; edit mode re-hydrates below.
    courseController.courseImageFile.value = null;
    courseController.courseImageUrl.value = '';
    courseController.isImageUpdated.value = false;

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
      courseController.courseImageUrl.value = data.image ?? "";
      // Save snapshot for comparison
      courseController.originalCourseData = {
        'name': data.name,
        'admissionProcess': data.admissionProcess,
        'eligibility': data.eligibility,
        'feeValue': feeVal,
        'feeType': courseController.feeType.value,
        'duration': data.duration,
        'description': data.description,
        'image': data.image,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShowMoreInfoIcon: true,
        title: AppStrings.addMoreCourse,
        isShadowShow: false,
      ),
      body: SafeArea(
        child: CommonCardWidget(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ///UPLOAD COURSE BANNER....
                _buildBannerUpload(),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: courseNameEditController,
                  hintText: "E.g. B.Sc. Geography Honours....",
                  title: AppStrings.courseName,
                  maxLength: 100,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: admissionProcessEditController,
                  hintText: "E.g. Direct Admission ",
                  title: AppStrings.admission,
                  maxLength: 50,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: eligibilityEditController,
                  hintText: "E.g. 10th Pass",
                  title: AppStrings.eligibility,
                  maxLength: 30,
                  // onChange is another way to trigger validation
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                // Radio buttons with Obx to update UI immediately
                Obx(() => RadioGroup<String>(
                      groupValue: courseController.feeType.value,
                      onChanged: (val) {
                        courseController.setFeeType(val);
                        _runValidation();
                      },
                      child: Row(
                        children: [
                          CustomText(
                            AppStrings.courseFee,
                          ),
                          Radio<String>(
                            value: 'Monthly',
                          ),
                          const CustomText(AppStrings.monthly),
                          Radio<String>(
                            value: 'Yearly',
                          ),
                          CustomText(AppStrings.years),
                        ],
                      ),
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
                  title: AppStrings.courseDuration,
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
                      "Hello Everyone @India User Now I am Using https://beapp.in It’s Amazing, I suggest to Join Me.",
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
    setState(() {});
  }

  Widget _buildBannerUpload() {
    return Obx(() {
      final localFile = courseController.courseImageFile.value;
      final networkUrl = courseController.courseImageUrl.value;
      final hasImage = localFile != null ||
          (networkUrl.isNotEmpty && networkUrl.startsWith('http'));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "Upload Course Banner",
            fontWeight: FontWeight.w600,
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          if (hasImage)
            _buildBannerPreview(localFile, networkUrl)
          else
            _buildBannerPlaceholder(),
        ],
      );
    });
  }

  Widget _buildBannerPlaceholder() {
    return InkWell(
      onTap: _pickBannerImage,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: SizeConfig.paddingXL),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xffDDE2EE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined, color: AppColors.grey7E, size: 20),
            const SizedBox(width: 8),
            CustomText(
              "Upload Photo",
              color: AppColors.grey7E,
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.medium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPreview(File? localFile, String networkUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 160,
            child: localFile != null
                ? Image.file(localFile, fit: BoxFit.cover)
                : Image.network(
                    networkUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () {
                courseController.courseImageFile.value = null;
                courseController.courseImageUrl.value = '';
                courseController.isImageUpdated.value = false;
                _runValidation();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: InkWell(
              onTap: _pickBannerImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 12, color: AppColors.white),
                    const SizedBox(width: 4),
                    CustomText(
                      "Change",
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBannerImage() async {
    final path = await CommonProfileImageUpload.pickImage(context: context);
    if (path != null) {
      courseController.courseImageFile.value = File(path);
      courseController.courseImageUrl.value = path;
      courseController.isImageUpdated.value = true;
      _runValidation();
    }
  }
}
