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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Container
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Bank Holder Name
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
                        validator: ValidationMethod.validateBankHolderName,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16,
                          vertical: SizeConfig.size12,
                        ),
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
                        validator: ValidationMethod.validateAccountNumber,
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
                        textEditController: controller.ifscCodeController,
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
                      SizedBox(height: SizeConfig.paddingM),

                      /// IFSC Code Field
                      CustomText(
                        'Account Type',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size16),
                      Obx(()=> CommonDropdown<BankAccountType>(
                        items: BankAccountType.values,
                        selectedValue: controller.selectedBankAccountType.value,
                        hintText: 'Select Account',
                        onChanged: (val) {
                          controller.selectedBankAccountType.value = val;
                        },
                        displayValue: (item) => item.displayName,
                      )),

                      SizedBox(height: SizeConfig.paddingXSL),
                      // Row(
                      //   crossAxisAlignment: CrossAxisAlignment.center,
                      //   children: [
                      //     CustomText(
                      //       'Set account as default',
                      //       fontSize: SizeConfig.small,
                      //       fontWeight: FontWeight.w600,
                      //       color: AppColors.mainTextColor,
                      //     ),
                      //     Obx(()=> Checkbox(
                      //       value: controller.isDefault.value,
                      //       onChanged: (value) {
                      //         controller.isDefault.value = !controller.isDefault.value;
                      //       },
                      //       checkColor: AppColors.white,
                      //     ))
                      //   ],
                      // )
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingL),

                  // Add Button
                  Obx(() =>
                      CustomBtn(
                        onTap: controller.isLoading.value
                            ? null
                            : controller.isupdate.value
                            ? controller.updateAccount
                            : controller.addAccount,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
