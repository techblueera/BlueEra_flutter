import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/account_plan/model/deposit_migration_model.dart';
import 'package:BlueEra/features/account_plan/view/account_plan_catalog_view.dart'
    show AccountPlanPalette;
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// UPGRADE CONFIRMATION — the last thing between an upgrade and the payment
/// sheet, shown in the CENTRE of the screen.
///
/// A user upgrading is not buying a plan at its listed price: what they already
/// paid is credited, and Razorpay will only ever show them the difference. That
/// makes the arithmetic the whole point of this moment — if the catalog says
/// ₹450 and the payment sheet says ₹295, the gap has to be explained before
/// the sheet opens, not after.
///
/// Every number is the server's ([UpgradePriceBreakdown]); the app computes
/// none of it, because the total the user approves here has to be the same one
/// the order is created for.
///
/// ## Two shapes, one dialog
/// * **current-plan credit** — plain confirmation, no consent needed. What they
///   paid for their current tier simply carries over.
/// * **deposit credit** — the credit is their REFUNDABLE deposit, and spending
///   it here means it will not come back. That is a decision, not a detail, so
///   the terms appear with a checkbox and the pay button stays dead until it is
///   ticked.
///
/// Centre rather than a bottom sheet: a sheet is a place you browse and swipe
/// away, and this is the one screen in the flow that must be read. It arrives
/// with a short scale-and-fade so it registers as an interruption.
///
/// Returns true when the user confirmed (and, where required, accepted).
Future<bool> showUpgradeConfirmDialog(
  BuildContext context, {
  required String planLabel,
  required UpgradePriceBreakdown breakdown,
  required bool requiresTnc,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: !requiresTnc,
    barrierLabel: AppStrings.upgradeConfirmTitle.tr,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        // Linear fade against an eased scale: the back-curve overshoot should
        // read as the card settling, not as it flickering.
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: _UpgradeConfirmDialog(
            planLabel: planLabel,
            breakdown: breakdown,
            requiresTnc: requiresTnc,
          ),
        ),
      );
    },
  );
  return result == true;
}

class _UpgradeConfirmDialog extends StatefulWidget {
  const _UpgradeConfirmDialog({
    required this.planLabel,
    required this.breakdown,
    required this.requiresTnc,
  });

  final String planLabel;
  final UpgradePriceBreakdown breakdown;
  final bool requiresTnc;

  @override
  State<_UpgradeConfirmDialog> createState() => _UpgradeConfirmDialogState();
}

class _UpgradeConfirmDialogState extends State<_UpgradeConfirmDialog> {
  bool _accepted = false;

  bool get _canPay => !widget.requiresTnc || _accepted;

