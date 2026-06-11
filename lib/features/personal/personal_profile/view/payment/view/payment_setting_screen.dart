import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/getx_utils.dart';
import '../../../../../../core/routes/route_helper.dart';
import '../../wallet/controller/wallet_controller.dart';
import '../../wallet/model/bank_details_model.dart';
import '../../wallet/model/upi_details_model.dart';
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
      backgroundColor: Colors.transparent,
      appBar: const CommonBackAppBar(
        title: AppStrings.paymentSetting,
        isLeading: true,
      ),
      body: Obx(() {
        final banks = controller.bankListModel.value.data ?? [];
        final upis = controller.upiListModel.value.data ?? [];

        /// LOADING — card-shaped shimmer that mirrors the real list.
        if (controller.isMethodsLoading.value) {
          return _buildShimmerLoading();
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
      // Only re-fetch when a method was actually added (the add screen returns
      // `true` on success) — not on every back-press.
      if (val == true) controller.getAllWithdrawalMethods();
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

  /// =========================
  /// LOADING SHIMMER
  /// =========================
  Widget _buildShimmerLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header placeholder (title + count + add pill).
        Padding(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size16,
            SizeConfig.size16,
            SizeConfig.size16,
            SizeConfig.size8,
          ),
          child: buildLoadingShimmer(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerContainer(height: 16, width: 150, radius: 6),
                      SizedBox(height: 6),
                      shimmerContainer(height: 12, width: 90, radius: 6),
                    ],
                  ),
                ),
                shimmerContainer(height: 34, width: 96, radius: 30),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: SizeConfig.size4, bottom: SizeConfig.size12),
                  child: buildLoadingShimmer(
                    child: shimmerContainer(height: 14, width: 110, radius: 6),
                  ),
                ),
                ...List.generate(3, (_) => _shimmerCard()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// A single card skeleton matching the bank/UPI card layout.
  Widget _shimmerCard() {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size16),
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.boxBg),
      ),
      child: buildLoadingShimmer(
        child: Column(
          children: [
            Row(
              children: [
                shimmerContainer(height: 42, width: 42, radius: 21),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerContainer(height: 16, width: 130, radius: 6),
                      SizedBox(height: 6),
                      shimmerContainer(height: 12, width: 70, radius: 6),
                    ],
                  ),
                ),
                shimmerContainer(height: 34, width: 34, radius: 17),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            shimmerContainer(height: 48, radius: 12),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBankList(WalletController controller) {
    final banks = controller.bankListModel.value.data ?? [];
    return banks.map((e) => _bankCard(controller, e)).toList();
  }

  List<Widget> _buildUpiList(WalletController controller) {
    final upis = controller.upiListModel.value.data ?? [];
    return upis.map((e) => _upiCard(controller, e)).toList();
  }

  /// =========================
  /// UPI CARD
  /// =========================
  Widget _upiCard(WalletController controller, UpiData e) {
    final upiId = e.upiDetails?.upiId ?? '';
    final mobileNumber = e.upiDetails?.mobileNumber ?? '';
    final bankName = e.upiDetails?.bankName ?? '';
    final isDefault = e.isDefault ?? false;
    final id = e.id ?? '';

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
        border: Border.all(
          color: isDefault
              ? AppColors.primaryColor.withValues(alpha: 0.45)
              : AppColors.boxBg,
          width: isDefault ? 1.2 : 1,
        ),
      ),
      child: Column(
        children: [
          /// Top Row
          Row(
            children: [
              _avatarCircle(
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white, size: 22),
                color: AppColors.primaryColor,
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
                            fontSize: SizeConfig.size16,
                            fontWeight: FontWeight.w500,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault) _defaultBadge(),
                      ],
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
              _actionMenu(
                isDefault: isDefault,
                onEdit: () => _openEditUpi(controller, e),
                onSetDefault: () =>
                    controller.setDefaultWithdrawalMethod(id),
                onDelete: () => _confirmDelete(
                  controller,
                  id,
                  upiId.isNotEmpty ? upiId : "this UPI ID",
                ),
              ),
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
                    onTap: () => showUpiQrDialog(
                      upiId: upiId,
                      bankName: bankName,
                    ),
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
  /// BANK CARD
  /// =========================
  Widget _bankCard(WalletController controller, BankData e) {
    final holderName = e.bankDetails?.holderName ?? '';
    final bankName = e.bankDetails?.bankName ?? '';
    final accountNo = e.bankDetails?.accountNo ?? '';
    final ifsc = e.bankDetails?.ifscCode ?? '';
    final isDefault = e.isDefault ?? false;
    final id = e.id ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size16),
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? AppColors.primaryColor.withValues(alpha: 0.45)
              : AppColors.boxBg,
          width: isDefault ? 1.2 : 1,
        ),
      ),
      child: Column(
        children: [
          /// Top Row
          Row(
            children: [
              _avatarCircle(
                color: Colors.blue,
                child: CustomText(
                  holderName.isNotEmpty ? holderName[0].toUpperCase() : "B",
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
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
                            holderName,
                            fontSize: SizeConfig.size18,
                            fontWeight: FontWeight.w500,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault) _defaultBadge(),
                      ],
                    ),
                    SizedBox(height: 2),
                    CustomText(
                      bankName,
                      fontSize: SizeConfig.size12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grayText,
                    ),
                  ],
                ),
              ),
              _actionMenu(
                isDefault: isDefault,
                onEdit: () => _openEditBank(controller, e),
                onSetDefault: () =>
                    controller.setDefaultWithdrawalMethod(id),
                onDelete: () => _confirmDelete(
                  controller,
                  id,
                  bankName.isNotEmpty ? bankName : "this bank account",
                ),
              ),
            ],
          ),

          SizedBox(height: SizeConfig.size8),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.boxBg),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size14,
                    vertical: SizeConfig.size12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                  height: 56,
                  width: 1,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size14,
                    vertical: SizeConfig.size12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

  // ─────────────────────────────────────────────────────────────────────
  //  SHARED CARD BITS
  // ─────────────────────────────────────────────────────────────────────

  Widget _avatarCircle({required Widget child, required Color color}) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }

  Widget _defaultBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.verifiedTickIcon,
            height: 12,
            width: 12,
            boxFix: BoxFit.contain,
            imgColor: AppColors.primaryColor,
          ),
          const SizedBox(width: 3),
          CustomText(
            "Default",
            fontSize: SizeConfig.size12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  /// The 3-dot menu shared by both card types — Edit, Set as Default (hidden
  /// when already default), and Delete.
  Widget _actionMenu({
    required bool isDefault,
    required VoidCallback onEdit,
    required VoidCallback onSetDefault,
    required VoidCallback onDelete,
  }) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFE),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E5E5), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.more_vert, size: 18, color: Colors.black87),
        onSelected: (value) {
          if (value == "edit") onEdit();
          if (value == "default") onSetDefault();
          if (value == "delete") onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: "edit",
            child: _menuRow(AppIconAssets.editIcon, AppStrings.edit),
          ),
          if (!isDefault)
            PopupMenuItem(
              value: "default",
              child: _menuRow(
                  AppIconAssets.verifiedTickIcon, AppStrings.setAsDefault.tr),
            ),
          PopupMenuItem(
            value: "delete",
            child: _menuRow(AppIconAssets.deleteIcon, "Delete",
                color: AppColors.red),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(String asset, String label, {Color? color}) {
    return Row(
      children: [
        LocalAssets(
          imagePath: asset,
          height: 18,
          width: 18,
          boxFix: BoxFit.contain,
          imgColor: color ?? AppColors.mainTextColor,
        ),
        const SizedBox(width: 10),
        CustomText(
          label,
          fontSize: SizeConfig.size14,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.mainTextColor,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  ACTIONS
  // ─────────────────────────────────────────────────────────────────────

  void _confirmDelete(WalletController controller, String id, String label) {
    if (id.isEmpty) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText(
          "Remove method?",
          fontSize: SizeConfig.size18,
          fontWeight: FontWeight.w700,
        ),
        content: CustomText(
          "Are you sure you want to remove $label? This action can't be undone.",
          fontSize: SizeConfig.size14,
          color: AppColors.grayText,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomText(
              AppStrings.cancel,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Get.back();
              controller.deleteWithdrawalMethod(id);
            },
            child: const CustomText(
              "Delete",
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditUpi(WalletController controller, UpiData e) {
    final upiCtrl = TextEditingController(text: e.upiDetails?.upiId ?? '');
    final mobileCtrl =
        TextEditingController(text: e.upiDetails?.mobileNumber ?? '');
    _editSheet(
      title: "Edit UPI",
      fields: [
        _sheetField(AppStrings.upiId, upiCtrl, hint: "name@bank"),
        _sheetField("Mobile Number", mobileCtrl,
            hint: "10-digit mobile number",
            keyboardType: TextInputType.phone,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]),
      ],
      onSave: () {
        if (upiCtrl.text.trim().isEmpty) {
          commonSnackBar(message: "Please enter a UPI ID");
          return false;
        }
        controller.updateUpiMethod(
          id: e.id ?? '',
          upiId: upiCtrl.text,
          mobileNumber: mobileCtrl.text,
        );
        return true;
      },
    );
  }

  void _openEditBank(WalletController controller, BankData e) {
    final holderCtrl =
        TextEditingController(text: e.bankDetails?.holderName ?? '');
    final accountCtrl =
        TextEditingController(text: e.bankDetails?.accountNo ?? '');
    final ifscCtrl = TextEditingController(text: e.bankDetails?.ifscCode ?? '');
    final bankCtrl = TextEditingController(text: e.bankDetails?.bankName ?? '');
    _editSheet(
      title: "Edit Bank Account",
      fields: [
        _sheetField("Account Holder Name", holderCtrl, hint: "Full name"),
        _sheetField("Account Number", accountCtrl,
            hint: "Bank account number",
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly]),
        _sheetField("IFSC Code", ifscCtrl,
            hint: "e.g. HDFC0001234",
            formatters: [
              UpperCaseTextFormatter(),
              LengthLimitingTextInputFormatter(11),
            ]),
        _sheetField("Bank Name", bankCtrl, hint: "e.g. HDFC Bank"),
      ],
      onSave: () {
        if (holderCtrl.text.trim().isEmpty ||
            accountCtrl.text.trim().isEmpty ||
            ifscCtrl.text.trim().isEmpty ||
            bankCtrl.text.trim().isEmpty) {
          commonSnackBar(message: "Please fill all bank details");
          return false;
        }
        controller.updateBankMethod(
          id: e.id ?? '',
          holderName: holderCtrl.text,
          accountNo: accountCtrl.text,
          ifscCode: ifscCtrl.text,
          bankName: bankCtrl.text,
        );
        return true;
      },
    );
  }

  /// Generic edit bottom-sheet. `onSave` returns true to dismiss the sheet
  /// (validation passed) or false to keep it open.
  void _editSheet({
    required String title,
    required List<Widget> fields,
    required bool Function() onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.size16,
            right: SizeConfig.size16,
            top: SizeConfig.size12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + SizeConfig.size16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size16),
              CustomText(
                title,
                fontSize: SizeConfig.size18,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: SizeConfig.size16),
              ...fields,
              SizedBox(height: SizeConfig.size8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: SizeConfig.size45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyE5),
                        ),
                        child: CustomText(
                          AppStrings.cancel,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (onSave()) Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: SizeConfig.size45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const CustomText(
                          "Save",
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.size12,
          fontWeight: FontWeight.w600,
          color: AppColors.grayText,
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyE5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            style: TextStyle(
              fontSize: SizeConfig.size15,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              contentPadding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size14,
                vertical: SizeConfig.size14,
              ),
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size14),
      ],
    );
  }
}

/// Upper-cases input as it's typed — used for the IFSC field.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}