import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_upi/add_accountupi_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/amount_withdraw_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AmountWithdrawScreen extends StatelessWidget {
  AmountWithdrawScreen({super.key});
  // final controller = Get.put(AddAccountupiController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AmountWithdrawScreenController>(
        init: AmountWithdrawScreenController(),
        builder: (controller) {
          return Scaffold(
            appBar: CommonBackAppBar(
              title: 'Amount to Witrhdraw',
              isLeading: true,
            ),
            body: Padding(
              padding: EdgeInsets.all(SizeConfig.size16),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: Get.width,
                      padding: EdgeInsets.all(SizeConfig.size10),
                      decoration: BoxDecoration(
                          color: AppColors.fillColor,
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            "Enter Amount",
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium,
                          ),
                          SizedBox(
                            height: SizeConfig.size12,
                          ),
                          CommonTextField(
                            textEditController: controller.amountController,
                            hintText: 'E.g. 100,200,300',
                            keyBoardType: TextInputType.text,
                            validator: controller.amountValidate,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size16,
                              vertical: SizeConfig.size12,
                            ),
                            borderColor: AppColors.greyE5,
                            borderWidth: 1,
                          ),
                          SizedBox(
                            height: SizeConfig.size12,
                          ),
                          CustomText(
                            "Choose Payment method",
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium,
                          ),
                          SizedBox(height: SizeConfig.size16),
                          CommonDropdown<String>(
                            items: controller.bankStatus,
                            selectedValue: controller.selectedBank,
                            validator: controller.validatePaymentMethod,
                            hintText: 'Select Account',
                            onChanged: (val) {
                              controller.selectedBank = val;
                              controller.update();
                            },
                            displayValue: (item) => item,
                          ),
                          SizedBox(height: SizeConfig.size20),
                          Row(
                            children: [
                              Expanded(
                                  child: GestureDetector(
                                onTap: () {
                                  Get.back();
                                },
                                child: Container(
                                  height: SizeConfig.size45,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.primaryColor),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Center(
                                    child: CustomText(
                                      'Cancel',
                                      fontSize: SizeConfig.medium15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              )),
                              SizedBox(
                                width: SizeConfig.extraLarge,
                              ),
                              Expanded(
                                  child: GestureDetector(
                                onTap: () {
                                  controller.WithdrawalApi();
//call API for withdraw
//message according ot response
                                },
                                child: Container(
                                  height: SizeConfig.size45,
                                  decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      border: Border.all(
                                          color: AppColors.primaryColor),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Center(
                                    child: CustomText(
                                      'Withdraw',
                                      fontSize: SizeConfig.medium15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ))
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
