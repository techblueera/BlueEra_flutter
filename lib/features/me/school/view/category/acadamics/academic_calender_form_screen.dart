import 'dart:io';
import 'package:BlueEra/core/api/model/academic_calender_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/academic_calender_controller.dart';
import 'package:BlueEra/features/me/school/controller/pdf_picker_controller.dart';
import 'package:BlueEra/features/me/school/view/common_ai_genereted_button.dart';
import 'package:BlueEra/features/me/school/view/pdf_picker_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';

class AcademicCalenderFormScreen extends StatefulWidget {
  const AcademicCalenderFormScreen(
      {super.key, this.isEdit = false, this.newsData});

  final bool isEdit;
  final AcademicCalenderData? newsData;

  @override
  State<AcademicCalenderFormScreen> createState() =>
      _AcademicCalenderFormScreenState();
}

class _AcademicCalenderFormScreenState
    extends State<AcademicCalenderFormScreen> {
  final academicCalenderController = Get.find<AcademicCalenderController>();
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
      academicCalenderController.initialNoticeImageUrl =
          widget.newsData?.uploadPhoto ?? "";
      academicCalenderController.notice_news_titleText.value =
          widget.newsData?.title ?? "";
      academicCalenderController.notice_news_messageText.value =
          widget.newsData?.description ?? "";

      // Store Original Values for Comparison
      academicCalenderController.originalImageUrl.value =
          widget.newsData?.uploadPhoto ?? "";
      academicCalenderController.originalTitle.value =
          widget.newsData?.title ?? "";
      academicCalenderController.originalDescription.value =
          widget.newsData?.description ?? "";

      titleEditController.text = widget.newsData?.title ?? "";
      descriptionEditController.text = widget.newsData?.description ?? "";
    } else {
      academicCalenderController.noticeImageFile.value = null;
      academicCalenderController.isFormValid.value = false;
      academicCalenderController.originalImageUrl.value = "";
      academicCalenderController.initialNoticeImageUrl = "";
      academicCalenderController.notice_news_titleText.value = "";
      academicCalenderController.notice_news_messageText.value = "";
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
                    return (academicCalenderController.docUploadName.value ==
                            "")
                        ? Row(
                            children: [
                              Expanded(child: _buildImageSection()),
                              SizedBox(width: SizeConfig.size10),
                              Expanded(child: SinglePdfPreviewWidget()),
                            ],
                          )
                        : Row(
                            children: [
                              if (academicCalenderController
                                      .docUploadName.value ==
                                  "photo")
                                Expanded(child: _buildImageSection()),
                              SizedBox(width: SizeConfig.size10),
                              if (academicCalenderController
                                      .docUploadName.value ==
                                  "pdf")
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
                      academicCalenderController.notice_news_titleText.value =
                          value;
                      _runValidation();
                    },
                  ),
                  SizedBox(height: SizeConfig.size20),

                  /// Apply Button

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.description,
                      ),
                      // The Reusable AI Widget
                      Obx(() {
                        return AIGeneratorButton(
                          type: "Academic Calender",
                          data: {
                            "for": "academic_calender",
                            if (academicCalenderController
                                .notice_news_titleText.value.isNotEmpty)
                              "title": academicCalenderController
                                  .notice_news_titleText.value,
                          },
                          onSelected: (generatedText) {
                            descriptionEditController.text = generatedText;
                            academicCalenderController
                                .notice_news_messageText.value = generatedText;
                            _runValidation();
                          },
                        );
                      }),
                    ],
                  ),

                  CommonTextField(
                    textEditController: descriptionEditController,
                    title:"",
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
                      academicCalenderController.notice_news_messageText.value =
                          newVal;
                      _runValidation();
                    },
                  ),
                  SizedBox(height: SizeConfig.size10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => CustomText(
                          "${academicCalenderController.notice_news_messageText.value.length}/1000",
                          color: Colors.grey,
                          fontSize: 12,
                        )),
                  ),
                  SizedBox(height: SizeConfig.size30),
                  Obx(() => CustomBtn(
                        onTap: academicCalenderController.isFormValid.value
                            ? () async {
                                if (widget.isEdit) {
                                  academicCalenderController.notice_news_id
                                      .value = widget.newsData?.id ?? "";
                                  if (academicCalenderController
                                          .noticeImageFile.value ==
                                      null) {
                                    await academicCalenderController
                                        .updateAcademicCalenderController(
                                            isPhotoUpdate: false);
                                  } else {
                                    await academicCalenderController
                                        .updateAcademicCalenderController(
                                            isPhotoUpdate: true);
                                  }
                                } else {
                                  await academicCalenderController
                                      .addAcademicCalenderController();
                                }
                              }
                            : null,
                        title: AppStrings.submit,
                        // Pass the validation state to change button color/opacity
                        isValidate:
                            academicCalenderController.isFormValid.value,
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
    if (academicCalenderController.noticeImageFile.value != null) {
      return CommonImageUploadTile(
        imageFile: academicCalenderController.noticeImageFile,
        onImageRemove: () {
          academicCalenderController.noticeImageFile.value = null;
          academicCalenderController.initialNoticeImageUrl = "";
          academicCalenderController.docUploadName.value = "";

          _runValidation();
          setState(() {});
        },
        title: '',
        context: context,
      );
    }
    // If no local file but we have a NETWORK image from API
    else if (academicCalenderController.initialNoticeImageUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              academicCalenderController.initialNoticeImageUrl,
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
                  academicCalenderController.noticeImageFile.value = null;

                  academicCalenderController.initialNoticeImageUrl = "";
                  academicCalenderController.docUploadName.value = "";

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
          academicCalenderController.noticeImageFile.value = File(path);
          academicCalenderController.initialNoticeImageUrl = path;
          academicCalenderController.docUploadName.value = "photo";

          _runValidation();
        }
      },
      onImageRemove: () {
        // Clear initial URL to show "Change" happened
        academicCalenderController.noticeImageFile.value = null;

        academicCalenderController.initialNoticeImageUrl = "";
        _runValidation();
        setState(() {}); //
      },
      imageFile: academicCalenderController.noticeImageFile,
    );
  }

// Helper to trigger validation
  void _runValidation() {
    // 1. Run your standard validation (e.g., checking if description is empty)
    academicCalenderController.noticesNewsValidateForm(
        noticeDescription:
            academicCalenderController.notice_news_messageText.value ?? "",
        uploadPhoto: academicCalenderController.initialNoticeImageUrl);

    // 2. If in edit mode, add the 'Has Changed' requirement
    if (widget.isEdit) {
      bool changed = academicCalenderController.hasChanges();
      // Update the controller's valid state based on both rules
      academicCalenderController.isFormValid.value =
          academicCalenderController.isFormValid.value && changed;
    }
  }
}
