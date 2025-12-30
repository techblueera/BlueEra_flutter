import 'dart:io';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';
import '../../../../../core/constants/app_strings.dart';

class SchoolNoticeAndNews extends StatefulWidget {
  const SchoolNoticeAndNews({super.key});

  @override
  State<SchoolNoticeAndNews> createState() => _SchoolNoticeAndNewsState();
}

class _SchoolNoticeAndNewsState extends State<SchoolNoticeAndNews> {
  final aboutUsController = Get.find<SchoolController>();
  final titleEditController = TextEditingController();
  final descriptionEditController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    descriptionEditController.addListener(_runValidation);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Notices & News",
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
                    "Upload Photo",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  CommonImageUploadTile(
                    title: "Upload Photo",
                    imageFile: aboutUsController.noticeNewsImageFile,
                    context: context,
                    onImageSelected: () async {
                      final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                      if (selectedPath != null) {
                        aboutUsController.noticeNewsImageFile.value =
                            File(selectedPath);
                      }
                      _runValidation();
                    },
                    onImageRemove: () {
                      aboutUsController.noticeNewsImageFile.value = null;
                      _runValidation();
                    },
                  ),
                  SizedBox(height: SizeConfig.size20),
                  CommonTextField(
                    textEditController: titleEditController,
                    hintText: "E.g. How do you commute to work?",
                    title: "Title (Optional)",
                    isValidate: false,
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
                      aboutUsController.notice_news_messageText.value = newVal;
                      _runValidation();
                    },
                  ),
                  SizedBox(height: SizeConfig.size10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => CustomText(
                          "${aboutUsController.notice_news_messageText.value.length}/1000",
                          color: Colors.grey,
                          fontSize: 12,
                        )),
                  ),
                  SizedBox(height: SizeConfig.size30),
                  Obx(() => CustomBtn(
                        onTap:
                            aboutUsController.isFormValid.value ? () {} : null,
                        title: AppStrings.submit,
                        // Pass the validation state to change button color/opacity
                        isValidate: aboutUsController.isFormValid.value,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper to trigger validation
  void _runValidation() {
    aboutUsController.noticesNewsValidateForm(
        noticeDescription: descriptionEditController.text,
        uploadPhoto: aboutUsController.noticeNewsImageFile.value?.path ?? "");
  }
}
