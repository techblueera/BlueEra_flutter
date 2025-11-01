import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/deliver_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/deliver_partner/view/driving_verification_riding_screen.dart';
import 'package:BlueEra/features/common/deliver_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/common/deliver_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalIdentificationRidingScreen extends StatefulWidget {
  const PersonalIdentificationRidingScreen({super.key});

  @override
  State<PersonalIdentificationRidingScreen> createState() => _PersonalIdentificationRidingScreenState();
}

class _PersonalIdentificationRidingScreenState extends State<PersonalIdentificationRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Personal Identification",
        // onBackTap: onBackPressed,
        buildCustomWidget: ()=> Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              "Step-3/6",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: Column(
          children: [
            GetBuilder<DeliveryPartnerController>(
              id: DeliveryPartnerController.livePhotoId,
              builder: (ctrl) => CommonMultipleImageUploadSection(
                title: 'Upload Your Live Photo',
                minImages: 2,
                maxImages: controller.maxLiveUploadImages,
                images: ctrl.livePhoto,
                onAddImage: () async {
                  ctrl.addImages(
                      label: 'Road Side Images',
                      imageList: ctrl.livePhoto,
                      updateId: DeliveryPartnerController.livePhotoId,
                      maxUploadImages: controller.maxLiveUploadImages
                  );
                },
                onRemoveImage: (index) {
                  ctrl.removeImageAt(
                    imageList: ctrl.livePhoto,
                    index: index,
                    updateId: DeliveryPartnerController.livePhotoId,
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.paddingM),
            CustomFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Aadhar
                    CommonTextField(
                      textEditController: controller.aadharController,
                      title: 'Aadhar Number',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "E.g. 23333....",
                      keyBoardType: TextInputType.text,
                      isValidate: true,
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    CustomText(
                      'Upload Aadhar (Both Side)',
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        Expanded(
                          child: CommonImageUploadTile(
                            title: 'Aadhar Front',
                            imageFile: controller.aadharFrontImage,
                            context: context,
                            onImageSelected: () async {
                              final selectedPath = await controller.pickImage(context: context);
                              if (selectedPath != null) {
                                controller.aadharFrontImage.value = File(selectedPath);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: SizeConfig.size8),
                        Expanded(
                          child:
                          CommonImageUploadTile(
                            title: 'Aadhar Back',
                            imageFile: controller.aadharBackImage,
                            context: context,
                            onImageSelected: () async {
                              final selectedPath = await controller.pickImage(context: context);
                              if (selectedPath != null) {
                                controller.aadharBackImage.value = File(selectedPath);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                )
            ),
            SizedBox(height: SizeConfig.paddingM),

            CustomFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Pan Number
                    CommonTextField(
                      textEditController: controller.aadharController,
                      title: 'Pan Number',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "E.g. 23333....",
                      keyBoardType: TextInputType.text,
                      isValidate: true,
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    CustomText(
                      'Upload Aadhar (Both Side)',
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonImageUploadTile(
                      title: 'Upload Pan',
                      imageFile: controller.panCardImage,
                      context: context,
                      onImageSelected: () async {
                        final selectedPath = await controller.pickImage(context: context);
                        if (selectedPath != null) {
                          controller.panCardImage.value = File(selectedPath);
                        }
                      },
                    ),
                  ],
                )),

            SizedBox(height: SizeConfig.paddingL),
            CustomBtn(
              title: 'Next',
              onTap: ()=> Get.to(()=> DrivingVerificationRidingScreen()),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }



}
