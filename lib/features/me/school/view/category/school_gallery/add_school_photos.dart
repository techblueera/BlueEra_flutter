import 'dart:io';

import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';

class AddSchoolPhotos extends StatefulWidget {
  const AddSchoolPhotos({super.key});

  @override
  State<AddSchoolPhotos> createState() => _AddSchoolPhotosState();
}

class _AddSchoolPhotosState extends State<AddSchoolPhotos> {
  final aboutUsController = Get.find<SchoolController>();
  final titleEditController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    titleEditController.addListener(_runValidation);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add Photo",
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
                  CommonTextField(
                    textEditController: titleEditController,
                    hintText: "E.g. How do you commute to work?",
                    title: "Title",
                    onChange: (va) => _runValidation(),
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
                    imageFile: aboutUsController.noticeNewsImageFile,
                    context: context,
                    onImageRemove: () {
                      aboutUsController.noticeNewsImageFile.value =
                          null; // remove image
                      _runValidation();
                    },
                    onImageSelected: () async {
                      final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                      if (selectedPath != null) {
                        aboutUsController.noticeNewsImageFile.value =
                            File(selectedPath);
                        _runValidation();
                      }
                    },
                  ),
                  SizedBox(height: SizeConfig.size30),
                  Obx(() => CustomBtn(
                        onTap:
                            aboutUsController.isFormValid.value ? () {} : null,
                        title: AppStrings.add,
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
    aboutUsController.addPhotosValidateForm(
        uploadPhoto: aboutUsController.noticeNewsImageFile.value?.path ?? "",
        title: titleEditController.text);
  }
}
