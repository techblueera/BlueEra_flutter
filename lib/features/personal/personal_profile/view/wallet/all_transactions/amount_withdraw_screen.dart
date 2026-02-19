import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';

import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/getx_utils.dart';
import '../controller/wallet_controller.dart';

class AmountWithdrawScreen extends StatefulWidget {
  AmountWithdrawScreen({super.key});

  @override
  State<AmountWithdrawScreen> createState() => _AmountWithdrawScreenState();
}

class _AmountWithdrawScreenState extends State<AmountWithdrawScreen> {
  final controller = getOrPut(() => WalletController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Amount to Withdraw',
        isLeading: true,
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: Get.width,
              padding: EdgeInsets.all(SizeConfig.size14),
              margin: EdgeInsets.all(SizeConfig.size16),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                  BorderRadius.circular(SizeConfig.size12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonTextField(
                    title: "Enter Amount",
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
                    fontWeight: FontWeight.w400,
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
                          child: CustomBtn(onTap: (){

                          },
                              bgColor: AppColors.white,
                              textColor: AppColors.secondaryTextColor,
                              borderColor: AppColors.whiteE5,
                              radius: 10,

                              title: "Cancel")),
                      SizedBox(
                        width: SizeConfig.extraLarge,
                      ),
                      Expanded(
                          child: CustomBtn(
                            bgColor: AppColors.primaryColor,
                            textColor: AppColors.white,
                            radius: 10,
                            onTap: () {
                              controller.WithdrawalApi();
                            },
                            title: "Withdraw",
                          ))
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
