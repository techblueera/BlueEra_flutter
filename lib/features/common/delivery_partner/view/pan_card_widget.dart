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

class PanCardWidget extends StatelessWidget {
  PanCardWidget({super.key});

  final controller = Get.find<DeliveryPartnerController>();

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Pan Number
            CommonTextField(
              textEditController: controller.panNumberController,
              title: AppStrings.panNumber,
              hintText:'E.g. ABCDE1234F',

              keyBoardType: TextInputType.text,
              validator: ValidationMethod.validatePAN,
              isCapitalize: true,
              maxLength: 10,
            ),
            SizedBox(height: SizeConfig.paddingM),
            CustomText(
              AppStrings.uploadPan,
              fontSize: SizeConfig.medium,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size8),
            CommonImageUploadTile(
              title: AppStrings.uploadPan,
              imageFile: controller.panCardImage,
              context: context,
              onImageSelected: () async {
                final selectedPath =
                    await CommonImageUploadTile.pickImage(
                        context: context,
                        cropAspectRatio:
                            CommonImageUploadTile.documentCropAspectRatio);
                if (selectedPath != null) {
                  controller.panCardImage.value = File(selectedPath);
                }
              },
            ),
            SizedBox(height: SizeConfig.paddingM),

            CustomBtn(
              title: controller.isRiderPersonalIdentificationLoading.value
                  ? null
                  : AppStrings.upload,
              onTap: () => controller.ridersPanCardApi(),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              isLoading: controller.isRiderPersonalIdentificationLoading.value,
            ),
          ],
        ));
  }
}
