import 'dart:io';
import 'package:BlueEra/core/api/model/academic_calender_res_model.dart';
import 'package:BlueEra/core/api/model/student_corner_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/academic_calender_controller.dart';
import 'package:BlueEra/features/me/school/controller/pdf_picker_controller.dart';
import 'package:BlueEra/features/me/school/controller/student_corder_controller.dart';
import 'package:BlueEra/features/me/school/view/pdf_picker_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';

class CommonStudentCornerFormScreen extends StatefulWidget {
  const CommonStudentCornerFormScreen(
      {super.key, this.isEdit = false, this.studentItem});

  final bool isEdit;
  final StudentCornerItem? studentItem;

  @override
  State<CommonStudentCornerFormScreen> createState() =>
      _CommonStudentCornerFormScreenState();
}

class _CommonStudentCornerFormScreenState
    extends State<CommonStudentCornerFormScreen> {
  final studentController = Get.find<StudentCornerController>();
  final titleEditController = TextEditingController();
  final descriptionEditController = TextEditingController();
  late PdfPickerController pdfPickerController;

  @override
  void initState() {
    descriptionEditController.addListener(_runValidation);
    pdfPickerController = Get.isRegistered<PdfPickerController>()
        ? Get.find<PdfPickerController>()
        : Get.put(PdfPickerController());
    if (widget.isEdit) {
      // Current Values
      studentController.initialNoticeImageUrl =
          widget.studentItem?.uploadPhoto ?? "";
      studentController.notice_news_titleText.value =
          widget.studentItem?.title ?? "";
      studentController.notice_news_messageText.value =
          widget.studentItem?.description ?? "";

      // Store Original Values for Comparison
      studentController.originalImageUrl.value =
          widget.studentItem?.uploadPhoto ?? "";
      studentController.originalTitle.value = widget.studentItem?.title ?? "";
      studentController.originalDescription.value =
          widget.studentItem?.description ?? "";

      titleEditController.text = widget.studentItem?.title ?? "";
      descriptionEditController.text = widget.studentItem?.description ?? "";
    } else {
      studentController.noticeImageFile.value = null;
      studentController.isFormValid.value = false;
      studentController.originalImageUrl.value = "";
      studentController.initialNoticeImageUrl = "";
      studentController.notice_news_titleText.value = "";
      studentController.notice_news_messageText.value = "";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Academic Calender",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.whiteE5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Upload Doc",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  Obx(() {
                    return (studentController.docUploadName.value == "")
                        ? Row(
                            children: [
                              Expanded(child: _buildImageSection()),
                              SizedBox(width: SizeConfig.size10),
                              Expanded(child: SinglePdfPreviewWidget()),
                            ],
                          )
                        : Row(
                            children: [
                              if (studentController.docUploadName.value ==
                                  "photo")
                                Expanded(child: _buildImageSection()),
                              SizedBox(width: SizeConfig.size10),
                              if (studentController.docUploadName.value == "pdf")
                                Expanded(child: SinglePdfPreviewWidget()),
                            ],
                          );
                  }),
                  SizedBox(height: SizeConfig.size20),
                  CommonTextField(
                    textEditController: titleEditController,
                    hintText: "E.g. How do you commute to work?",
                    title: "Title (Optional)",
                    isValidate: false,
                    onChange: (value) {
                      studentController.notice_news_titleText.value = value;
                      _runValidation();
                    },
                  ),
                  SizedBox(height: SizeConfig.size20),

                  /// Apply Button
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
                      String newVal =
                          value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                      studentController.notice_news_messageText.value = newVal;
                      _runValidation();
                    },
                  ),
                  SizedBox(height: SizeConfig.size10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => CustomText(
                          "${studentController.notice_news_messageText.value.length}/1000",
                          color: Colors.grey,
                          fontSize: 12,
                        )),
                  ),
                  SizedBox(height: SizeConfig.size30),
                  Obx(() => CustomBtn(
                        onTap: studentController.isFormValid.value
                            ? () async {
                                // if (widget.isEdit) {
                                //   studentController.notice_news_id.value =
                                //       widget.newsData?.id ?? "";
                                //   if (studentController.noticeImageFile.value ==
                                //       null) {
                                //     await studentController
                                //         .updateAcademicCalenderController(
                                //             isPhotoUpdate: false);
                                //   } else {
                                //     await studentController
                                //         .updateAcademicCalenderController(
                                //             isPhotoUpdate: true);
                                //   }
                                // } else {
                                //   await studentController
                                //       .addAcademicCalenderController();
                                // }
                              }
                            : null,
                        title: AppStrings.submit,
                        // Pass the validation state to change button color/opacity
                        isValidate: studentController.isFormValid.value,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    // If user picked a NEW local file
    if (studentController.noticeImageFile.value != null) {
      return CommonImageUploadTile(
        imageFile: studentController.noticeImageFile,
        onImageRemove: () {
          studentController.noticeImageFile.value = null;
          studentController.initialNoticeImageUrl = "";
          studentController.docUploadName.value = "";

          _runValidation();
          setState(() {});
        },
        title: '',
        context: context,
      );
    }
    // If no local file but we have a NETWORK image from API
    else if (studentController.initialNoticeImageUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              studentController.initialNoticeImageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: CircleAvatar(
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  // Clear initial URL to show "Change" happened
                  studentController.noticeImageFile.value = null;

                  studentController.initialNoticeImageUrl = "";
                  studentController.docUploadName.value = "";

                  _runValidation();
                  setState(
                      () {}); // Refresh local UI to show upload placeholder
                },
              ),
            ),
          )
        ],
      );
    }
    // Default: Show Upload Placeholder
    return CommonImageUploadTile(
      title: "Upload Image",
      context: context,
      onImageSelected: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
        if (path != null) {
          studentController.noticeImageFile.value = File(path);
          studentController.initialNoticeImageUrl = path;
          studentController.docUploadName.value = "photo";

          _runValidation();
        }
      },
      onImageRemove: () {
        // Clear initial URL to show "Change" happened
        studentController.noticeImageFile.value = null;

        studentController.initialNoticeImageUrl = "";
        _runValidation();
        setState(() {}); //
      },
      imageFile: studentController.noticeImageFile,
    );
  }

// Helper to trigger validation
  void _runValidation() {
    // 1. Run your standard validation (e.g., checking if description is empty)
    studentController.noticesNewsValidateForm(
        noticeDescription: studentController.notice_news_messageText.value ?? "",
        uploadPhoto: studentController.initialNoticeImageUrl);

    // 2. If in edit mode, add the 'Has Changed' requirement
    if (widget.isEdit) {
      bool changed = studentController.hasChanges();
      // Update the controller's valid state based on both rules
      studentController.isFormValid.value =
          studentController.isFormValid.value && changed;
    }
  }
}
