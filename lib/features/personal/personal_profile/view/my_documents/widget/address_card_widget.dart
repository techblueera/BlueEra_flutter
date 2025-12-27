import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class AddressCardWidget extends StatelessWidget {
  AddressCardWidget({super.key});

  final controller = getOrPut(() => MyDocumentsController());

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: CustomFormCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Address Id Name
              CommonTextField(
                textEditController: controller.addIdProofController,
                title: 'Name of ID',
                hintText: 'E.g. Voter ID, Gas Bill...',
                keyBoardType: TextInputType.text,
                validator: ValidationMethod.validateName,
                maxLength: 24,
              ),
              SizedBox(height: SizeConfig.paddingM),
              CustomText(
                "Upload Front and Back Images",
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w400,
              ),
              SizedBox(height: SizeConfig.size8),
              Row(
                children: [
                  Expanded(
                    child: CommonImageUploadTile(
                      title: 'Upload',
                      imageFile: controller.addIdProofFrontImage,
                      context: context,
                      onImageSelected: () async {
                        final selectedPath =
                        await CommonImageUploadTile.pickImage(
                            context: context);
                        if (selectedPath != null) {
                          controller.addIdProofFrontImage.value = File(selectedPath);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CommonImageUploadTile(
                      title: 'Upload',
                      imageFile: controller.addIdProofBackImage,
                      context: context,
                      onImageSelected: () async {
                        final selectedPath =
                        await CommonImageUploadTile.pickImage(
                            context: context);
                        if (selectedPath != null) {
                          controller.addIdProofBackImage.value = File(selectedPath);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.paddingL),

              CustomBtn(
                title: controller.isAddressUploadLoading.value
                    ? null
                    : "Upload",
                onTap: () => controller.addressApi(),
                radius: 10.0,
                bgColor: AppColors.primaryColor,
                isLoading: controller.isAddressUploadLoading.value,
              ),

            ],
          )),
    );
  }
}
