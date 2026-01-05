import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GenericDocumentWidget extends StatelessWidget {
  final String documentType;
  final String uploadSectionLabel;
  final bool backImage;   // Used to check if back image exists
  final String? textFieldLabel; // Used to check if input exists
  final String? textFieldHint;
  final String? Function(String?)? textFieldValidation;
  final int? maxLength;
  final TextInputType keyboardType;
  final bool isCapitalize;

  GenericDocumentWidget({
    required this.documentType,
    required this.uploadSectionLabel,
    required this.backImage,
    this.textFieldLabel,
    this.textFieldHint,
    this.textFieldValidation,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.isCapitalize = false,
    super.key,
  });

  final controller = getOrPut(() => MyDocumentsController());

  @override
  Widget build(BuildContext context) {

    controller.genericDocumentController.clear();
    controller.genericDocumentsFrontImage.value = null;
    controller.genericDocumentsBackImage.value = null;

    return Obx(()=> AbsorbPointer(
      absorbing: controller.isGenericDocumentLoading.value,
      child: CustomFormCard(
          padding: EdgeInsets.zero,
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                if(textFieldLabel!=null)
                  ...[
                    CommonTextField(
                      textEditController: controller.genericDocumentController,
                      title: textFieldLabel,
                      hintText: textFieldHint,
                      keyBoardType: keyboardType,
                      validator: textFieldValidation,
                      maxLength: maxLength,
                      isCapitalize: isCapitalize
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                  ],

                CustomText(
                  uploadSectionLabel,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    Expanded(
                      child: CommonImageUploadTile(
                        title: AppStrings.upload,
                        imageFile: controller.genericDocumentsFrontImage,
                        context: context,
                        onImageSelected: () async {
                          final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                          if (selectedPath != null) {
                            controller.genericDocumentsFrontImage.value = File(selectedPath);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    Expanded(
                      child: CommonImageUploadTile(
                        title: AppStrings.upload,
                        imageFile: controller.genericDocumentsBackImage,
                        context: context,
                        onImageSelected: () async {
                          final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                          if (selectedPath != null) {
                            controller.genericDocumentsBackImage.value = File(selectedPath);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.paddingL),

                CustomBtn(
                  title: controller.isGenericDocumentLoading.value
                      ? null
                      : "Upload",
                  onTap: () => controller.genericDocumentApi(
                      documentType: documentType,
                      hasInput: textFieldLabel!=null,
                      backImage: backImage
                  ),
                  radius: 10.0,
                  bgColor: AppColors.primaryColor,
                  isLoading: controller.isGenericDocumentLoading.value,
                ),
              ],
            ),
          )),
    ));
  }
}
