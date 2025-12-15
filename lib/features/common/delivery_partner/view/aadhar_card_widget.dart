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

class AadharCardWidget extends StatelessWidget {
  AadharCardWidget({super.key});

  final controller = Get.find<DeliveryPartnerController>();

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Aadhar
            CommonTextField(
              textEditController: controller.aadharController,
              title: AppStrings.aadharNumber,
              hintText: 'E.g. 5678 1234 6679 9012',
              keyBoardType: TextInputType.number,
              validator: ValidationMethod.validateAadhaar,
              maxLength: 12,
            ),
            SizedBox(height: SizeConfig.paddingM),
            CustomText(
              AppStrings.uploadAadharBothSide,
              fontSize: SizeConfig.medium,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w400,
            ),
            SizedBox(height: SizeConfig.size8),
            Row(
              children: [
                Expanded(
                  child: CommonImageUploadTile(
                    title: AppStrings.aadharFront,
                    imageFile: controller.aadharFrontImage,
                    context: context,
                    onImageSelected: () async {
                      final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                      if (selectedPath != null) {
                        controller.aadharFrontImage.value = File(selectedPath);
                      }
                    },
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: CommonImageUploadTile(
                    title: AppStrings.aadharBack,
                    imageFile: controller.aadharBackImage,
                    context: context,
                    onImageSelected: () async {
                      final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                      if (selectedPath != null) {
                        controller.aadharBackImage.value = File(selectedPath);
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
              onTap: () =>
                  controller.ridersAadharCardApi(),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              isLoading: controller.isRiderPersonalIdentificationLoading.value,
            ),
            // SizedBox(height: SizeConfig.paddingM),
          ],
        ));
  }
}
