import 'package:BlueEra/features/personal/personal_profile/view/wallet/controller/wallet_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/api/apiService/api_response.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/getx_utils.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/common_back_app_bar.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class SeeAllTransactionsView extends StatefulWidget {
  const SeeAllTransactionsView({super.key});

  @override
  State<SeeAllTransactionsView> createState() => _SeeAllTransactionsViewState();
}

class _SeeAllTransactionsViewState extends State<SeeAllTransactionsView> {
  final controller = getOrPut(() => WalletController());

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((_){
      controller.page++;
      controller.getWalletTransactionApi(isFromFilter: false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if(controller.viewTransactionHistoryResponse.value.status==Status.COMPLETE) {
        return Scaffold(
          appBar:
          CommonBackAppBar(
              title: "Transactions",
              isLeading: true,
              showTransactionFilter: true,
              transactionFilterOnTap: (value) {
                controller.selectedStatus = value;
                Get.back();
                controller.getWalletTransactionApi();
              },
              transactionFilterSelectedValue: controller.selectedStatus
          ),
          body: Container(
            // height: Get.height * 0.8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),),
            margin:
            EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            padding:
            EdgeInsets.all(16),
            child: (controller
                .walletTransactionResponseModalClass.value.data?.isEmpty ?? true)
                ? Center(
              child: CustomText("No Transaction Found"),
            )
                : ListView.separated(
              controller: controller.listScrollController,
              itemCount: (controller.walletTransactionResponseModalClass.value.data?.length ?? 0)
                  + (controller.isMoreDataInList ? 1 : 0),
              itemBuilder: (context, index) {
                final list =
                    controller.walletTransactionResponseModalClass.value.data ?? [];

                // Show bottom loader
                if (index == list.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                var data = list[index];

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          data.source ?? "",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        CustomText(
                          '\u{20B9}${data.amountInRupees ?? 0}',
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
                          data.createdAt != null
                              ? DateFormat('MMM d, hh:mm a')
                              .format(data.createdAt!.toLocal())
                              : "",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
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
                            SizedBox(width: 4),
                            CustomText(
                              data.status == "PENDING" ? "Pending" : "Completed",
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
                );
              },
              separatorBuilder: (context, index) =>
                  SizedBox(
                    height: 20,
                  ),
            ),

          ),
        );
      }else{
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

    });
  }
}
