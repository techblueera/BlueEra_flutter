import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/controller/payment_setting_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentSettingScreen extends StatelessWidget {
  const PaymentSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentSettingController>(
      init: PaymentSettingController(),
      builder: (controller) {
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
                      onTap: () =>
                          controller.addBankAccount(),
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


              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16),
                  child: Column(
                    children: _buildBankList(controller),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  List<Widget> _buildBankList(
      PaymentSettingController controller) {
    final apiData =
        controller.getAccountResponseModalClass?.data;

    if (apiData != null && apiData.isNotEmpty) {
      return apiData
          .where((e) => e.type?.toUpperCase() == "BANK")
          .map((e) => _bankCard(
        bankName: e.bankName ?? "",
        accountNo: e.accountNumber ?? "",
        ifsc: e.ifscCode ?? "",
        isDefault: e.isDefault ?? false,
        color: _getColor(e.bankName ?? ""),
        onTapDefault: () => controller
            .setAccountAsDefault(id: e.id ?? ""),
      ))
          .toList();
    }

    return [
      _bankCard(
        bankName: "State Bank Of India",
        accountNo: "1234567894",
        ifsc: "SBIN7878DG",
        isDefault: true,
        color: Colors.blue,
        onTapDefault: () {},
      ),
      _bankCard(
        bankName: "ICICI Bank",
        accountNo: "1234567894",
        ifsc: "ICICI7878DG",
        isDefault: false,
        color: Colors.red,
        onTapDefault: () {},
      ),
      _bankCard(
        bankName: "HDFC Bank",
        accountNo: "1234567894",
        ifsc: "HDFC7878DG",
        isDefault: false,
        color: Colors.indigo,
        onTapDefault: () {},
      ),
    ];
  }

  /// =========================
  /// CARD DESIGN (STATIC STYLE)
  /// =========================
  Widget _bankCard({
    required String bankName,
    required String accountNo,
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
                    bankName.isNotEmpty
                        ? bankName[0]
                        : "B",
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              SizedBox(width: SizeConfig.size12),

              Expanded(
                child: Row(
                  children: [
                    CustomText(
                      bankName,
                      fontSize: SizeConfig.size20,
                      fontWeight: FontWeight.w400,
                    ),
                    if (isDefault) ...[
                      SizedBox(width: 6),
                      CustomText(
                        "(Default)",
                        fontSize: SizeConfig.size16,
                        color: Colors.grey,
                      ),
                    ]
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
                  itemBuilder: (context) => [
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
              ),                  child: Column(
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
               color:AppColors.boxBg ,
               height: 56,width: 1,
             ),
             Padding(
             padding: EdgeInsets.symmetric(
               horizontal: SizeConfig.size14,
               vertical: SizeConfig.size12,
             ),               child: Column(
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