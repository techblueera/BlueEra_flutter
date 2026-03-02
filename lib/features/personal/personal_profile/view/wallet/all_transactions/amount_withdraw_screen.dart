import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';

import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
  initState(){
    super.initState();
    withdrawalMethodApiCall();
  }

  void withdrawalMethodApiCall(){
    controller.getWalletWithdrawalMethodApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Amount to Withdraw',
        isLeading: true,
      ),
      body: SafeArea(
        child: Obx(() {
        
          if(controller.walletWithdrawalMethodResponse.value.status == Status.INITIAL){
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        
          if(controller.walletWithdrawalMethodResponse.value.status == Status.ERROR){
            return Center(
                child: CustomText(
                  'Oops Something went wrong.. Unable to fetch withdraw account data',
                  fontSize: SizeConfig.extraLarge,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                )
            );
          }
        
          var methodsList = controller.withdrawalMethodDataList;
        
          return methodsList.isNotEmpty
              ? _buildWithdrawalForm()
              : _buildNoAccountEmptyState();
        }),
      ),
    );
  }

  Widget _buildNoAccountEmptyState() {
    return Container(
      width: Get.width,
      padding: EdgeInsets.all(SizeConfig.size24),
      child: Column(
        children: [

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Visual cue
                Container(
                  padding: EdgeInsets.all(SizeConfig.size20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    size: 60,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: SizeConfig.paddingXL),

                // Informative Text
                CustomText(
                  "No Payment Method Linked",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.paddingS),
                CustomText(
                  "To withdraw your earnings, please add a bank account or UPI ID. Your details are stored securely for future transactions.",
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            )
          ),


          SizedBox(height: SizeConfig.paddingL), // Pushes the button to the bottom

          // Action Button
          CustomBtn(
            title: "Add Bank Account / UPI",
            radius: 10,
            bgColor: AppColors.primaryColor,
            onTap: () {
              Get.toNamed(
                  RouteHelper
                      .getAddBankAccountScreenRoute())?.then(
                      (_)=> withdrawalMethodApiCall()
              );
            },
          ),
          SizedBox(height: SizeConfig.paddingM),

          // Secondary Action
          InkWell(
            onTap: () => Get.back(),
            child: CustomText(
              "Go Back",
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm(){
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        child: Obx(() {
          bool hasBank = controller.bankList.isNotEmpty;
          bool hasUpi = controller.upiList.isNotEmpty;

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
                      height: SizeConfig.paddingS,
                    ),
                    if (hasBank && hasUpi) ...[
                      CustomText(
                        "Choose Payment method",
                        color: AppColors.black,
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.medium,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonDropdown<String>(
                        items: controller.bankStatus,
                        selectedValue: controller.selectedBank.value,
                        validator: controller.validatePaymentMethod,
                        hintText: 'Select Account',
                        onChanged: (val) {
                          controller.selectedBank.value = val ?? '';
                        },
                        displayValue: (item) => item,
                      ),
                      SizedBox(height: SizeConfig.paddingS),
                    ],

                    SizedBox(height: SizeConfig.paddingS),
                    if(controller.selectedBank.value == "Bank")
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText("Choose Bank"),
                          SizedBox(height: SizeConfig.size12),
                          ...controller.bankList.map((e) =>
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
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          CustomText(
                                              e.bankDetails?.holderName,
                                              color: AppColors.mainTextColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: SizeConfig.medium),
                                          SizedBox(height: SizeConfig.paddingXSL),
                                          Row(mainAxisAlignment: MainAxisAlignment
                                              .spaceBetween,
                                            children: [
                                              CustomText(
                                                e.bankDetails?.accountNo,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.secondaryTextColor,
                                              ),
                                              CustomText(
                                                  e.bankDetails?.bankName,
                                                  color: AppColors.secondaryTextColor
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      if (controller.selectedBankDetails.value == e)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: LocalAssets(
                                            imagePath: AppIconAssets.green_tick_icon,
                                            height: 20,
                                            width: 20,
                                          ),
                                        ),
                                    ]
                                  ),
                                ),
                              )).toList(),
                        ],
                      ),
                    if(controller.selectedBank.value == "UPI")
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText("Choose UPI"),
                          SizedBox(height: SizeConfig.size12),
                          ...controller.upiList.map((e) =>
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
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          CustomText(
                                            e.upiDetails?.bankName,
                                            color: AppColors.mainTextColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: SizeConfig.medium),
                                          SizedBox(height: SizeConfig.paddingXSL),
                                          Row(
                                            children: [
                                              CustomText(
                                                  e.upiDetails?.upiId,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.secondaryTextColor
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      if (controller.selectedBankDetails.value == e)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: LocalAssets(
                                            imagePath: AppIconAssets.green_tick_icon,
                                            height: 20,
                                            width: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )).toList(),
                        ],
                      ),

                    SizedBox(height: SizeConfig.paddingL),
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
                              isValidate: (controller.selectedBank.value == "UPI")
                                          ? controller.selectedUpiDetails.value.id!=null
                                              : controller.selectedBankDetails.value.id!=null,
                              textColor: AppColors.white,
                              radius: 10,
                              isLoading: controller.isLoading.value,
                              onTap: () {
                                if(controller.selectedBank.value == "UPI"
                                    ? controller.selectedUpiDetails.value.id!=null
                                    : controller.selectedBankDetails.value.id!=null){
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
    );
  }



}
