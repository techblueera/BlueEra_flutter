import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';

import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/getx_utils.dart';
import '../../../../../../core/constants/snackbar_helper.dart';
import '../../../../../../features/personal/personal_profile/view/wallet/model/wallet_withdrawal_methods.dart';
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
    // WalletController is a shared (getOrPut) instance, so its amountController
    // keeps whatever was typed last time. Clear it so the field starts empty.
    controller.amountController.clear();
    controller.enteredAmount.value = '';
    withdrawalMethodApiCall();
    // Needed to show the available balance and cap the withdrawal amount.
    controller.getWalletApi();
  }

  void withdrawalMethodApiCall(){
    controller.getWalletWithdrawalMethodApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No scaffold colour — the app-wide background (colour or banner) painted
      // by AppHomeBackground shows through the transparent scaffold. The form's
      // own white cards/buttons sit opaque on top. See AppBackgroundScreen.
      appBar: CommonBackAppBar(
        title: 'Amount to Withdraw',
        isLeading: true,
        buildCustomActionWidget: () => _addAccountAction(),
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

  Widget _buildWithdrawalForm() {
    return Form(
      key: controller.formKey,
      child: Obx(() {
        final bool hasBank = controller.bankList.isNotEmpty;
        final bool hasUpi = controller.upiList.isNotEmpty;
        final bool showToggle = hasBank && hasUpi;
        final bool isBank = controller.selectedBank.value == "Bank";
        final accounts = isBank ? controller.bankList : controller.upiList;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(SizeConfig.size16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _amountField(),
                SizedBox(height: SizeConfig.size10),
                _availableBalance(),
                SizedBox(height: SizeConfig.size20),
                if (showToggle) ...[
                  _sectionLabel("Withdraw to"),
                  SizedBox(height: SizeConfig.size10),
                  _methodToggle(),
                  SizedBox(height: SizeConfig.size16),
                ],
                _sectionLabel(isBank ? "Choose bank account" : "Choose UPI ID"),
                SizedBox(height: SizeConfig.size12),
                ...accounts.map((e) => isBank ? _bankTile(e) : _upiTile(e)),
                SizedBox(height: SizeConfig.size24),
                _actionButtons(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Amount field ──────────────────────────────────────────────────────────
  // Uses the app's standard CommonTextField layout (title + white rounded box)
  // so it matches every other input in the product.
  Widget _amountField() {
    return CommonTextField(
      title: "Enter Amount",
      textEditController: controller.amountController,
      hintText: 'E.g. 100, 200, 300',
      keyBoardType: const TextInputType.numberWithOptions(decimal: true),
      validator: controller.amountValidate,
      prefixText: '₹ ',
      onChange: (val) => controller.enteredAmount.value = val,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
    );
  }

  // Shows the withdrawable balance and a one-tap "Use Max" to fill the field.
  // The amount validator caps any entry at this value.
  Widget _availableBalance() {
    final balance =
        controller.walletResponseModalClass.value.data?.withdrawableAmount ?? 0;
    return Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 15, color: AppColors.secondaryTextColor),
        const SizedBox(width: 6),
        CustomText(
          "Available balance: ",
          fontSize: 12.5,
          color: AppColors.secondaryTextColor,
        ),
        CustomText(
          "₹$balance",
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            controller.amountController.text = balance.toString();
            controller.amountController.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.amountController.text.length),
            );
            controller.enteredAmount.value = balance.toString();
          },
          child: CustomText(
            "Use Max",
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return CustomText(
      text,
      fontSize: SizeConfig.medium,
      fontWeight: FontWeight.w700,
      color: AppColors.mainTextColor,
    );
  }

  // ── Bank / UPI segmented toggle ───────────────────────────────────────────
  Widget _methodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _toggleSegment("Bank", Icons.account_balance_rounded, "Bank"),
          _toggleSegment("UPI", Icons.qr_code_rounded, "UPI"),
        ],
      ),
    );
  }

  Widget _toggleSegment(String label, IconData icon, String value) {
    final bool selected = controller.selectedBank.value == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.selectedBank.value = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    selected ? AppColors.primaryColor : AppColors.secondaryTextColor,
              ),
              const SizedBox(width: 6),
              CustomText(
                label,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color:
                    selected ? AppColors.primaryColor : AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Account tiles ─────────────────────────────────────────────────────────
  Widget _bankTile(WithdrawalMethodData e) {
    final bool selected = controller.selectedBankDetails.value == e;
    final bank = e.bankDetails;
    final subtitle = [
      _maskAccount(bank?.accountNo),
      if ((bank?.bankName ?? '').isNotEmpty) bank!.bankName,
    ].where((s) => (s ?? '').isNotEmpty).join("   •   ");
    return _accountTile(
      selected: selected,
      icon: Icons.account_balance_rounded,
      title: (bank?.holderName ?? '').isNotEmpty ? bank!.holderName! : "Bank account",
      subtitle: subtitle,
      isDefault: e.isDefault ?? false,
      onTap: () => controller.selectedBankDetails.value = e,
    );
  }

  Widget _upiTile(WithdrawalMethodData e) {
    // Selection is tracked separately from bank — this tile reflects the UPI
    // selection (the earlier version mistakenly read the bank selection here).
    final bool selected = controller.selectedUpiDetails.value == e;
    final upi = e.upiDetails;
    final title = (upi?.bankName ?? '').isNotEmpty
        ? upi!.bankName!
        : (upi?.upiId ?? "UPI ID");
    return _accountTile(
      selected: selected,
      icon: Icons.qr_code_rounded,
      title: title,
      subtitle: upi?.upiId ?? '',
      isDefault: e.isDefault ?? false,
      onTap: () => controller.selectedUpiDetails.value = e,
    );
  }

  Widget _accountTile({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDefault,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.all(SizeConfig.size12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryColor.withValues(alpha: 0.06)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primaryColor : AppColors.greyE5,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryColor.withValues(alpha: 0.12)
                        : AppColors.fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor,
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: CustomText(
                              title,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 6),
                            _defaultBadge(),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        CustomText(
                          subtitle,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _radio(selected),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        "DEFAULT",
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _radio(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.primaryColor
              : AppColors.secondaryTextColor.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor,
                ),
              ),
            )
          : null,
    );
  }

  // App-bar action: a filled primary button to add a new bank/UPI method,
  // then refresh the list on return.
  Widget _addAccountAction() {
    return Padding(
      padding: EdgeInsets.only(right: SizeConfig.size12),
      child: Material(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Get.toNamed(RouteHelper.getAddBankAccountScreenRoute())
              ?.then((_) => withdrawalMethodApiCall()),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 18, color: AppColors.white),
                const SizedBox(width: 4),
                CustomText(
                  "Add Account",
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────
  // Stacked in a column at the end of the form content (not pinned to the
  // bottom of the screen).
  Widget _actionButtons() {
    final bool methodSelected = controller.selectedBank.value == "UPI"
        ? controller.selectedUpiDetails.value.id != null
        : controller.selectedBankDetails.value.id != null;
    // Enabled only with both a valid amount (within balance) AND a method.
    final bool canWithdraw =
        methodSelected && controller.isAmountWithinBalance;
    return Column(
      children: [
        CustomBtn(
          isValidate: canWithdraw,
          textColor: AppColors.white,
          radius: 12,
          isLoading: controller.isLoading.value,
          onTap: () {
            // Surface the amount error inline first (empty / >balance / invalid).
            final bool amountOk =
                controller.formKey.currentState?.validate() ?? false;
            if (!methodSelected) {
              commonSnackBar(message: "Choose a payment method");
              return;
            }
            if (!amountOk) return;
            controller.WithdrawalApi();
          },
          title: "Withdraw",
        ),
        SizedBox(height: SizeConfig.size12),
        CustomBtn(
          onTap: () => Get.back(),
          bgColor: AppColors.white,
          textColor: AppColors.secondaryTextColor,
          borderColor: AppColors.greyE5,
          radius: 12,
          title: "Cancel",
        ),
      ],
    );
  }

  /// Masks all but the last four digits of an account number — a small
  /// fintech courtesy that also keeps the subtitle short.
  String _maskAccount(String? account) {
    final acc = (account ?? '').trim();
    if (acc.isEmpty) return '';
    if (acc.length <= 4) return acc;
    return '•••• ${acc.substring(acc.length - 4)}';
  }
}
