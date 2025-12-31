import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/school_about_us_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
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
  final schoolAboutUsController = Get.find<SchoolAboutUsController>();
  final descriptionEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    schoolAboutUsController.isFormValid.value = false;
    schoolAboutUsController.getSchoolAboutUsController();

    // Listen for data load
    once(schoolAboutUsController.aboutUsData!, (AboutUsData? data) {
      if (data != null) {
        // Set Initial Values for Comparison
        schoolAboutUsController.initialHistoryText = data.history ?? "";
        schoolAboutUsController.initialHistoryImageUrl = "";
        // schoolAboutUsController.initialHistoryImageUrl = data.historyImage ?? "";

        // Populate UI
        descriptionEditController.text = data.history ?? "";
        schoolAboutUsController.historyText.value = data.history ?? "";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "History"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          // If still loading from API
          if (schoolAboutUsController.getAboutUsSchoolResponse.value.status ==
              Status.LOADING) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Container(
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
                      textEditController: descriptionEditController,
                      title: "Our History",
                      maxLine: 5,
                      onChange: (value) {
                        schoolAboutUsController.historyText.value = value;
                        schoolAboutUsController.validateHistoryForm();
                      },
                    ),

                    // Display character count
                    Align(
                      alignment: Alignment.centerRight,
                      child: CustomText(
                          "${schoolAboutUsController.historyText.value.length}/3000",
                          color: Colors.grey,
                          fontSize: 12),
                    ),

                    SizedBox(height: SizeConfig.size20),
                    CustomText("Upload Photo"),
                    SizedBox(height: SizeConfig.size10),

                    // Image Section: Handles Network vs Local
                    _buildImageSection(),

                    SizedBox(height: SizeConfig.size30),

                    // Submit Button
                    CustomBtn(
                      onTap: schoolAboutUsController.isFormValid.value
                          ? () => _handleSubmit()
                          : null,
                      title: AppStrings.submit,
                      isValidate: schoolAboutUsController.isFormValid.value,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildImageSection() {
    // If user picked a NEW local file
    if (schoolAboutUsController.historyImageFile.value != null) {
      return CommonImageUploadTile(
        imageFile: schoolAboutUsController.historyImageFile,
        onImageRemove: () {
          schoolAboutUsController.historyImageFile.value = null;
          schoolAboutUsController.validateHistoryForm();
        },
        title: '',
        context: context,
      );
    }
    // If no local file but we have a NETWORK image from API
    else if (schoolAboutUsController.initialHistoryImageUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              schoolAboutUsController.initialHistoryImageUrl,
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
                  schoolAboutUsController.initialHistoryImageUrl = "";
                  schoolAboutUsController.validateHistoryForm();
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
      title: "Upload Photo",
      context: context,
      onImageSelected: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
        if (path != null) {
          schoolAboutUsController.historyImageFile.value = File(path);
          schoolAboutUsController.validateHistoryForm();
        }
      },
      imageFile: schoolAboutUsController.historyImageFile,
    );
  }

  void _handleSubmit() {
    // Call your update API
    print("Submitting changes...");
    schoolAboutUsController.uploadEductionHistoryDocInit();
  }
}
/*
class _HistoryScreenState extends State<HistoryScreen> {
  final schoolAboutUsController = Get.find<SchoolAboutUsController>();
  final descriptionEditController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    schoolAboutUsController.isFormValid.value = false;

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
                      schoolAboutUsController.historyText.value = newVal;
                      _runValidation();
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Obx(() => CustomText(
                          "${schoolAboutUsController.historyText.value.length}/3000",
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
                    imageFile: schoolAboutUsController.historyImageFile,
                    context: context,
                    onImageRemove: () {
                      schoolAboutUsController.historyImageFile.value = null;
                      _runValidation();
                    },
                    onImageSelected: () async {
                      final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                      if (selectedPath != null) {
                        schoolAboutUsController.historyImageFile.value =
                            File(selectedPath);
                      }
                      _runValidation();
                    },
                  ),

                  SizedBox(height: SizeConfig.size30),
                  Obx(() => CustomBtn(
                        onTap: schoolAboutUsController.isFormValid.value
                            ? () {
                                schoolAboutUsController
                                    .uploadEductionDocInit();
                              }
                            : null,
                        title: AppStrings.submit,
                        // Pass the validation state to change button color/opacity
                        isValidate: schoolAboutUsController.isFormValid.value,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to trigger validation
  void _runValidation() {
    schoolAboutUsController.noticesNewsValidateForm(
        noticeDescription: descriptionEditController.text,
        uploadPhoto:
            schoolAboutUsController.historyImageFile.value?.path ?? "");
  }
}
*/
