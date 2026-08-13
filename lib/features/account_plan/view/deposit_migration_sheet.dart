import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/account_plan/controller/account_plan_controller.dart';
import 'package:BlueEra/features/account_plan/controller/account_plan_entitlement.dart';
import 'package:BlueEra/features/account_plan/model/deposit_migration_model.dart';
import 'package:BlueEra/features/account_plan/repo/account_plan_repo.dart';
import 'package:BlueEra/features/account_plan/view/account_plan_catalog_view.dart'
    show AccountPlanPalette;
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// DEPOSIT → ACCOUNT-PLAN MIGRATION offer.
///
/// Existing security-deposit holders are moved onto the account-plan system by
/// invitation, not by decree: the mapped plan activates at ₹0 and the deposit
/// itself is untouched — still refundable, still auto-refunded to the original
/// payment method on its original date. Both sheets say that in as many words,
/// because the one thing a user will assume about "migrate your deposit" is
/// that they are about to lose it.
///
/// Two steps, per the backend contract: the offer (Skip / Migrate), then the
/// T&C the backend records an acceptance against. Nothing here charges anyone.
///
/// See docs/backend/DEPOSIT_MIGRATION_FLUTTER_GUIDE.md §1–§4.

/// Dismissed (or shown, or answered) during this app run. The guide's cadence:
/// at most once per session, re-offered on the next app open — so this is
/// in-memory on purpose and nothing is persisted. A skip is "not now", not
/// "never"; the offer is free money staying safe, and burning it forever on one
/// tap would be the wrong default.
bool _handledThisLaunch = false;

/// Guards two callers racing the eligibility call into two sheets.
bool _checkInFlight = false;

/// Asks the backend whether this user is a deposit holder who can be migrated,
/// and if so shows the offer. Safe to call on every launch — every reason not
/// to show is checked here.
///
/// Fails silently: an error, an ineligible answer, or a malformed one all show
/// nothing. This is an unprompted offer, so it must never surface a failure the
/// user didn't ask for.
Future<void> showDepositMigrationIfNeeded(BuildContext context) async {
  if (_handledThisLaunch || _checkInFlight) return;
  // Entry log: every other exit from this function is logged, so without one
  // here a silent "not signed in" return is indistinguishable from the check
  // never running at all.
  logs('DEPOSIT_MIGRATION: checking…');
  if (isGuestUser() || !isLoggedIn()) {
    logs('DEPOSIT_MIGRATION: skip — guest / not signed in');
    return;
  }
  _checkInFlight = true;
  try {
    final res = await AccountPlanRepo().migrationEligibility();
    if (!res.isSuccess) {
      logs('DEPOSIT_MIGRATION: eligibility failed — ${res.message}');
      return;
    }
    final body = res.response?.data;
    if (body is! Map) return;

    final eligibility = DepositMigrationEligibility.fromJson(
        Map<String, dynamic>.from(body));
    logs('DEPOSIT_MIGRATION: eligible=${eligibility.eligible} '
        'alreadyMigrated=${eligibility.alreadyMigrated} '
        'hasActivePlan=${eligibility.hasActivePlan} '
        'reason=${eligibility.reason} plan=${eligibility.plan?.label}');
    if (!eligibility.canOffer) return;

    if (!context.mounted || _handledThisLaunch) return;
    // Something is on top (the joining-bonus card, the add-products page, a
    // deep link). Stacking a money sheet over it would bury whichever loses.
    // The offer comes back on the next app open.
    if (ModalRoute.of(context)?.isCurrent == false) {
      logs('DEPOSIT_MIGRATION: skip — another route is on top');
      return;
    }

    _handledThisLaunch = true;
    await _showOfferSheet(context, eligibility);
  } catch (e) {
    logs('DEPOSIT_MIGRATION: check threw — $e');
  } finally {
    _checkInFlight = false;
  }
}

/// Sheet A → on Migrate, Sheet B. Kept as one call so the caller doesn't have
/// to know there are two.
Future<void> _showOfferSheet(
    BuildContext context, DepositMigrationEligibility eligibility) async {
  final wantsMigrate = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MigrationOfferSheet(eligibility: eligibility),
  );
  if (wantsMigrate != true || !context.mounted) return;

  await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    // Not dismissible by tapping away: this sheet can have a network call in
    // flight, and closing it mid-migration is what produces the "did it work?"
    // half state the guide warns about.
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MigrationTncSheet(eligibility: eligibility),
  );
}

