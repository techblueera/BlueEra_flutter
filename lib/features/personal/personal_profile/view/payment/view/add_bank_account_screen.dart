import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
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
import 'package:get/get.dart';

import '../controller/add_bank_account_controller.dart';

class AddBankAccountScreen extends StatelessWidget {
  AddBankAccountScreen({super.key});

  final controller = getOrPut(() => AddBankAccountController());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF1,
      appBar: CommonBackAppBar(
        title: controller.isupdate.value
            ? 'Update Bank Account'
            : 'Add Bank Account',
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
                          'Select Account Type',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size16),
                        CommonDropdown<String>(
                          items: ['Bank Account', "UPI"],
                          selectedValue: controller.selectedBankAccountType
                              .value,
                          hintText: 'Select Account',
                          onChanged: (val) {
                            controller.selectedBankAccountType.value =
                                val ?? '';
                          },
                          displayValue: (item) => item,
                        ),
                        SizedBox(height: SizeConfig.paddingM),

                        /// Bank Name Field
                        CustomText(
                          'Bank Name',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        CommonTextField(
                          textEditController: controller.bankNameController,
                          hintText: 'E.g. State Bank Of India',
                          keyBoardType: TextInputType.text,
                          validator: ValidationMethod.validateBankName,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16,
                            vertical: SizeConfig.size12,
                          ),
                        ),
                        SizedBox(height: SizeConfig.paddingM),
                        if(controller.selectedBankAccountType.value == "Bank Account")
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                'Bank Holder Name',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController:
                                controller.bankHolderNameController,
                                hintText: 'E.g.Bank Holder Name',
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
                                'Account Number',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController:
                                controller.accountNumberController,
                                hintText: 'E.g. 1234567890',
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
                                'IFSC code',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController: controller
                                    .ifscCodeController,
                                hintText: 'E.g. SBIN0001234',
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
                              CustomText(
                                'UPI ID',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CommonTextField(
                                textEditController: controller.upiIdController,
                                hintText: 'E.g.0123456789',
                                keyBoardType: TextInputType.text,
                                validator: controller.upiValidate,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16,
                                  vertical: SizeConfig.size12,
                                ),
                                borderColor: AppColors.greyE5,
                                borderWidth: 1,
                              ),
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
                            if(controller.selectedBankAccountType.value == "Bank Account"){
                              if(controller.isupdate.value){
                                controller.updateAccount();
                              }else{
                                controller.addAccount();
                              }
                            }else{
                              controller.AddUpiApi();
                            }

                          },
                          title: controller.isupdate.value ? 'Update' : 'Add',
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
