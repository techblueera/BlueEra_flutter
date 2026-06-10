import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/add_bank_account_controller.dart';
import '../widget/upi_qr_widget.dart';

class AddBankAccountScreen extends StatelessWidget {
  AddBankAccountScreen({super.key});

  final controller = getOrPut(() => AddBankAccountController());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: controller.isupdate.value
            ? AppStrings.updateBankAccount
            : AppStrings.addBankAccount,
        isLeading: true,
      ),
      body: AbsorbPointer(
        absorbing: controller.isLoading.value,
        child: SingleChildScrollView(
          child: Form(
            key: controller.formKey,
            child: CustomFormCard(
              margin: EdgeInsets.symmetric(
                vertical: SizeConfig.size20,
                horizontal: SizeConfig.size8,
              ),
              child: Obx(() {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Container
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// IFSC Code Field
                        CustomText(
                          AppStrings.selectAccountType,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size16),
                        CommonDropdown<String>(
                          items: ['Bank Account', "UPI"],
                          selectedValue: controller.selectedBankAccountType
                                      .value ==
                                  'Select Account'
                              ? null
                              : controller.selectedBankAccountType.value,
                          hintText: AppStrings.selectAccount.tr,
                          validator: controller.validateAccountType,
                          onChanged: (val) {
                            controller.selectedBankAccountType.value =
                                val ?? '';
                          },
                          displayValue: (item) => item,
                        ),
                        SizedBox(height: SizeConfig.paddingM),

                        if(controller.selectedBankAccountType.value == "Bank Account")
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Bank Name Field
                              CustomText(
                                AppStrings.bankName,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController: controller.bankNameController,
                                hintText: AppStrings.bankNameHint.tr,
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
                              CustomText(
                                AppStrings.bankHolderName,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController:
                                controller.bankHolderNameController,
                                hintText: AppStrings.bankHolderNameHint.tr,
                                maxLength: AppConstants.inputCharterLimit20,
                                keyBoardType: TextInputType.text,
                                validator: ValidationMethod
                                    .validateBankHolderName,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16,
                                  vertical: SizeConfig.size12,
                                ),
                              ),
                              SizedBox(height: SizeConfig.paddingM),

                              /// Account Number Field
                              CustomText(
                                AppStrings.accountNumber,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController:
                                controller.accountNumberController,
                                hintText: AppStrings.accountNumberHint.tr,
                                keyBoardType: TextInputType.number,
                                validator: ValidationMethod
                                    .validateAccountNumber,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16,
                                  vertical: SizeConfig.size12,
                                ),
                                inputLength: 18,
                              ),
                              SizedBox(height: SizeConfig.paddingM),

                              /// IFSC Code Field
                              CustomText(
                                AppStrings.ifscCode,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController: controller
                                    .ifscCodeController,
                                hintText: AppStrings.ifscCodeHint.tr,
                                keyBoardType: TextInputType.text,
                                inputLength: 11,
                                validator: ValidationMethod.validateIfscCode,
                                isCapitalize: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16,
                                  vertical: SizeConfig.size12,
                                ),
                              ),
                            ],
                          ),
                        if(controller.selectedBankAccountType.value =="UPI")
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Link Mobile Number to UPI — shown in place of
                              /// the bank-name field on the UPI form.
                              CustomText(
                                AppStrings.linkMobileNumberToUpi,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  /// Fixed country code.
                                  Container(
                                    height: SizeConfig.size45,
                                    width: SizeConfig.size57,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.greyE5,
                                        width: 1,
                                      ),
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: CustomText(
                                      "+91",
                                      fontSize: SizeConfig.large,
                                    ),
                                  ),
                                  SizedBox(width: SizeConfig.size10),
                                  Expanded(
                                    child: CommonTextField(
                                      textEditController:
                                          controller.linkedMobileController,
                                      hintText: AppStrings.linkMobileNumberHint,
                                      keyBoardType: TextInputType.number,
                                      validator: controller.validateLinkedMobile,
                                      inputLength: 10,
                                      maxLength: 10,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: SizeConfig.size16,
                                        vertical: SizeConfig.size12,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: SizeConfig.paddingM),
                              CustomText(
                                AppStrings.upiId,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController: controller.upiIdController,
                                hintText: AppStrings.upiIdHint.tr,
                                keyBoardType: TextInputType.text,
                                validator: controller.upiValidate,
                                onChange: (val) =>
                                    controller.upiInput.value = val,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16,
                                  vertical: SizeConfig.size12,
                                ),
                                borderColor: AppColors.greyE5,
                                borderWidth: 1,
                              ),

                              /// Live QR generated from the entered UPI ID.
                              Obx(() {
                                if (!controller.isUpiInputValid) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: EdgeInsets.only(
                                      top: SizeConfig.paddingM),
                                  child: UpiQrPreview(
                                    upiId: controller.upiInput.value.trim(),
                                    bankName:
                                        controller.bankNameController.text.trim(),
                                  ),
                                );
                              }),
                            ],
                          ),

                            SizedBox(height: SizeConfig.paddingXSL),
                      ],
                    ),

                    SizedBox(height: SizeConfig.paddingL),

                    // Add Button
                    Obx(() =>
                        CustomBtn(
                          onTap: (){
                            final type = controller.selectedBankAccountType.value;
                            if(type == "Bank Account"){
                              if(controller.isupdate.value){
                                controller.updateAccount();
                              }else{
                                controller.addAccount();
                              }
                            }else if(type == "UPI"){
                              controller.AddUpiApi();
                            }else{
                              // No type chosen yet — surface the dropdown error.
                              controller.formKey.currentState?.validate();
                            }
                          },
                          title: controller.isupdate.value ? AppStrings.update.tr : AppStrings.add.tr,
                          isLoading: controller.isLoading.value,
                          bgColor: AppColors.primaryColor,
                          textColor: AppColors.white,
                          radius: SizeConfig.size8,
                          height: SizeConfig.buttonXL,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
