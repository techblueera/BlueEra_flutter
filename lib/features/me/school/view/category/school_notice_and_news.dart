import 'dart:io';
import 'package:BlueEra/core/api/model/notice_news_model.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/notice_news_controller.dart';
import 'package:BlueEra/features/me/school/view/common_ai_genereted_button.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';
import '../../../../../core/constants/app_strings.dart';

class SchoolNoticeAndNews extends StatefulWidget {
  const SchoolNoticeAndNews({super.key, this.isEdit = false, this.newsData});

  final bool isEdit;
  final NoticeNewsData? newsData;

  @override
  State<SchoolNoticeAndNews> createState() => _SchoolNoticeAndNewsState();
}

class _SchoolNoticeAndNewsState extends State<SchoolNoticeAndNews> {
  final noticeController = Get.find<NoticeController>();
  final titleEditController = TextEditingController();
  final descriptionEditController = TextEditingController();

  @override
  void initState() {
    descriptionEditController.addListener(_runValidation);

    if (widget.isEdit) {
      // Current Values
      noticeController.initialNoticeImageUrl =
          widget.newsData?.uploadPhoto ?? "";
      noticeController.notice_news_titleText.value =
          widget.newsData?.title ?? "";
      noticeController.notice_news_messageText.value =
          widget.newsData?.description ?? "";

      // Store Original Values for Comparison
      noticeController.originalImageUrl.value =
          widget.newsData?.uploadPhoto ?? "";
      noticeController.originalTitle.value = widget.newsData?.title ?? "";
      noticeController.originalDescription.value =
          widget.newsData?.description ?? "";

      titleEditController.text = widget.newsData?.title ?? "";
      descriptionEditController.text = widget.newsData?.description ?? "";
    } else {
      noticeController.noticeImageFile.value = null;
      noticeController.isFormValid.value = false;
      noticeController.originalImageUrl.value = "";
      noticeController.initialNoticeImageUrl = "";
      noticeController.notice_news_titleText.value = "";
      noticeController.notice_news_messageText.value = "";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title:AppStrings.noticesNews,
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
                    AppStrings.uploadPhotos,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _buildImageSection(),
                  SizedBox(height: SizeConfig.size20),
                  CommonTextField(
                    textEditController: titleEditController,
                    hintText: "E.g. How do you commute to work?",
                    title: AppStrings.title,
                    isValidate: false,
                    onChange: (value) {
                      noticeController.notice_news_titleText.value = value;
                      _runValidation();
                    },
                  ),
                  SizedBox(height: SizeConfig.size20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.description,
                      ),
                      // The Reusable AI Widget
                      Obx(() {
                        return AIGeneratorButton(
                          type: AppStrings.designation,
                          data: {
                            "for": "Notice News",
                            if (noticeController
                                .notice_news_titleText.value.isNotEmpty)
                              "title":
                                  noticeController.notice_news_titleText.value,
                          },
                          onSelected: (generatedText) {
                            descriptionEditController.text = generatedText;
                            noticeController.notice_news_messageText.value =
                                generatedText;

                            _runValidation();
                          },
                        );
                      }),
                    ],
                  ),

                  /// Apply Button
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
                      String newVal =
                          value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                      noticeController.notice_news_messageText.value = newVal;
                      _runValidation();
                    },
                  ),
                  SizedBox(height: SizeConfig.size10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => CustomText(
                          "${noticeController.notice_news_messageText.value.length}/1000",
                          color: Colors.grey,
                          fontSize: 12,
                        )),
                  ),
                  SizedBox(height: SizeConfig.size30),
                  Obx(() => CustomBtn(
                        onTap: noticeController.isFormValid.value
                            ? () async {
                                if (widget.isEdit) {
                                  noticeController.notice_news_id.value =
                                      widget.newsData?.id ?? "";
                                  if (noticeController.noticeImageFile.value ==
                                      null) {
                                    await noticeController
                                        .updateSchoolNoticeNewsController(
                                            isPhotoUpdate: false);
                                  } else {
                                    await noticeController.uploadNewsDocDocInit(
                                        isEdit: true);
                                  }
                                } else {
                                  await noticeController.uploadNewsDocDocInit();
                                }
                              }
                            : null,
                        title: AppStrings.submit,
                        // Pass the validation state to change button color/opacity
                        isValidate: noticeController.isFormValid.value,
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
    if (noticeController.noticeImageFile.value != null) {
      return CommonImageUploadTile(
        imageFile: noticeController.noticeImageFile,
        onImageRemove: () {
          noticeController.noticeImageFile.value = null;
          noticeController.initialNoticeImageUrl = "";

          _runValidation();
          setState(() {});
        },
        title: '',
        context: context,
      );
    }
    // If no local file but we have a NETWORK image from API
    else if (noticeController.initialNoticeImageUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              noticeController.initialNoticeImageUrl,
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
                  noticeController.noticeImageFile.value = null;

                  noticeController.initialNoticeImageUrl = "";
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
      title:AppStrings.uploadPhotos,
      context: context,
      onImageSelected: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
        if (path != null) {
          noticeController.noticeImageFile.value = File(path);
          noticeController.initialNoticeImageUrl = path;
          _runValidation();
        }
      },
      onImageRemove: () {
        // Clear initial URL to show "Change" happened
        noticeController.noticeImageFile.value = null;

        noticeController.initialNoticeImageUrl = "";
        _runValidation();
        setState(() {}); //
      },
      imageFile: noticeController.noticeImageFile,
    );
  }

// Helper to trigger validation
  void _runValidation() {
    // 1. Run your standard validation (e.g., checking if description is empty)
    noticeController.noticesNewsValidateForm(
        noticeDescription: noticeController.notice_news_messageText.value,
        uploadPhoto: noticeController.initialNoticeImageUrl);

    // 2. If in edit mode, add the 'Has Changed' requirement
    if (widget.isEdit) {
      bool changed = noticeController.hasChanges();
      // Update the controller's valid state based on both rules
      noticeController.isFormValid.value =
          noticeController.isFormValid.value && changed;
    }
  }
}
