import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/common_ai_genereted_button.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';

import '../../../../../../core/api/model/school_about_us_model.dart';

class ManagementTrustFormScreen extends StatefulWidget {
  ManagementTrustFormScreen(
      {super.key,
      required this.isEdit,
      this.management,
      this.editItemIndex = 0});

  final int editItemIndex;
  final bool isEdit;
  final Management? management;

  @override
  State<ManagementTrustFormScreen> createState() =>
      _ManagementTrustFormScreenState();
}

class _ManagementTrustFormScreenState extends State<ManagementTrustFormScreen> {
  final schoolAboutUsController = Get.find<SchoolAboutUsController>();

  final nameEditController = TextEditingController();

  final professionEditController = TextEditingController();

  final messageEditController = TextEditingController();

  @override
  void initState() {
    schoolAboutUsController.managementProfileImageFile.value = null;
    schoolAboutUsController.initialManagementProfileImageUrl = "";
    schoolAboutUsController.managementProfile.value = "";
    schoolAboutUsController.qualifications.clear();
    schoolAboutUsController.isFormValid.value = false;
    schoolAboutUsController.isImageUpdated.value = false;

    // TODO: implement initState
    schoolAboutUsController.addQualification();

    if (widget.isEdit) {
      schoolAboutUsController.initialManagementProfileImageUrl =
          widget.management?.photo ?? "";
      schoolAboutUsController.managementProfile.value =
          widget.management?.photo ?? "";

      nameEditController.text = widget.management?.name ?? "";
      professionEditController.text = widget.management?.position ?? "";
      messageEditController.text = widget.management?.bio ?? "";
      widget.management?.qualification?.forEach((data) {
        schoolAboutUsController.qualifications
            .add(TextEditingController(text: data));
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: AppStrings.managementTrust,
        isShadowShow: false,
      ),
      body: SafeArea(
        child: CommonCardWidget(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///UPLOAD PROFILE....
                Center(child: _buildImageSection()),

                CommonTextField(
                  textEditController: nameEditController,
                  hintText: "E.g. Ramesh Gupta",
                  title: AppStrings.fullName,
                  isValidate: true,
                  maxLength: 50,
                  validator: (v) => ValidationMethod.validateName(v),
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  AppStrings.qualifications,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.paddingXSL),
                Obx(() => Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount:
                              schoolAboutUsController.qualifications.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: schoolAboutUsController
                                          .qualifications[index],
                                      decoration: InputDecoration(
                                        hintText: "E.g. PhD in Geography",
                                      ),
                                    ),
                                  ),
                                  if (schoolAboutUsController
                                          .qualifications.length >
                                      1)
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () => schoolAboutUsController
                                          .removeQualification(index),
                                    )
                                ],
                              ),
                            );
                          },
                        ),

                        /// Add More Button (hidden after 5)
                        if (schoolAboutUsController.qualifications.length < 5)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: Icon(Icons.add),
                              label: CustomText(
                                AppStrings.addMore,
                                color: AppColors.primaryColor,
                              ),
                              onPressed:
                                  schoolAboutUsController.addQualification,
                            ),
                          ),
                      ],
                    )),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: professionEditController,
                  hintText: "E.g. Managing Director",
                  title: AppStrings.profession,
                  isValidate: true,
                  maxLength: 50,
                  validator: (v) => ValidationMethod.validatePosition(v),
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(AppStrings.visionMission,
                        fontWeight: FontWeight.bold),
                    // The Reusable AI Widget
                    AIGeneratorButton(
                      type: "Management,Trust",
                      data: {
                        "name": nameEditController.text,
                        "profession": professionEditController.text,
                        "qualification":
                            schoolAboutUsController.qualifications.join(","),
                      },
                      onSelected: (generatedText) {
                        schoolAboutUsController
                            .managementDescriptionText.value = generatedText;
                        messageEditController.text = generatedText;
                        _runValidation();
                      },
                    ),
                  ],
                ),
                CommonTextField(
                  textEditController: messageEditController,
                  title: "",
                  hintText:
                      "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  maxLine: 5,
                  maxLength: 1000,
                  isValidate: true,
                  validator: (v) => ValidationMethod.validateDescription(v),
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChange: (value) {
                    String newVal = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                    schoolAboutUsController.managementDescriptionText.value =
                        newVal;
                    _runValidation();
                  },
                ),
                SizedBox(height: SizeConfig.paddingXSL),

                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => CustomText(
                        "${schoolAboutUsController.managementDescriptionText.value.length}/1000",
                        color: Colors.grey,
                        fontSize: 12,
                      )),
                ),
                SizedBox(height: SizeConfig.paddingM),

                // THE BUTTON
                Obx(() => CustomBtn(
                      onTap: schoolAboutUsController.isFormValid.value
                          ? () async {
                              if (widget.isEdit) {
                                await schoolAboutUsController
                                    .editManagementTrustController(
                                  currentIndex: widget.editItemIndex,
                                  name: nameEditController.text,
                                  bio: schoolAboutUsController
                                      .managementDescriptionText.value,
                                  position: professionEditController.text,
                                  qualificationList: schoolAboutUsController
                                      .qualifications
                                      .map((item) => item.text)
                                      .toList(),
                                  managementId: widget.management?.id ?? "",
                                );
                              } else {
                                await schoolAboutUsController
                                    .addManagementTrustController(
                                  name: nameEditController.text,
                                  bio: schoolAboutUsController
                                      .managementDescriptionText.value,
                                  position: professionEditController.text,
                                  qualificationList: schoolAboutUsController
                                      .qualifications
                                      .map((item) => item.text)
                                      .toList(),
                                  managementId: widget.management?.id ?? "",
                                );
                              }
                            }
                          : null,
                      title: AppStrings.add,
                      // Pass the validation state to change button color/opacity
                      isValidate: schoolAboutUsController.isFormValid.value,
                    )),
                SizedBox(height: SizeConfig.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    // If user picked a NEW local file
    if (schoolAboutUsController.managementProfileImageFile.value != null) {
      return CommonProfileImageUpload(
        imageFile: schoolAboutUsController.managementProfileImageFile,
        imgUrl: widget.management?.photo ?? "",
        onImageRemove: () {
          schoolAboutUsController.managementProfileImageFile.value = null;
          schoolAboutUsController.managementProfile.value =
              schoolAboutUsController.managementProfileImageFile.value?.path ??
                  "";
          _runValidation();
        },
        onImageSelected: () {},
        title: '',
        context: context,
      );
    }

    // If no local file but we have a NETWORK image from API
    // Default: Show Upload Placeholder
    return CommonProfileImageUpload(
      title: AppStrings.uploadImages,
      context: context,
      imgUrl: widget.management?.photo ?? "",
      onImageSelected: () async {
        final path = await CommonProfileImageUpload.pickImage(context: context);
        if (path != null) {
          schoolAboutUsController.managementProfile.value = path;
          schoolAboutUsController.isImageUpdated.value = true;
          schoolAboutUsController.managementProfileImageFile.value = File(path);
          _runValidation();
        }
      },
      imageFile: schoolAboutUsController.managementProfileImageFile,
    );
  }

// Helper to trigger validation
  void _runValidation() {
    schoolAboutUsController.managementValidateForm(
        managementName: nameEditController.text,
        profession: professionEditController.text,
        message: messageEditController.text,
        qualification: schoolAboutUsController.qualifications,
        profileImg: schoolAboutUsController.managementProfile.value);
  }
}
