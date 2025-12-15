import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DrivingLicenceCardWidget extends StatelessWidget {
  DrivingLicenceCardWidget({super.key});

  final controller = Get.find<DeliveryPartnerController>();

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonTextField(
              textEditController: controller.drivingLicenseController,
              title: AppStrings.drivingLicenceNumber,
              hintText: 'E.g. DL0120110012345',
              keyBoardType: TextInputType.text,
              validator: ValidationMethod.validateDrivingLicense,
              isCapitalize: true,
              maxLength: 15,
            ),
            SizedBox(height: SizeConfig.paddingM),
            CustomText(
              AppStrings.uploadDrivingLicenceBothSide,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size8),
            Row(
              children: [
                Expanded(
                  child: CommonImageUploadTile(
                    title: AppStrings.licenseFront,
                    imageFile: controller.drivingLicenseFrontImage,
                    context: context,
                    onImageSelected: () async {
                      final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                      if (selectedPath != null) {
                        controller.drivingLicenseFrontImage.value =
                            File(selectedPath);
                      }
                    },
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: CommonImageUploadTile(
                    title: AppStrings.licenseBack,
                    imageFile: controller.drivingLicenseBackImage,
                    context: context,
                    onImageSelected: () async {
                      final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                      if (selectedPath != null) {
                        controller.drivingLicenseBackImage.value =
                            File(selectedPath);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.paddingM),

            CustomBtn(
              title: controller.isRiderPersonalIdentificationLoading.value
                  ? null
                  : "Upload",
              onTap: () => controller.ridersDrivingLicenceVerificationApi(),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              isLoading: controller.isRiderPersonalIdentificationLoading.value,
            ),
            // SizedBox(height: SizeConfig.paddingM),
          ],
        ));
  }
}
