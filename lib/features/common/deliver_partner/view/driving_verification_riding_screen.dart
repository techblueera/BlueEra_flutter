import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/deliver_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/deliver_partner/view/vehicle_images_riding_screen.dart';
import 'package:BlueEra/features/common/deliver_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DrivingVerificationRidingScreen extends StatefulWidget {
  const DrivingVerificationRidingScreen({super.key});

  @override
  State<DrivingVerificationRidingScreen> createState() => _DrivingVerificationRidingScreenState();
}

class _DrivingVerificationRidingScreenState extends State<DrivingVerificationRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Driving Verification",
        // onBackTap: onBackPressed,
        buildCustomWidget: ()=> Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              "Step-4/6",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: Column(
          children: [
            /// RC
            CustomFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// RC
                    CommonTextField(
                      textEditController: controller.rcController,
                      title: 'RC Number',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "E.g. 23333....",
                      keyBoardType: TextInputType.text,
                      isValidate: true,
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    CustomText(
                      'Upload RC (Both Side)',
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        Expanded(
                          child: CommonImageUploadTile(
                            title: 'RC Front',
                            imageFile: controller.rcFrontImage,
                            context: context,
                            onImageSelected: () async {
                              final selectedPath = await controller.pickImage(context: context);
                              if (selectedPath != null) {
                                controller.rcFrontImage.value = File(selectedPath);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: SizeConfig.size8),
                        Expanded(
                          child:
                          CommonImageUploadTile(
                            title: 'RC Back',
                            imageFile: controller.rcBackImage,
                            context: context,
                            onImageSelected: () async {
                              final selectedPath = await controller.pickImage(context: context);
                              if (selectedPath != null) {
                                controller.rcBackImage.value = File(selectedPath);
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

            /// DRIVING LICENSE
            CustomFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Pan Number
                    CommonTextField(
                      textEditController: controller.drivingLicenseController,
                      title: 'Driving Licence Number',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "E.g. 23333....",
                      keyBoardType: TextInputType.text,
                      isValidate: true,
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    CustomText(
                      'Upload Driving Licence (Both Side)',
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        Expanded(
                          child: CommonImageUploadTile(
                            title: 'License Front',
                            imageFile: controller.drivingLicenseFrontImage,
                            context: context,
                            onImageSelected: () async {
                              final selectedPath = await controller.pickImage(context: context);
                              if (selectedPath != null) {
                                controller.drivingLicenseFrontImage.value = File(selectedPath);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: SizeConfig.size8),
                        Expanded(
                          child:
                          CommonImageUploadTile(
                            title: 'License Back',
                            imageFile: controller.drivingLicenseBackImage,
                            context: context,
                            onImageSelected: () async {
                              final selectedPath = await controller.pickImage(context: context);
                              if (selectedPath != null) {
                                controller.drivingLicenseBackImage.value = File(selectedPath);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                )),

            SizedBox(height: SizeConfig.paddingL),

            CustomBtn(
              title: 'Next',
              onTap: ()=> Get.to(()=> VehicleImagesRidingScreen()),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
