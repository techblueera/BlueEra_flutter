import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/school_about_us_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class PrincipalMessageScreen extends StatefulWidget {
  PrincipalMessageScreen({super.key});

  @override
  State<PrincipalMessageScreen> createState() => _PrincipalMessageScreenState();
}

class _PrincipalMessageScreenState extends State<PrincipalMessageScreen> {
  final schoolAboutUsController = Get.find<SchoolAboutUsController>();
  final descriptionEditController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    schoolAboutUsController.isFormValid.value = false;
    schoolAboutUsController.getSchoolAboutUsController();

    // Listen for data load
    once(schoolAboutUsController.aboutUsData!, (AboutUsData? data) {
      if (data != null) {
        schoolAboutUsController.directorProfile.value = data.principalMessage?.photo??"";

        // Set Initial Values for Comparison
        schoolAboutUsController.initialDirectText =
            data.principalMessage?.message ?? "";
        schoolAboutUsController.initialDirectImageUrl =  data.principalMessage?.photo??"";
        // Populate UI
        descriptionEditController.text = data.principalMessage?.message ?? "";
        schoolAboutUsController.directorMessageText.value =
            data.principalMessage?.message ?? "";
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Principal / Director Message",
        isShadowShow: false,
      ),
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
                    CustomText(
                      "Upload Principal / Director Photo",
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _buildImageSection(),

                    SizedBox(height: SizeConfig.size20),

                    /// Apply Button
                    CommonTextField(
                      textEditController: descriptionEditController,
                      title: "Principal / Director Message",
                      hintText:
                          "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                      maxLine: 5,
                      maxLength: 1500,
                      isValidate: false,
                      keyBoardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onChange: (value) {
                        String newVal =
                            value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                        schoolAboutUsController.directorMessageText.value =
                            newVal;
                        _runValidation();
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Obx(() => CustomText(
                            "${schoolAboutUsController.directorMessageText.value.length}/1500",
                            color: Colors.grey,
                            fontSize: 12,
                          )),
                    ),
                    SizedBox(height: SizeConfig.size30),
                    Obx(() => CustomBtn(
                          onTap: schoolAboutUsController.isFormValid.value
                              ? () async {
                                  await schoolAboutUsController
                                      . updateDirectMessageController();
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
          );
        }),
      ),
    );
  }



  Widget _buildImageSection() {
    // If user picked a NEW local file
    if (schoolAboutUsController.directorMessageImageFile.value != null) {
      return CommonProfileImageUpload(
        imageFile: schoolAboutUsController.directorMessageImageFile,
        imgUrl: schoolAboutUsController.aboutUsData?.value.principalMessage?.photo ?? "",
        onImageRemove: () {
          schoolAboutUsController.directorMessageImageFile.value = null;
          schoolAboutUsController.directorProfile.value =
              schoolAboutUsController.directorMessageImageFile.value?.path ??
                  "";
          _runValidation();
        },onImageSelected: (){

      },
        title: '',
        context: context,
      );
    }

    // If no local file but we have a NETWORK image from API
    // Default: Show Upload Placeholder
    return CommonProfileImageUpload(
      title: "Upload Photo",
      context: context,
      imgUrl: schoolAboutUsController.aboutUsData?.value.principalMessage?.photo ?? "",
      onImageSelected: () async {
        final path = await CommonProfileImageUpload.pickImage(context: context);
        if (path != null) {
          schoolAboutUsController.directorProfile.value = path;
          schoolAboutUsController.isDirectorImageUpdate.value = true;
          schoolAboutUsController.directorMessageImageFile.value = File(path);
          _runValidation();
        }
      },
      imageFile: schoolAboutUsController.directorMessageImageFile,
    );
  }

/*  Widget _buildImageSection__() {
    // If user picked a NEW local file
    if (schoolAboutUsController.directorMessageImageFile.value != null) {
      return CommonImageUploadTile(
        imageFile: schoolAboutUsController.directorMessageImageFile,
        onImageRemove: () {
          schoolAboutUsController.isDirectorImageUpdate.value = false;

          schoolAboutUsController.directorMessageImageFile.value = null;
          schoolAboutUsController.directorProfile.value = "";
          schoolAboutUsController.validateDirectMessageForm();
        },
        title: '',
        context: context,
      );
    }
    // If no local file but we have a NETWORK image from API
    else if (schoolAboutUsController.initialDirectImageUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              schoolAboutUsController.initialDirectImageUrl,
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
                  schoolAboutUsController.isDirectorImageUpdate.value = false;

                  schoolAboutUsController.initialDirectImageUrl = "";
                  schoolAboutUsController.directorProfile.value="";
                  schoolAboutUsController.validateDirectMessageForm();
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
          schoolAboutUsController.directorProfile.value = path;
          schoolAboutUsController.isDirectorImageUpdate.value = true;

          schoolAboutUsController.directorMessageImageFile.value = File(path);
          schoolAboutUsController.validateDirectMessageForm();
        }
      },
      imageFile: schoolAboutUsController.directorMessageImageFile,
    );
  }*/

  void _runValidation() {
    schoolAboutUsController.noticesNewsValidateForm(
        noticeDescription: descriptionEditController.text,
        uploadPhoto:
        schoolAboutUsController.directorProfile.value);
  }
}
