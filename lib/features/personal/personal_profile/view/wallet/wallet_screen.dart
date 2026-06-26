import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/view/payment_setting_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/amount_withdraw_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/wallet_transaction_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/controller/wallet_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final controller = getOrPut(() => WalletController());

  @override
  void initState() {
    controller.getWalletApi();
    controller.getWalletTransactionApi();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          bool isInitialLoading = controller.viewWalletBalanceResponse.value.status == Status.LOADING ||
              controller.viewTransactionHistoryResponse.value.status == Status.LOADING;

          if (isInitialLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Container(
                height: SizeConfig.size240,
                width: Get.width,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(AppImageAssets.wallet_heater_bg), fit: BoxFit.fill)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: InkWell(
                            onTap: () {
                              Get.back();
                            },
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        CustomText(
                          AppStrings.currentBalance.tr,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 40,
                        )
                      ],
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.walletIcon,
                          height: 26, // reduce icon size
                          width: 26,
                          imgColor: AppColors.white,
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        CustomText(
                          (controller.walletResponseModalClass.value.data?.withdrawableAmount ?? "0")
                              .toString(),
                          fontSize: SizeConfig.heading,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        // Text('\u{20B9}${200}'),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     CustomText(
                    //       'Pending Balance:',
                    //       fontSize: SizeConfig.medium,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //     SizedBox(
                    //       width: 4,
                    //     ),
                    //     CustomText(
                    //       '\u{20B9}controller',
                    //       fontSize: SizeConfig.medium15,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //     SizedBox(
                    //       width: 12,
                    //     ),
                    //     CustomText(
                    //       'Total Earning:',
                    //       fontSize: SizeConfig.medium,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //     SizedBox(
                    //       width: 4,
                    //     ),
                    //     CustomText(
                    //       '\u{20B9}2,500',
                    //       fontSize: SizeConfig.medium15,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white,
                    //     ),
                    //   ],
                    // ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          AppStrings.totalRewardAmount.tr,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        CustomText(
                          '\u{20B9}${(controller.walletResponseModalClass.value.data?.totalRewardAmount ?? "0").toString()}',
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          AppStrings.totalWithdrawals.tr,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        CustomText(
                          '\u{20B9}${(controller.walletResponseModalClass.value.data?.totalWithdrawalAmount ?? "0").toString()}',
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: GestureDetector(
                            onTap: () {
                              Get.to(() => PaymentSettingScreen());
                              // Get.toNamed(RouteHelper.getAddBankAccountScreenRoute());
                            },
                            child: Container(
                              height: SizeConfig.size45,
                              decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.white),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Center(
                                child: CustomText(
                                  AppStrings.addAccount.tr,
                                  fontSize: SizeConfig.medium15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                              Get.to(() => AmountWithdrawScreen())?.then(
                                (value) {
                                  controller.getWalletTransactionApi();
                                  controller.getWalletApi();
                                },
                              );
                            },
                            child: Container(
                              height: SizeConfig.size45,
                              decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.white),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Center(
                                child: CustomText(
                                  AppStrings.withdraw.tr,
                                  fontSize: SizeConfig.medium15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ))
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    // borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    children: [
                      (controller.walletTransactionResponseModalClass.value.data?.isEmpty ?? true)
                          ? Center(
                              child: CustomText(AppStrings.noTransactionFound.tr),
                            )
                          : Expanded(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount:
                                    ((controller.walletTransactionResponseModalClass.value.data?.length) ??
                                        0),
                                itemBuilder: (context, index) {
                                  WalletTransactionResponseModalClassDatum data =
                                      controller.walletTransactionResponseModalClass.value.data![index];
                                  return _customContainer(data: data);
                                },
                                separatorBuilder: (context, index) => SizedBox(
                                  height: 20,
                                ),
                              ),
                            ),
                      SizedBox(
                        height: 8,
                      ),
                      InkWell(
                        onTap: () => Get.toNamed(RouteConstant.allTransactionsScreen),
                        child: CustomText(
                          AppStrings.seeAllTransactions.tr,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          color: AppColors.skyBlueDF,
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          );
        }),
      ),
    );
  }

  Widget _customContainer({required WalletTransactionResponseModalClassDatum data}) {
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                data.source,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              CustomText(
                '\u{20B9}${data.amountInRupees}',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                DateFormat(
                  'MMM d, hh:mm a',
                ).format(data.createdAt!.toLocal()),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
              ),
              Row(
                children: [
                  data.status == "PENDING"
                      ? Icon(
                          Icons.watch_later_outlined,
                          color: AppColors.orange,
                          size: 14,
                        )
                      : Icon(
                          Icons.check_circle_outline_outlined,
                          color: AppColors.green39,
                          size: 14,
                        ),
                  SizedBox(
                    width: 4,
                  ),
                  CustomText(
                    data.status == "PENDING" ? "Pending" : 'Completed',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: data.status == "PENDING" ? AppColors.orange : AppColors.green39,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
