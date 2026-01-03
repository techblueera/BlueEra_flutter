import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_about_us_model.dart';

class ManagementTrustFormScreen extends StatefulWidget {
  ManagementTrustFormScreen({super.key, required this.isEdit, this.management});

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
    schoolAboutUsController.initialManagementProfileImageUrl = "";
    schoolAboutUsController.managementProfile.value ="";
    schoolAboutUsController.qualifications.clear();
    schoolAboutUsController.isFormValid.value = false;
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
        title: "Add Management / Trust",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: CommonCardWidget(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///UPLOAD PROFILE....
                _buildImageSection(),
                // Center(
                //   child: CommonProfileImage(
                //     imagePath: schoolAboutUsController.managementProfile.value,
                //     onImageUpdate: (image) {
                //       schoolAboutUsController.managementProfile.value = image;
                //       schoolAboutUsController.isImageUpdated.value = true;
                //     },
                //     dialogTitle: 'Upload Profile',
                //     borderColor: AppColors.primaryColor,
                //   ),
                // ),
                CommonTextField(
                  textEditController: nameEditController,
                  hintText: "E.g. Ramesh Gupta",
                  title: "Name",
                  maxLength: 50,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  'Qualification',
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
                                "Add More",
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
                  title: "Profession",
                  maxLength: 50,
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),

                CommonTextField(
                  textEditController: messageEditController,
                  title: AppStrings.message,
                  hintText:
                      "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  maxLine: 5,
                  maxLength: 1000,
                  isValidate: false,
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
                              await schoolAboutUsController
                                  .uploadManagementDocInit(
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
      return Center(
        child: CommonProfileImage(
          imagePath: schoolAboutUsController.managementProfile.value,
          onImageUpdate: (image) {
            schoolAboutUsController.managementProfile.value = image;
            schoolAboutUsController.isImageUpdated.value = true;
            _runValidation();
          },
          dialogTitle: 'Upload Profile',
          borderColor: AppColors.primaryColor,
        ),
      );
      return CommonImageUploadTile(
        imageFile: schoolAboutUsController.managementProfileImageFile,
        onImageRemove: () {
          schoolAboutUsController.managementProfileImageFile.value = null;
          _runValidation();
        },
        title: '',
        context: context,
      );
    }
    // If no local file but we have a NETWORK image from API
    else if (schoolAboutUsController
        .initialManagementProfileImageUrl.isNotEmpty) {
      return Stack(
        children: [
          Center(
            child: CommonProfileImage(
              imagePath:
                  schoolAboutUsController.initialManagementProfileImageUrl,
              // imagePath: schoolAboutUsController.managementProfile.value,
              onImageUpdate: (image) {
                schoolAboutUsController.managementProfile.value = image;
                schoolAboutUsController.isImageUpdated.value = true;
                _runValidation();
              },
              dialogTitle: 'Upload Profile',
              borderColor: AppColors.primaryColor,
            ),
          ),
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(8),
          //   child: Image.network(
          //     schoolAboutUsController.initialManagementProfileImageUrl,
          //     height: 150,
          //     width: double.infinity,
          //     fit: BoxFit.cover,
          //   ),
          // ),
          // Positioned(
          //   right: 5,
          //   top: 5,
          //   child: CircleAvatar(
          //     backgroundColor: Colors.red,
          //     child: IconButton(
          //       icon: const Icon(Icons.delete, color: Colors.white),
          //       onPressed: () {
          //         // Clear initial URL to show "Change" happened
          //         schoolAboutUsController.initialManagementProfileImageUrl = "";
          //         _runValidation();
          //         setState(
          //             () {}); // Refresh local UI to show upload placeholder
          //       },
          //     ),
          //   ),
          // )
        ],
      );
    }
    return Center(
      child: CommonProfileImage(
        imagePath: schoolAboutUsController.managementProfile.value,
        onImageUpdate: (image) async {
          final path = await CommonImageUploadTile.pickImage(context: context);
          if (path != null) {
            schoolAboutUsController.managementProfile.value = path;
            schoolAboutUsController.managementProfileImageFile.value =
                File(path);

            _runValidation();
          }
          //   schoolAboutUsController.managementProfile.value = image;
          //   schoolAboutUsController.isImageUpdated.value = true;
          //   _runValidation();
          //
        },
        dialogTitle: 'Upload Profile',
        borderColor: AppColors.primaryColor,
      ),
    );
    // Default: Show Upload Placeholder
    return CommonImageUploadTile(
      title: "Upload Photo",
      context: context,
      onImageSelected: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
        if (path != null) {
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
        qualification:
            schoolAboutUsController.qualifications,
        profileImg: schoolAboutUsController.managementProfile.value ?? "");
  }
}
