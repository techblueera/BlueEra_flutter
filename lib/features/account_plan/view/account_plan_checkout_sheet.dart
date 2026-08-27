import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/account_plan_models.dart';
import 'account_plan_catalog_view.dart' show AccountPlanPalette;

/// PAISE → a rupee string, dropping a trailing `.00` so whole prices read as
/// whole prices. The same rule every other price on this surface uses.
String _money(int paise) {
  final v = paise / 100;
  return '${AppConstants.rupeeSymbol}'
      '${v == v.truncateToDouble() ? v.toInt() : v.toStringAsFixed(2)}';
}

/// The checkout receipt — **built from `initiate`'s response, not the card**.
///
/// Shown between the tap and Razorpay for a purchase a campaign discounted, and
/// only then: that is the case where the plan's list price and the amount about
/// to leave the buyer's account are different numbers, and the arithmetic that
/// reconciles them has to be stated somewhere before the money moves. A
/// full-price purchase has nothing to reconcile and goes straight to checkout,
/// exactly as it did before discounts existed.
///
/// The figures are the server's, in the order the server applies them:
/// **list → minus discount → GST on what's left → total**. Nothing is
/// recomputed here; `order.totalAmount` is what the gateway is opened with.
///
/// Returns true when the user chose to pay. Dismissing returns false and
/// abandons the purchase — the unpaid order survives server-side and the next
/// attempt resumes it, so backing out costs nothing.
Future<bool> showAccountPlanCheckoutSheet(
  BuildContext context, {
  required String planLabel,
  required InitiatePlanResponse order,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    isDismissible: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _CheckoutSheet(
      planLabel: planLabel,
      order: order,
    ),
  );
  return result == true;
}

class _CheckoutSheet extends StatelessWidget {
  const _CheckoutSheet({required this.planLabel, required this.order});

  final String planLabel;
  final InitiatePlanResponse order;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size20,
          SizeConfig.size16,
          SizeConfig.size20,
          SizeConfig.size20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AccountPlanPalette.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              AppStrings.confirmYourPlan.tr,
              fontSize: SizeConfig.size18,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              planLabel,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w600,
              color: AccountPlanPalette.muted,
              maxLines: 2,
            ),
            SizedBox(height: SizeConfig.size16),

            // ── The arithmetic, in the order the server applies it ──
            _ReceiptRow(
              label: AppStrings.upgradePlanPriceLabel.tr,
              value: _money(order.listBaseAmount),
            ),
            if (order.hasDiscount) ...[
              _ReceiptRow(
                // The campaign's own name, rendered verbatim — admin copy is
                // never translated.
                label: order.discountLabel ?? order.discountCode!,
                value: '- ${_money(order.discountAmount)}',
                valueColor: AccountPlanPalette.tick,
              ),
              _ReceiptRow(
                label: AppStrings.priceAfterOffer.tr,
                value: _money(order.baseAmount),
              ),
            ],
            _ReceiptRow(
              label: AppStrings.upgradeGstLabelFmt
                  .trParams({'percent': '${order.gstPercent}'}),
              value: '+ ${_money(order.gstAmount)}',
            ),
            SizedBox(height: SizeConfig.size10),
            Container(height: 1, color: AppColors.greyE5),
            SizedBox(height: SizeConfig.size10),
            _ReceiptRow(
              label: AppStrings.totalPayable.tr,
              value: _money(order.totalAmount),
              emphasised: true,
            ),
            SizedBox(height: SizeConfig.size16),
            CustomBtn(
              title: '${AppStrings.payLabel.tr} ${_money(order.totalAmount)}',
              bgColor: AppColors.primaryColor,
              radius: SizeConfig.size12,
              fontSize: SizeConfig.size16,
              fontWeight: FontWeight.w700,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

/// One label/value line of the receipt.
class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
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
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
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
          SizedBox(width: SizeConfig.size8),
          CustomText(
            value,
            fontSize: emphasised ? SizeConfig.size16 : SizeConfig.size13,
            fontWeight: emphasised ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }
}

/// The 409 `price_changed` re-confirm.
///
/// The offer ended between the catalog and the tap, so the server refused the
/// price the card had promised rather than charging more. This is the buyer
/// seeing the new total and deciding — **the one thing that must never happen
/// here is an automatic retry**, which would take a larger amount than the
/// screen ever displayed.
///
/// Returns true to continue at the new price; the caller then re-buys from the
/// REFRESHED card, never by replaying the old amount.
Future<bool> showAccountPlanPriceChangedDialog(
  BuildContext context,
  Map<String, dynamic> detail,
) async {
  // Every figure is the server's, straight out of the rejection body.
  final label = detail['option_label']?.toString();
  final newTotal = detail['total_amount'] is num
      ? _money((detail['total_amount'] as num).toInt())
      : (detail['total_amount_inr'] == null
          ? null
          : '${AppConstants.rupeeSymbol}${detail['total_amount_inr']}');

  final result = await showDialog<bool>(
    context: context,
    // Not dismissible by tapping away: this is a price the buyer has to answer
    // yes or no to, and a stray tap reading as "no" is the safe half of that —
    // but an explicit Cancel is clearer than an accident either way.
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      title: CustomText(
        AppStrings.offerChangedTitle.tr,
        fontSize: SizeConfig.size16,
        fontWeight: FontWeight.w800,
        color: AppColors.mainTextColor,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.offerChangedBody.tr,
            fontSize: SizeConfig.size13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            height: 1.35,
            maxLines: 5,
          ),
          if (label != null && label.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size12),
            CustomText(
              label,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 2,
            ),
          ],
          if (newTotal != null) ...[
            SizedBox(height: SizeConfig.size6),
            CustomText(
              '${AppStrings.newTotal.tr}: $newTotal',
              fontSize: SizeConfig.size16,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: CustomText(
            AppStrings.cancel.tr,
            fontSize: SizeConfig.size14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: CustomText(
            AppStrings.continueAtNewPrice.tr,
            fontSize: SizeConfig.size14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    ),
  );
  return result == true;
}
