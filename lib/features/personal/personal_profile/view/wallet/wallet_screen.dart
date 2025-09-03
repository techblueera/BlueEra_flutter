import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/amount_withdraw_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/see_all_transactions.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/wallet_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/wallet_transaction_response.dart';

import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
        init: WalletController(),
        builder: (controller) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: SizeConfig.size250,
                    width: Get.width,
                    color: AppColors.primaryColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          'Current Balance',
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppIconAssets.walletIcon,
                              height: 26, // reduce icon size
                              width: 26,
                              color: AppColors.white,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            CustomText(
                              (controller.walletResponseModalClass?.data
                                          ?.withdrawableAmount ??
                                      "0")
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
                              'Total Reword Amount',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            CustomText(
                              '\u{20B9}${(controller.walletResponseModalClass?.data?.totalRewardAmount ?? "0").toString()}',
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
                              'Total Withdrawals',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            CustomText(
                              '\u{20B9}${(controller.walletResponseModalClass?.data?.totalWithdrawalAmount ?? "0").toString()}',
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
                                  Get.toNamed(
                                      RouteHelper.getAddAccountScreenRoute());
                                },
                                child: Container(
                                  height: SizeConfig.size45,
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.white),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Center(
                                    child: CustomText(
                                      'Add Account',
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
                                      controller.getwalletApi();
                                    },
                                  );
                                },
                                child: Container(
                                  height: SizeConfig.size45,
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.white),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Center(
                                    child: CustomText(
                                      'Withdraw',
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
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.colorBorder,
                                blurRadius: 4,
                                spreadRadius: 4)
                          ]),
                      margin:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: ((controller
                                      .walletTransactionResponseModalClass
                                      ?.data
                                      ?.length) ??
                                  0),
                              itemBuilder: (context, index) {
                                WalletTransactionResponseModalClassDatum data =
                                    controller
                                        .walletTransactionResponseModalClass!
                                        .data![index];
                                return _customContainer(data: data);
                              },
                              separatorBuilder: (context, index) => SizedBox(
                                height: 20,
                              ),
                            ),

                            //  ListView.builder(
                            //   itemBuilder: (context, index) {
                            //     return Padding(
                            //       padding: const EdgeInsets.symmetric(horizontal: 16),
                            //       child: Column(
                            //         children: [
                            //           Row(
                            //             mainAxisAlignment:
                            //                 MainAxisAlignment.spaceBetween,
                            //             children: [
                            //               CustomText(
                            //                 'October,2025',
                            //                 fontSize: SizeConfig.large18,
                            //                 fontWeight: FontWeight.w600,
                            //                 color: Colors.black,
                            //               ),
                            //               CustomText(
                            //                 '\u{20B9}${200}',
                            //                 fontSize: SizeConfig.large18,
                            //                 fontWeight: FontWeight.w600,
                            //                 color: Colors.black,
                            //               ),
                            //             ],
                            //           ),
                            //           SizedBox(
                            //             height: 12,
                            //           ),
                            //           ListView.separated(
                            //             shrinkWrap: true,
                            //             physics: NeverScrollableScrollPhysics(),
                            //             itemCount: 5,
                            //             itemBuilder: (context, index) {
                            //               return _customContainer(index: index);
                            //             },
                            //             separatorBuilder: (context, index) =>
                            //                 SizedBox(
                            //               height: 20,
                            //             ),
                            //           ),
                            //           SizedBox(
                            //             height: 38,
                            //           ),
                            //         ],
                            //       ),
                            //     );
                            //     // _customContainer();
                            //   },
                            // ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          InkWell(
                            onTap: () => Get.toNamed(
                                RouteConstant.allTransactionsScreen),
                            child: CustomText(
                              "See all transactions",
                              decoration: TextDecoration.underline,
                              color: AppColors.skyBlueDF,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  Widget _customContainer(
      {required WalletTransactionResponseModalClassDatum data}) {
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                data.source,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              CustomText(
                '\u{20B9}${data.amountInRupees}',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
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
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color: AppColors.grayText,
              ),
              Row(
                children: [
                  data.status == "PENDING"
                      ? Icon(
                          Icons.watch_later_outlined,
                          color: AppColors.orange,
                          size: 16,
                        )
                      : Icon(
                          Icons.check_circle_outline_outlined,
                          color: AppColors.green39,
                          size: 16,
                        ),
                  SizedBox(
                    width: 4,
                  ),
                  CustomText(
                    data.status == "PENDING" ? "Pending" : 'Completed',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: data.status == "PENDING"
                        ? AppColors.orange
                        : AppColors.green39,
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