/// `11 Feb 2026`, or null when the backend sent no parseable date — the copy
/// then drops the date rather than inventing one.
String? _refundDate(MigrationDeposit deposit) {
  final at = deposit.refundEligibleAt;
  if (at == null) return null;
  return DateFormat('d MMM yyyy').format(at);
}

String _money(num amount) =>
    '${AppConstants.rupeeSymbol}${amount % 1 == 0 ? amount.toInt() : amount}';

// ─────────────────────────────────────────────────────────────────────────────
// Sheet A — the offer
// ─────────────────────────────────────────────────────────────────────────────

class _MigrationOfferSheet extends StatelessWidget {
  const _MigrationOfferSheet({required this.eligibility});

  final DepositMigrationEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final deposit = eligibility.deposit!;
    final plan = eligibility.plan!;
    final date = _refundDate(deposit);
    final amount = _money(deposit.amountInr);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size20,
          SizeConfig.size12,
          SizeConfig.size20,
          SizeConfig.size20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetGrabber(),
            SizedBox(height: SizeConfig.size16),
            Center(
              child: CustomText(
                AppStrings.depositMigrationTitle.tr,
                fontSize: SizeConfig.size20,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            // The offer in one sentence, with both numbers that matter in it.
            CustomText(
              AppStrings.depositMigrationOfferFmt
                  .trParams({'amount': amount, 'plan': plan.label}),
              fontSize: SizeConfig.medium15,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
              height: 1.45,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size16),
            _Benefit(text: AppStrings.depositMigrationBenefitFree.tr),
            SizedBox(height: SizeConfig.size8),
            // The line that stops the fear. Without a date from the backend it
            // still promises the refund, just without naming a day.
            _Benefit(
              text: date == null
                  ? AppStrings.depositMigrationBenefitRefundNoDateFmt
                      .trParams({'amount': amount})
                  : AppStrings.depositMigrationBenefitRefundFmt
                      .trParams({'amount': amount, 'date': date}),
            ),
            SizedBox(height: SizeConfig.size20),
            Row(
              children: [
                Expanded(
                  child: CustomBtn(
                    title: AppStrings.skip.tr,
                    bgColor: AppColors.white,
                    borderColor: AccountPlanPalette.divider,
                    textColor: AppColors.secondaryTextColor,
                    radius: SizeConfig.size10,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: CustomBtn(
                    title: AppStrings.depositMigrationCta.tr,
                    bgColor: AppColors.primaryColor,
                    radius: SizeConfig.size10,
                    onTap: () => Navigator.of(context).pop(true),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sheet B — T&C, then migrate
// ─────────────────────────────────────────────────────────────────────────────

class _MigrationTncSheet extends StatefulWidget {
  const _MigrationTncSheet({required this.eligibility});

  final DepositMigrationEligibility eligibility;

  @override
  State<_MigrationTncSheet> createState() => _MigrationTncSheetState();
}

class _MigrationTncSheetState extends State<_MigrationTncSheet> {
  bool _accepted = false;
  bool _migrating = false;

  /// Accepts the T&C and activates the plan.
  ///
  /// On failure the sheet STAYS OPEN with the button live again — the guide's
  /// rule: never leave a half state. A closed sheet after a failed migration
  /// reads as "it worked", which is the one wrong answer here.
  Future<void> _migrate() async {
    if (_migrating || !_accepted) return;
    setState(() => _migrating = true);
    try {
      final res = await AccountPlanRepo().migrate();
      final body = res.response?.data;
      final data = body is Map && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : const <String, dynamic>{};
      // Idempotent by contract: a second tap answers `already: true`, which is
      // the plan being active — the same outcome the first tap wanted.
      final already = data['already'] == true || body is Map && body['already'] == true;
      final ok = res.isSuccess &&
          (body is! Map || body['success'] != false || already);

      if (!ok) {
        final message = (body is Map ? body['message']?.toString() : null) ??
            res.message ??
            AppStrings.somethingWentWrong.tr;
        logs('DEPOSIT_MIGRATION: migrate failed — $message');
        if (mounted) commonSnackBar(message: message);
        return;
      }

      final message = (body is Map ? body['message']?.toString() : null) ??
          AppStrings.depositMigrationSuccess.tr;
      logs('DEPOSIT_MIGRATION: migrated (already=$already)');
      if (mounted) Navigator.of(context).pop(true);
      commonSnackBar(message: message);
      // The user now holds a plan — refresh the entitlement snapshot the
      // go-live gates read, or the app keeps telling them to pay for one.
      unawaited(AccountPlanEntitlement.to.refresh());
      // And the plans screen, if it happens to be alive, so the new active
      // plan is there rather than one navigation behind.
      if (Get.isRegistered<AccountPlanController>()) {
        unawaited(Get.find<AccountPlanController>().fetchMyPlans());
      }
    } catch (e) {
      logs('DEPOSIT_MIGRATION: migrate threw — $e');
      if (mounted) commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deposit = widget.eligibility.deposit!;
    final plan = widget.eligibility.plan!;
    final date = _refundDate(deposit);
    final amount = _money(deposit.amountInr);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size20,
          SizeConfig.size12,
          SizeConfig.size20,
          SizeConfig.size20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetGrabber(),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              AppStrings.depositMigrationTncTitle.tr,
              fontSize: SizeConfig.size18,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size12),
            _Bullet(
              text: AppStrings.depositMigrationTncPlanFmt
                  .trParams({'plan': plan.label}),
            ),
            _Bullet(
              text: date == null
                  ? AppStrings.depositMigrationTncRefundNoDateFmt
                      .trParams({'amount': amount})
                  : AppStrings.depositMigrationTncRefundFmt
                      .trParams({'amount': amount, 'date': date}),
            ),
            _Bullet(text: AppStrings.depositMigrationTncLifetime.tr),
            _Bullet(text: AppStrings.depositMigrationTncNoCharge.tr),
            SizedBox(height: SizeConfig.size8),
            // The acceptance is the whole point of this sheet, so the row is a
            // tap target, not just a checkbox with a label beside it.
            InkWell(
              onTap: _migrating ? null : () => setState(() => _accepted = !_accepted),
              borderRadius: BorderRadius.circular(SizeConfig.size8),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        onChanged: _migrating
                            ? null
                            : (v) => setState(() => _accepted = v ?? false),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: CustomText(
                        AppStrings.depositMigrationTncAccept.tr,
                        fontSize: SizeConfig.size13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            Row(
              children: [
                Expanded(
                  child: CustomBtn(
                    title: AppStrings.cancel.tr,
                    bgColor: AppColors.white,
                    borderColor: AccountPlanPalette.divider,
                    textColor: AppColors.secondaryTextColor,
                    radius: SizeConfig.size10,
                    onTap: _migrating
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: CustomBtn(
                    title: AppStrings.depositMigrationAccept.tr,
                    // Disabled until the box is ticked — the backend records an
                    // acceptance, so it has to be a real one.
                    isValidate: _accepted,
                    bgColor: _accepted
                        ? AppColors.primaryColor
                        : AppColors.whiteF3,
                    textColor:
                        _accepted ? AppColors.white : AppColors.grey9B,
                    radius: SizeConfig.size10,
                    isLoading: _migrating,
                    onTap: _accepted ? _migrate : null,
                  ),
                ),
              ],
            ),
            if ((widget.eligibility.tncVersion ?? '').isNotEmpty) ...[
              SizedBox(height: SizeConfig.size10),
              Center(
                child: CustomText(
                  '${AppStrings.depositMigrationTncVersion.tr} '
                  '${widget.eligibility.tncVersion}',
                  fontSize: SizeConfig.size11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────────

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AccountPlanPalette.divider,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// A green-ticked promise on the offer sheet.
class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded,
            size: SizeConfig.size18, color: AccountPlanPalette.tick),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: CustomText(
            text,
            fontSize: SizeConfig.size13,
            fontWeight: FontWeight.w500,
            color: AccountPlanPalette.featureText,
            height: 1.45,
            maxLines: 4,
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: SizeConfig.size6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.secondaryTextColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w500,
              color: AccountPlanPalette.featureText,
              height: 1.45,
              maxLines: 5,
            ),
          ),
        ],
      ),
    );
  }
}
