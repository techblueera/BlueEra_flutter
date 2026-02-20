import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/controller/payment_setting_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/apiService/api_keys.dart';
import '../../../../../../core/constants/getx_utils.dart';
import '../../../../../../core/routes/route_helper.dart';
import '../../wallet/controller/wallet_controller.dart';

class PaymentSettingScreen extends StatefulWidget {
  const PaymentSettingScreen({super.key});

  @override
  State<PaymentSettingScreen> createState() => _PaymentSettingScreenState();
}

class _PaymentSettingScreenState extends State<PaymentSettingScreen> {
  final controller = getOrPut(() => WalletController());

  @override
  void initState() {
    // TODO: implement initState
    controller.getWalletWithdrawalMethod({
      ApiKeys.methodType: "BANK"
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: const CommonBackAppBar(
        title: "Payment Setting",
        isLeading: true,
      ),
      body: Column(
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size12,
            ),
            color: AppColors.appBackgroundColor,
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "All Bank Accounts",
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w400,
                ),
                InkWell(
                  onTap: () {
                    Get.toNamed(
                      RouteHelper.getAddBankAccountScreenRoute(),
                    )?.then((val){
                      controller.getWalletWithdrawalMethod({
                        ApiKeys.methodType: "BANK"
                      });
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.add,
                          size: 18,
                          color: AppColors.primaryColor),
                      SizedBox(width: 4),
                      CustomText(
                        "Add Account",
                        fontSize: SizeConfig.size14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),


          Obx(() {
            return Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16),
                child: Column(
                  children: _buildBankList(controller),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildBankList(WalletController controller) {
    return [
      ...controller.bankListModel.value.data?.map((e) =>
          _bankCard(
            holderName: e.bankDetails?.holderName??'',
            bankName: e.bankDetails?.bankName ?? '',
            accountNo: e.bankDetails?.accountNo ?? '',
            ifsc: e.bankDetails?.ifscCode ?? '',
            isDefault: true,
            color: Colors.blue,
            onTapDefault: () {},
          )).toList() ?? [],

    ];
  }

  /// =========================
  /// CARD DESIGN (STATIC STYLE)
  /// =========================
  Widget _bankCard({
    required String bankName,
    required String accountNo,
    required String holderName,
    required String ifsc,
    required bool isDefault,
    required Color color,
    required VoidCallback onTapDefault,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size16),
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [

          /// Top Row
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomText(
                    holderName.isNotEmpty
                        ? holderName[0]
                        : "B",
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              SizedBox(width: SizeConfig.size12),

              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText("${holderName}",
                      fontSize: SizeConfig.size20,
                      fontWeight: FontWeight.w500,
                    ),
                    Row(
                      children: [
                        CustomText(
                          bankName,
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grayText,
                        ),
                        // if (isDefault) ...[
                        //   SizedBox(width: 6),
                        //   CustomText(
                        //     "(Default)",
                        //     fontSize: SizeConfig.size12,
                        //     color: Colors.grey,
                        //   ),
                        // ]
                      ],
                    ),

                  ],
                ),
              ),

              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFE), // background
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE5E5E5),
                    width: 0.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.black87,
                  ),
                  onSelected: (value) {
                    if (value == "default") {
                      onTapDefault();
                    }
                  },
                  itemBuilder: (context) =>
                  [
                    const PopupMenuItem(
                      value: "default",
                      child: Text("Set as Default"),
                    ),
                  ],
                ),
              )
            ],
          ),

          SizedBox(height: SizeConfig.size8),


          Container(
            // padding: EdgeInsets.symmetric(
            //   horizontal: SizeConfig.size14,
            //   vertical: SizeConfig.size12,
            // ),
            decoration: BoxDecoration(
              // color: Colors.grey.shade100,
              border: Border.all(color: AppColors.boxBg),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size14,
                    vertical: SizeConfig.size12,
                  ), child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "Account No.",
                      fontSize: SizeConfig.size12,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 4),
                    CustomText(
                      accountNo,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                ),
                Container(
                  color: AppColors.boxBg,
                  height: 56, width: 1,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size14,
                    vertical: SizeConfig.size12,
                  ), child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "IFSC Code",
                      fontSize: SizeConfig.size12,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 4),
                    CustomText(
                      ifsc,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Color _getColor(String name) {
    if (name.contains("State")) return Colors.blue;
    if (name.contains("ICICI")) return Colors.red;
    if (name.contains("HDFC")) return Colors.indigo;
    return AppColors.primaryColor;
  }
}