  @override
  Widget build(BuildContext context) {
    final b = widget.breakdown;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size20,
        vertical: SizeConfig.size24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size18),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size20,
          SizeConfig.size20,
          SizeConfig.size20,
          SizeConfig.size16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              AppStrings.upgradeConfirmTitle.tr,
              fontSize: SizeConfig.size18,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              AppStrings.upgradeConfirmSubtitleFmt
                  .trParams({'plan': widget.planLabel}),
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              height: 1.35,
              maxLines: 2,
            ),
            SizedBox(height: SizeConfig.size16),

            // ── The arithmetic, in the order it happens ──────────────
            _Row(
              label: AppStrings.upgradePlanPriceLabel.tr,
              value: _money(b.planPriceInr),
            ),
            _Row(
              label: b.fromDeposit
                  ? AppStrings.upgradeCreditDepositLabel.tr
                  : AppStrings.upgradeCreditPlanLabel.tr,
              value: '- ${_money(b.creditAppliedInr)}',
              valueColor: AccountPlanPalette.tick,
            ),
            _Row(
              label: AppStrings.upgradeGstLabelFmt
                  .trParams({'percent': '${_plain(b.gstPercent)}'}),
              value: '+ ${_money(b.gstInr)}',
            ),
            SizedBox(height: SizeConfig.size10),
            Container(height: 1, color: AppColors.greyE5),
            SizedBox(height: SizeConfig.size10),
            _Row(
              label: AppStrings.upgradePayNowLabel.tr,
              value: _money(b.payTotalInr),
              emphasised: true,
            ),
            SizedBox(height: SizeConfig.size8),
            // The one line that reconciles this dialog with the payment sheet
            // the user is about to see.
            CustomText(
              AppStrings.upgradeChargeNote.tr,
              fontSize: SizeConfig.size11,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              height: 1.35,
              maxLines: 3,
            ),

            // ── Deposit terms, when the credit is refundable money ────
            if (widget.requiresTnc) ...[
              SizedBox(height: SizeConfig.size14),
              Container(
                padding: EdgeInsets.all(SizeConfig.size12),
                decoration: BoxDecoration(
                  color: AccountPlanPalette.popularSurface,
                  borderRadius: BorderRadius.circular(SizeConfig.size12),
                  border: Border.all(
                    color: AccountPlanPalette.popular.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.upgradeTncTitle.tr,
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size6),
                    _Bullet(
                      text: AppStrings.upgradeTncDepositSpentFmt
                          .trParams({'amount': _money(b.creditAppliedInr)}),
                    ),
                    _Bullet(text: AppStrings.upgradeTncNoRefund.tr),
                    _Bullet(
                      text: AppStrings.upgradeTncPaidDifferenceFmt
                          .trParams({'amount': _money(b.payTotalInr)}),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size6),
              InkWell(
                onTap: () => setState(() => _accepted = !_accepted),
                borderRadius: BorderRadius.circular(SizeConfig.size8),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: SizeConfig.size24,
                        height: SizeConfig.size24,
                        child: Checkbox(
                          value: _accepted,
                          activeColor: AppColors.primaryColor,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) =>
                              setState(() => _accepted = v ?? false),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: CustomText(
                          AppStrings.upgradeTncAccept.tr,
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: SizeConfig.size16),
            Row(
              children: [
                Expanded(
                  child: CustomBtn(
                    title: AppStrings.cancel.tr,
                    bgColor: AppColors.white,
                    borderColor: AppColors.greyE5,
                    textColor: AppColors.secondaryTextColor,
                    radius: SizeConfig.size10,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: CustomBtn(
                    // Names the amount, so the button and the payment sheet
                    // agree before it is tapped.
                    title: AppStrings.upgradePayFmt
                        .trParams({'amount': _money(b.payTotalInr)}),
                    isValidate: _canPay,
                    bgColor:
                        _canPay ? AppColors.primaryColor : AppColors.whiteF3,
                    textColor: _canPay ? AppColors.white : AppColors.grey9B,
                    radius: SizeConfig.size10,
                    onTap: _canPay
                        ? () => Navigator.of(context).pop(true)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// `₹450`, dropping a trailing `.0` so whole rupees read cleanly.
String _money(num amount) =>
    '${AppConstants.rupeeSymbol}${_plain(amount)}';

String _plain(num value) =>
    value % 1 == 0 ? value.toInt().toString() : value.toString();

/// One line of the calculation.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomText(
              label,
              fontSize: emphasised ? SizeConfig.size14 : SizeConfig.size13,
              fontWeight: emphasised ? FontWeight.w800 : FontWeight.w500,
              color: emphasised
                  ? AppColors.mainTextColor
                  : AppColors.secondaryTextColor,
              maxLines: 2,
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          CustomText(
            value,
            fontSize: emphasised ? SizeConfig.size18 : SizeConfig.size13,
            fontWeight: emphasised ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ??
                (emphasised
                    ? AppColors.primaryColor
                    : AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: SizeConfig.size6),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.secondaryTextColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.size12,
              fontWeight: FontWeight.w500,
              color: AccountPlanPalette.featureText,
              height: 1.35,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }
}
