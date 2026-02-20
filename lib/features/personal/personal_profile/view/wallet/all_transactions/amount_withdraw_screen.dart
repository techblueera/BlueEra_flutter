import 'package:BlueEra/core/api/apiService/api_keys.dart';
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
import '../../../../../../core/constants/snackbar_helper.dart';
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
        child: SingleChildScrollView(
          child: Obx(() {
            return Column(
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
                        selectedValue: controller.selectedBank.value,
                        validator: controller.validatePaymentMethod,
                        hintText: 'Select Account',
                        onChanged: (val) {
                          controller.selectedBank.value = val ?? '';
                          controller.getWalletWithdrawalMethod({
                            ApiKeys.methodType: val!.toUpperCase()
                          });
                        },
                        displayValue: (item) => item,
                      ),
                      SizedBox(height: SizeConfig.size12),
                      if(controller.selectedBank.value == "Bank")
                        Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("Choose Bank"),
                            SizedBox(height: SizeConfig.size12),
                            ...controller.bankListModel.value.data?.map((e) =>
                                InkWell(
                                  onTap: () {
                                    controller.selectedBankDetails.value = e;
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: controller
                                                .selectedBankDetails.value == e
                                                ? AppColors.primaryColor
                                                : AppColors.whiteE5
                                        ),
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    padding: EdgeInsets.all(10),
                                    margin: EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        CustomText(
                                          e.bankDetails?.holderName,
                                          color: AppColors.secondaryTextColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,),
                                        SizedBox(height: 10,),
                                        Row(mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween,
                                          children: [
                                            CustomText(e.bankDetails?.accountNo,
                                              fontWeight: FontWeight.w600,),
                                            CustomText(e.bankDetails?.bankName,
                                              color: AppColors
                                                  .secondaryTextColor,),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )).toList() ?? [],
                          ],
                        ),
                      if(controller.selectedBank.value == "UPI")
                        Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("Choose UPI"),
                            SizedBox(height: SizeConfig.size12),
                            ...controller.upiListModel.value.data?.map((e) =>
                                InkWell(
                                  onTap: () {
                                    controller.selectedUpiDetails.value = e;
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: controller
                                                .selectedUpiDetails.value == e
                                                ? AppColors.primaryColor
                                                : AppColors.whiteE5
                                        ),
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    padding: EdgeInsets.all(10),
                                    margin: EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        CustomText(
                                          e.upiDetails?.bankName,
                                          color: AppColors.secondaryTextColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,),
                                        SizedBox(height: 10,),
                                        Row(
                                          children: [
                                            CustomText(e.upiDetails?.upiId,
                                              fontWeight: FontWeight.w600,),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )).toList() ?? [],
                          ],
                        ),

                      SizedBox(height: SizeConfig.size20),
                      Row(
                        children: [
                          Expanded(
                              child: CustomBtn(onTap: () {

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
                                isValidate: controller.selectedBank.value == "UPI"?controller.selectedUpiDetails.value.id!=null:controller.selectedBankDetails.value.id!=null,
                                textColor: AppColors.white,
                                radius: 10,
                                isLoading: controller.isLoading.value,
                                onTap: () {
                                  if(controller.selectedBank.value == "UPI"?controller.selectedUpiDetails.value.id!=null:controller.selectedBankDetails.value.id!=null){
                                    controller.WithdrawalApi();

                                  }else{
                                    commonSnackBar(
                                        message: "Choose Payment Type");
                                  }
                                },
                                title: "Withdraw",
                              ))
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
