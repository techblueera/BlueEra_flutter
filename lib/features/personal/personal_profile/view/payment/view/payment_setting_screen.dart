import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/getx_utils.dart';
import '../../../../../../core/routes/route_helper.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../widget/upi_qr_widget.dart';

class PaymentSettingScreen extends StatefulWidget {
  const PaymentSettingScreen({super.key});

  @override
  State<PaymentSettingScreen> createState() => _PaymentSettingScreenState();
}

class _PaymentSettingScreenState extends State<PaymentSettingScreen> {
  final controller = getOrPut(() => WalletController());

  @override
  void initState() {
    controller.getAllWithdrawalMethods();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: const CommonBackAppBar(
        title: AppStrings.paymentSetting,
        isLeading: true,
      ),
      body: Obx(() {
        final banks = controller.bankListModel.value.data ?? [];
        final upis = controller.upiListModel.value.data ?? [];

        /// LOADING
        if (controller.isMethodsLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        /// EMPTY STATE — no bank accounts AND no UPI IDs
        if (banks.isEmpty && upis.isEmpty) {
          return _buildEmptyState();
        }

        /// LIST
        return Column(
          children: [
            /// HEADER
            _buildHeader(banks.length + upis.length),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// BANK ACCOUNTS
                    if (banks.isNotEmpty) ...[
                      _sectionLabel(AppStrings.bankAccounts),
                      ..._buildBankList(controller),
                    ],

                    /// UPI IDs
                    if (upis.isNotEmpty) ...[
                      _sectionLabel(AppStrings.upiIds),
                      ..._buildUpiList(controller),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Polished list header: title + saved-count on the left, a tinted "Add"
  /// pill on the right.
  Widget _buildHeader(int count) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size16,
        SizeConfig.size8,
      ),
      color: AppColors.appBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.savedPaymentMethods,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: 2),
                CustomText(
                  "$count ${count == 1 ? AppStrings.methodSaved.tr : AppStrings.methodsSaved.tr}",
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grayText,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _openAddBankAccount,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size14,
                vertical: SizeConfig.size8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: AppColors.primaryColor),
                  SizedBox(width: 4),
                  CustomText(
                    AppStrings.addAccount,
                    fontSize: SizeConfig.size14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddBankAccount() {
    Get.toNamed(
      RouteHelper.getAddBankAccountScreenRoute(),
    )?.then((val) {
      controller.getAllWithdrawalMethods();
    });
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(
        top: SizeConfig.size4,
        bottom: SizeConfig.size12,
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.size14,
        fontWeight: FontWeight.w600,
        color: AppColors.mainTextColor,
      ),
    );
  }

  /// =========================
  /// EMPTY STATE (NO BANK ACCOUNTS)
  /// =========================
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.08),
              ),
              child: Center(
                child: Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    size: 38,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size24),
            CustomText(
              "No Bank Account Added",
              fontSize: SizeConfig.size18,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              "Add a bank account to receive your withdrawals quickly and securely.",
              fontSize: SizeConfig.size14,
              fontWeight: FontWeight.w400,
              color: AppColors.grayText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size28),
            InkWell(
              onTap: _openAddBankAccount,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size28,
                  vertical: SizeConfig.size14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: AppColors.white),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      AppStrings.addBankAccount,
                      fontSize: SizeConfig.size15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  List<Widget> _buildUpiList(WalletController controller) {
    return [
      ...controller.upiListModel.value.data?.map((e) => _upiCard(
            upiId: e.upiDetails?.upiId ?? '',
            bankName: e.upiDetails?.bankName ?? '',
            mobileNumber: e.upiDetails?.mobileNumber ?? '',
            onTapDefault: () {},
            onViewQr: () => showUpiQrDialog(
              upiId: e.upiDetails?.upiId ?? '',
              bankName: e.upiDetails?.bankName ?? '',
            ),
          )) ??
          [],
    ];
  }

  /// =========================
  /// UPI CARD
  /// =========================
  Widget _upiCard({
    required String upiId,
    required String bankName,
    required String mobileNumber,
    required VoidCallback onTapDefault,
    required VoidCallback onViewQr,
  }) {
    // New UPIs store a linked mobile number in place of bank name; fall back to
    // bankName (older records) then a generic label.
    final title = mobileNumber.isNotEmpty
        ? mobileNumber
        : (bankName.isNotEmpty ? bankName : AppStrings.upiId);
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
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      fontSize: SizeConfig.size16,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 2),
                    CustomText(
                      "UPI",
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grayText,
                    ),
                  ],
                ),
              ),
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFE),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE5E5E5),
                    width: 0.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
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
                    PopupMenuItem(
                      value: "default",
                      child: Text(AppStrings.setAsDefault.tr),
                    ),
                  ],
                ),
              )
            ],
          ),

          SizedBox(height: SizeConfig.size8),

          /// UPI ID box
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.boxBg),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size14,
                vertical: SizeConfig.size12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          AppStrings.upiId,
                          fontSize: SizeConfig.size12,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 4),
                        CustomText(
                          upiId,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onViewQr,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.all(SizeConfig.size4),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_2,
                              size: 20, color: AppColors.primaryColor),
                          SizedBox(width: 4),
                          CustomText(
                            AppStrings.viewQr,
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
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
                      color: Colors.black.withValues(alpha: 0.08),
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
                    PopupMenuItem(
                      value: "default",
                      child: Text(AppStrings.setAsDefault.tr),
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
                      AppStrings.accountNoLabel,
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
                      AppStrings.ifscCodeLabel,
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

}