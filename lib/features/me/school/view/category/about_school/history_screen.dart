import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final aboutUsController = Get.find<SchoolController>();
  final descriptionEditController = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    aboutUsController.isFormValid.value=false;

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "History",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// Course Card
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
                  /// Apply Button
                  CommonTextField(
                    textEditController: descriptionEditController,
                    title: "Our History",
                    hintText:
                        "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                    maxLine: 5,
                    maxLength: 3000,
                    isValidate: false,
                    keyBoardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onChange: (value) {
                      String newVal =
                          value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                      aboutUsController.historyText.value = newVal;
                      _runValidation();
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => CustomText(
                          "${aboutUsController.historyText.value.length}/3000",
                          color: Colors.grey,
                          fontSize: 12,
                        )),
                  ),
                  SizedBox(height: SizeConfig.size20),
                  CustomText(
                    "Upload Photo",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  CommonImageUploadTile(
                    title: "Upload Photo",
                    imageFile: aboutUsController.historyImageFile,
                    context: context,
                    onImageRemove: () {
                      aboutUsController.historyImageFile.value = null;
                      _runValidation();
                    },
                    onImageSelected: () async {
                      final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                      if (selectedPath != null) {
                        aboutUsController.historyImageFile.value =
                            File(selectedPath);
                      }
                      _runValidation();
                    },
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
        uploadPhoto: aboutUsController.historyImageFile.value?.path ?? "");
  }
}
