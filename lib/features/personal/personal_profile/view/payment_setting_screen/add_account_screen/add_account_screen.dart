import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'add_account_controller.dart';

class AddAccountScreen extends StatelessWidget {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(AddAccountController());

    return GetBuilder<AddAccountController>(
        init: AddAccountController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: CommonBackAppBar(
              // title: controller.isupdate.value?Text("Update Bank Account"):Text("Update Bank Account")
              title: controller.isupdate.value
                  ? 'Update Bank Account'
                  : 'Add Bank Account',
              isLeading: true,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size16),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Container
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(SizeConfig.size20),
                        decoration: BoxDecoration(
                          color: AppColors.fillColor,
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'Bank  Holder Name',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            SizedBox(height: SizeConfig.size8),
                            CommonTextField(
                              textEditController:
                                  controller.bankHolderNameController,
                              hintText: 'E.g.Bank Holder Name',
                              keyBoardType: TextInputType.text,
                              validator: controller.validateBankHolderName,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size16,
                                vertical: SizeConfig.size12,
                              ),
                              borderColor: AppColors.greyE5,
                              borderWidth: 1,
                              // borderRadius: SizeConfig.size8,
                            ),
                            SizedBox(height: SizeConfig.size16),
                            // Bank Name Field
                            CustomText(
                              'Bank Name',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            SizedBox(height: SizeConfig.size8),
                            CommonTextField(
                              textEditController: controller.bankNameController,
                              hintText: 'E.g. State Bank Of India',
                              keyBoardType: TextInputType.number,
                              validator: controller.validateBankName,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size16,
                                vertical: SizeConfig.size12,
                              ),
                              borderColor: AppColors.greyE5,
                              borderWidth: 1,
                              // borderRadius: SizeConfig.size8,
                            ),
                            SizedBox(height: SizeConfig.size16),

                            // Account Number Field
                            CustomText(
                              'Account Number',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            SizedBox(height: SizeConfig.size8),
                            CommonTextField(
                              textEditController:
                                  controller.accountNumberController,
                              hintText: 'E.g. 1234567890',
                              keyBoardType: TextInputType.number,
                              validator: controller.validateAccountNumber,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size16,
                                vertical: SizeConfig.size12,
                              ),
                              borderColor: AppColors.greyE5,
                              borderWidth: 1,
                              // borderRadius: SizeConfig.size8,
                            ),
                            SizedBox(height: SizeConfig.size16),

                            // IFSC Code Field
                            CustomText(
                              'IFSC code',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            SizedBox(height: SizeConfig.size8),
                            CommonTextField(
                              textEditController: controller.ifscCodeController,
                              hintText: 'E.g. SB17878DG',
                              keyBoardType: TextInputType.text,
                              validator: controller.validateIfscCode,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size16,
                                vertical: SizeConfig.size12,
                              ),
                              borderColor: AppColors.greyE5,
                              borderWidth: 1,
                              // borderRadius: SizeConfig.size8,
                            ),
                            SizedBox(height: SizeConfig.size16),
                            CustomText(
                              'Account Type',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            SizedBox(height: SizeConfig.size16),

                            CommonDropdown<String>(
                              items: controller.bankStatus,
                              selectedValue: controller.selectedBank,
                              hintText: 'Select Account',
                              onChanged: (val) {
                                controller.selectedBank = val;
                                controller.update();
                              },
                              displayValue: (item) => item,
                            ),

                            SizedBox(height: SizeConfig.size16),
                            Row(
                              children: [
                                CustomText(
                                  'Set account as default',
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                                Checkbox(
                                  value: controller.isDefault,
                                  onChanged: (value) {
                                    controller.isDefault =
                                        !controller.isDefault;
                                    controller.update();
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                      ),

                      SizedBox(height: SizeConfig.size24),

                      // Add Button
                      Obx(() => 
                      CustomBtn(
                            onTap: controller.isLoading.value
                                ? null
                                // : controller.addAccount,
                                : controller.isupdate.value
                                    ? () => controller.updateAccount()
                                    : controller.addAccount,
                            title: controller.isupdate.value ? 'Update' : 'Add',
                            // title: "Add",
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
          );
        });
  }
}
