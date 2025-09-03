import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/see_all_transaction_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class SeeAllTransactionsView extends StatelessWidget {
  const SeeAllTransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SeeAllTransactionController>(
        init: SeeAllTransactionController(),
        builder: (controller) {
          return Scaffold(
            appBar:
                //  CommonBackAppBar(
                //   title: "Transactions",
                //   isLeading: true,

                // ),
                AppBar(
              surfaceTintColor: AppColors.white,
              title: Text("Transactions"),
              leading: InkWell(
                onTap: () => Get.back(),
                child: Icon(Icons.arrow_back_ios),
              ),
              actions: [
                PopupMenuButton<int>(
                    icon: SvgPicture.asset(AppIconAssets.filterIcon),
                    onSelected: (value) {},
                    itemBuilder: (context) => [
                          // PopupMenuItem(
                          //     value: 1,
                          //     child: ExpansionTile(
                          //       expandedAlignment: Alignment.centerLeft,
                          //       childrenPadding: EdgeInsets.zero,
                          //       expandedCrossAxisAlignment:
                          //           CrossAxisAlignment.start,
                          //       title: CustomText(
                          //         "Date",
                          //         color: AppColors.black,
                          //         fontWeight: FontWeight.w600,
                          //         fontSize: SizeConfig.medium15,
                          //       ),
                          //       children: [
                          //         CustomText(
                          //           "Last 30 days",
                          //           color: AppColors.black,
                          //           fontWeight: FontWeight.w400,
                          //           fontSize: SizeConfig.medium,
                          //         ),
                          //         Divider(),
                          //         CustomText(
                          //           "Last 60 days",
                          //           color: AppColors.black,
                          //           fontWeight: FontWeight.w400,
                          //           fontSize: SizeConfig.medium,
                          //         ),
                          //         Divider(),
                          //         CustomText(
                          //           "Last 90 days",
                          //           color: AppColors.black,
                          //           fontWeight: FontWeight.w400,
                          //           fontSize: SizeConfig.medium,
                          //         ),
                          //       ],
                          //     )),
                          PopupMenuItem(
                              value: 1,
                              child: ExpansionTile(
                                expandedAlignment: Alignment.centerLeft,
                                childrenPadding: EdgeInsets.zero,
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.start,
                                title: CustomText(
                                  "Status",
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: SizeConfig.medium15,
                                ),
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          controller.selectedStatus =
                                              "SUCCESSFUL";
                                          Get.back();
                                          controller.update();
                                          controller.getWalletTransactionApi();
                                        },
                                        child: CustomText(
                                          "SUCCESSFUL",
                                          textAlign: TextAlign.left,
                                          color: controller.selectedStatus ==
                                                  "SUCCESSFUL"
                                              ? AppColors.green39
                                              : AppColors.black,
                                          fontWeight: FontWeight.w400,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                      controller.selectedStatus == "SUCCESSFUL"
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: InkWell(
                                                onTap: () {
                                                  controller.selectedStatus =
                                                      null;
                                                  controller.update();
                                                  controller
                                                      .getWalletTransactionApi();
                                                  Get.back();
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          : SizedBox()
                                    ],
                                  ),
                                  Divider(),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          controller.selectedStatus = "FAILED";
                                          Get.back();
                                          controller.update();
                                          controller.getWalletTransactionApi();
                                        },
                                        child: CustomText(
                                          "FAILED",
                                          textAlign: TextAlign.left,
                                          color: controller.selectedStatus ==
                                                  "FAILED"
                                              ? AppColors.green39
                                              : AppColors.black,
                                          fontWeight: FontWeight.w400,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                      controller.selectedStatus == "FAILED"
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: InkWell(
                                                onTap: () {
                                                  controller.selectedStatus =
                                                      null;
                                                  controller.update();
                                                  controller
                                                      .getWalletTransactionApi();
                                                  Get.back();
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          : SizedBox()
                                    ],
                                  ),
                                  Divider(),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          controller.selectedStatus = "PENDING";
                                          Get.back();
                                          controller.update();
                                          controller.getWalletTransactionApi();
                                        },
                                        child: CustomText(
                                          "PENDING",
                                          color: controller.selectedStatus ==
                                                  "PENDING"
                                              ? AppColors.green39
                                              : AppColors.black,
                                          fontWeight: FontWeight.w400,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                      controller.selectedStatus == "PENDING"
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: InkWell(
                                                onTap: () {
                                                  controller.selectedStatus =
                                                      null;
                                                  controller.update();
                                                  controller
                                                      .getWalletTransactionApi();
                                                  Get.back();
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          : SizedBox()
                                    ],
                                  ),
                                  Divider(),
                                ],
                              )),
                          PopupMenuItem(
                              value: 2,
                              child: ExpansionTile(
                                expandedAlignment: Alignment.centerLeft,
                                childrenPadding: EdgeInsets.zero,
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.start,
                                title: CustomText(
                                  "Type",
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: SizeConfig.medium15,
                                ),
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          controller.selectedType = "CREDIT";
                                          Get.back();
                                          controller.update();
                                          controller.getWalletTransactionApi();
                                        },
                                        child: CustomText(
                                          "CREDIT",
                                          textAlign: TextAlign.left,
                                          color: controller.selectedType ==
                                                  "CREDIT"
                                              ? AppColors.green39
                                              : AppColors.black,
                                          fontWeight: FontWeight.w400,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                      controller.selectedType == "CREDIT"
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: InkWell(
                                                onTap: () {
                                                  controller.selectedType =
                                                      null;
                                                  controller.update();
                                                  controller
                                                      .getWalletTransactionApi();
                                                  Get.back();
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          : SizedBox()
                                    ],
                                  ),
                                  Divider(),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          controller.selectedType = "DEBIT";
                                          Get.back();
                                          controller.update();
                                          controller.getWalletTransactionApi();
                                        },
                                        child: CustomText(
                                          "DEBIT",
                                          textAlign: TextAlign.left,
                                          color:
                                              controller.selectedType == "DEBIT"
                                                  ? AppColors.green39
                                                  : AppColors.black,
                                          fontWeight: FontWeight.w400,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                      controller.selectedType == "DEBIT"
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: InkWell(
                                                onTap: () {
                                                  controller.selectedType =
                                                      null;
                                                  controller.update();
                                                  controller
                                                      .getWalletTransactionApi();
                                                  Get.back();
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          : SizedBox()
                                    ],
                                  ),
                                  Divider(),
                                ],
                              )),
                          PopupMenuItem(
                              value: 3,
                              child: ExpansionTile(
                                expandedAlignment: Alignment.centerLeft,
                                childrenPadding: EdgeInsets.zero,
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.start,
                                title: CustomText(
                                  "Source",
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: SizeConfig.medium15,
                                ),
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          controller.selectedSource = "REWARD";
                                          Get.back();
                                          controller.update();
                                          controller.getWalletTransactionApi();
                                        },
                                        child: CustomText(
                                          "REWARD",
                                          textAlign: TextAlign.left,
                                          color: controller.selectedSource ==
                                                  "REWARD"
                                              ? AppColors.green39
                                              : AppColors.black,
                                          fontWeight: FontWeight.w400,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                      controller.selectedSource == "REWARD"
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: InkWell(
                                                onTap: () {
                                                  controller.selectedSource =
                                                      null;
                                                  controller.update();
                                                  controller
                                                      .getWalletTransactionApi();
                                                  Get.back();
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          : SizedBox()
                                    ],
                                  ),
                                  Divider(),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          controller.selectedSource =
                                              "WITHDRAWAL";
                                          Get.back();
                                          controller.update();
                                          controller.getWalletTransactionApi();
                                        },
                                        child: CustomText(
                                          "WITHDRAWAL",
                                          textAlign: TextAlign.left,
                                          color: controller.selectedSource ==
                                                  "WITHDRAWAL"
                                              ? AppColors.green39
                                              : AppColors.black,
                                          fontWeight: FontWeight.w400,
                                          fontSize: SizeConfig.medium,
                                        ),
                                      ),
                                      controller.selectedSource == "WITHDRAWAL"
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: InkWell(
                                                onTap: () {
                                                  controller.selectedSource =
                                                      null;
                                                  controller.update();
                                                  controller
                                                      .getWalletTransactionApi();
                                                  Get.back();
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                              ),
                                            )
                                          : SizedBox()
                                    ],
                                  ),
                                  Divider(),
                                ],
                              )),
                        ]),
              ],
            ),
            body: Container(
              height: Get.height * 0.8,
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
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
              child: ListView.separated(
                controller: controller.listScrollController,
                itemCount: ((controller
                        .walletTransactionResponseModalClass?.data?.length) ??
                    0),
                itemBuilder: (context, index) {
                  var data = controller
                      .walletTransactionResponseModalClass!.data![index];
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
                              DateFormat('MMM d, hh:mm a')
                                  .format(data.createdAt!.toLocal()),
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
                                  data.status == "PENDING"
                                      ? "Pending"
                                      : 'Completed',
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
                  ;
                },
                separatorBuilder: (context, index) => SizedBox(
                  height: 20,
                ),
              ),

              // ListView.builder(
              //   itemBuilder: (context, index) {
              //     return Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 16),
              //       child: Column(
              //         children: [
              //           Row(
              //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              //               return Container(
              //                 child: Column(
              //                   children: [
              //                     Row(
              //                       mainAxisAlignment:
              //                           MainAxisAlignment.spaceBetween,
              //                       children: [
              //                         CustomText(
              //                           'Refer',
              //                           fontSize: SizeConfig.medium,
              //                           fontWeight: FontWeight.w600,
              //                           color: Colors.black,
              //                         ),
              //                         CustomText(
              //                           '\u{20B9}${200}',
              //                           fontSize: SizeConfig.medium,
              //                           fontWeight: FontWeight.w400,
              //                           color: AppColors.grayText,
              //                         ),
              //                       ],
              //                     ),
              //                     Row(
              //                       mainAxisAlignment:
              //                           MainAxisAlignment.spaceBetween,
              //                       children: [
              //                         CustomText(
              //                           'Oct 19, 05:45 AM',
              //                           fontSize: SizeConfig.medium,
              //                           fontWeight: FontWeight.w400,
              //                           color: AppColors.grayText,
              //                         ),
              //                         Row(
              //                           children: [
              //                             index == 4
              //                                 ? Icon(
              //                                     Icons.watch_later_outlined,
              //                                     color: AppColors.orange,
              //                                     size: 16,
              //                                   )
              //                                 : Icon(
              //                                     Icons
              //                                         .check_circle_outline_outlined,
              //                                     color: AppColors.green39,
              //                                     size: 16,
              //                                   ),
              //                             SizedBox(
              //                               width: 4,
              //                             ),
              //                             CustomText(
              //                               index == 4 ? "Pending" : 'Completed',
              //                               fontSize: SizeConfig.medium,
              //                               fontWeight: FontWeight.w400,
              //                               color: index == 4
              //                                   ? AppColors.orange
              //                                   : AppColors.green39,
              //                             ),
              //                           ],
              //                         ),
              //                       ],
              //                     ),
              //                   ],
              //                 ),
              //               );
              //             },
              //             separatorBuilder: (context, index) => SizedBox(
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
          );
        });
  }
}
