import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CancelChequeDocumentWidget extends StatelessWidget {
  final String documentType;
  CancelChequeDocumentWidget({super.key, required this.documentType});

  final controller = getOrPut(() => MyDocumentsController());

  @override
  Widget build(BuildContext context) {
    return Obx(()=> AbsorbPointer(
      absorbing: controller.isCancelChequeLoading.value,
      child: CustomFormCard(
          padding: EdgeInsets.zero,
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                /// Bank Name Field
                CommonTextField(
                  textEditController: controller.bankNameController,
                  hintText: 'E.g. State Bank Of India',
                  title: 'Bank Name',
                  keyBoardType: TextInputType.text,
                  validator: ValidationMethod.validateBankName,
                  maxLength: AppConstants.inputCharterLimit20,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size12,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.&-]')),
                  ],
                ),
                SizedBox(height: SizeConfig.paddingM),

                /// Bank Account Number
                CommonTextField(
                  textEditController: controller.bankAccountNumberController,
                  title: 'Bank Account Number',
                  hintText: 'E.g. 1234567890',
                  keyBoardType: TextInputType.number,
                  validator: ValidationMethod.validateAccountNumber,
                  inputLength: 18,
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: controller.IFSCCodeController,
                  title: 'IFSC Code',
                  hintText: 'E.g. SBIN0001234',
                  keyBoardType: TextInputType.text,
                  inputLength: 11,
                  validator: ValidationMethod.validateIfscCode,
                  isCapitalize: true,
                ),
                SizedBox(height: SizeConfig.paddingM),
                CustomText(
                  'Upload Cancelled Cheque / Bank Passbook Photo',
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    Expanded(
                      child: CommonImageUploadTile(
                        title: 'Cancel Cheque Front',
                        imageFile: controller.cancelChequeFrontImage,
                        context: context,
                        onImageSelected: () async {
                          final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                          if (selectedPath != null) {
                            controller.cancelChequeFrontImage.value = File(selectedPath);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: SizeConfig.size3),
                    Expanded(
                      child: CommonImageUploadTile(
                        title: 'Cancel Cheque Back',
                        imageFile: controller.cancelChequeBackImage,
                        context: context,
                        onImageSelected: () async {
                          final selectedPath =
                          await CommonImageUploadTile.pickImage(
                              context: context);
                          if (selectedPath != null) {
                            controller.cancelChequeBackImage.value = File(selectedPath);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.paddingL),

                CustomBtn(
                  title: controller.isCancelChequeLoading.value
                      ? null
                      : "Upload",
                  onTap: () => controller.cancelChequeUploadApi(
                      documentType: documentType
                  ),
                  radius: 10.0,
                  bgColor: AppColors.primaryColor,
                  isLoading: controller.isCancelChequeLoading.value,
                ),
              ],
            ),
          )),
    ));
  }
}
