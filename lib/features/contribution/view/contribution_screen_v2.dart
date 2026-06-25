import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/contribution/controller/security_deposit_controller.dart';
import 'package:BlueEra/features/contribution/model/security_deposit_models.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Contribution flow **v2** — built on the Security Deposit backend
/// (docs/backend/SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md). Replaces the
/// recharge-based [ContributionScreen] at its call sites.
///
/// Shows the active (held) deposit when the user has one, otherwise the plan
/// catalog with a pay (initiate → confirm) CTA.
class ContributionScreenV2 extends StatelessWidget {
  const ContributionScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => SecurityDepositController());
    _hydrateBuyerDetails(controller);
    return Scaffold(
      backgroundColor: const Color(0xFFEEF8FF),
      appBar: CommonBackAppBar(
        title: AppStrings.contributionTitle.tr,
        isLeading: true,
        showElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() => controller.isTestMode
                ? const _TestModeBanner()
                : const SizedBox.shrink()),
            Expanded(
              child: Obx(() {
                final status = controller.currentStatus.value;
                if (status == Status.INITIAL || status == Status.LOADING) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.hasActiveDeposit) {
                  return _ActiveDepositView(controller: controller);
                }
                return _PlansView(controller: controller);
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Populate the controller's Razorpay prefill (name / email / phone) from the
  /// personal-details controller, falling back to the global mobile number.
  void _hydrateBuyerDetails(SecurityDepositController controller) {
    try {
      final viewCtrl = Get.find<ViewPersonalDetailsController>();
      final user = viewCtrl.personalProfileDetails.value.user;
      controller.userName = user?.name ?? '';
      controller.userEmail = user?.email ?? '';
      controller.userPhone = user?.contactNo ?? userMobileGlobal;
    } catch (_) {
      controller.userPhone = userMobileGlobal;
    }
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(String raw) {
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return '--';
  return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
}

String _rupees(int paise) {
  final r = paise / 100.0;
  return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(2);
}

// ─────────────────────────────────────────────
// PLANS CATALOG
// ─────────────────────────────────────────────
class _PlansView extends StatelessWidget {
  const _PlansView({required this.controller});

  final SecurityDepositController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.plansStatus.value;
      if (status == Status.INITIAL || status == Status.LOADING) {
        return const Center(child: CircularProgressIndicator());
      }
      if (status == Status.ERROR) {
        return _ErrorState(
          message: controller.plansError.value,
          onRetry: controller.fetchPlans,
        );
      }
      final plans = controller.plans;
      if (plans.isEmpty) {
        return _ErrorState(
          message: 'No deposit plans available',
          onRetry: controller.fetchPlans,
        );
      }
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size12,
          SizeConfig.size12,
          SizeConfig.size12,
          SizeConfig.size40,
        ),
        itemCount: plans.length,
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
        itemBuilder: (_, i) => _PlanCard(plan: plans[i], controller: controller),
      );
    });
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.controller});

  final SecurityDepositPlan plan;
  final SecurityDepositController controller;

  @override
  Widget build(BuildContext context) {
    final zeroDeposit = plan.depositAmount <= 0;
    final firstDayText = plan.firstDayFreeUnlimited
        ? plan.firstDayFreeText
        : (plan.firstDayFreeLimit != null
            ? 'First ${plan.firstDayFreeLimit} free'
            : plan.firstDayFreeText);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: const [
          BoxShadow(color: Color(0x14001120), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets.all(SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + refundable deposit amount.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      plan.name,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (plan.uiCategoryGroup.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      CustomText(
                        plan.uiCategoryGroup,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    zeroDeposit ? '₹0' : '₹${_rupees(plan.depositAmount)}',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryColor,
                  ),
                  CustomText(
                    'Refundable deposit',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (firstDayText.isNotEmpty)
            _Pill(icon: Icons.card_giftcard_rounded, text: firstDayText),
          // if (plan.baseMetric.isNotEmpty) ...[
          //   SizedBox(height: SizeConfig.size8),
          //   _InfoLine(label: 'Billed per', value: plan.baseMetric),
          // ],
          // if (plan.activationCondition.isNotEmpty) ...[
          //   SizedBox(height: SizeConfig.size6),
          //   _InfoLine(label: 'Activation', value: plan.activationCondition),
          // ],
          _InfoLine(
            label: 'Refund lock',
            value: 'After ${plan.refundAfterMonths} months',
          ),
          if (plan.termsAndConditions.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size8),
            _TermsBlock(terms: plan.termsAndConditions),
          ],
          SizedBox(height: SizeConfig.size14),
          if (zeroDeposit)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                'No deposit required',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryTextColor,
              ),
            )
          else
            Obx(() {
              final busy = controller.isProcessing.value;
              return SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: busy ? null : () => controller.payDeposit(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor:
                        AppColors.primaryColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : CustomText(
                          'Pay Security Deposit',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTIVE (HELD) DEPOSIT
// ─────────────────────────────────────────────
class _ActiveDepositView extends StatelessWidget {
  const _ActiveDepositView({required this.controller});

  final SecurityDepositController controller;

  @override
  Widget build(BuildContext context) {
    final deposit = controller.currentDeposit.value!;
    final plan = deposit.plan;
    final planName = plan?.name ?? AppStrings.activeContribution.tr;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size12,
        SizeConfig.size40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card.
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F1B5C), Color(0xFF5E2BA8), Color(0xFFB2308C)],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x4D2B1B5C), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        size: 16, color: Color(0xFFFFD9B0)),
                    const SizedBox(width: 6),
                    CustomText(
                      'SECURITY DEPOSIT',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    const Spacer(),
                    _StatusPill(status: deposit.status),
                  ],
                ),
                const SizedBox(height: 26),
                CustomText(
                  planName,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: '₹',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFE6B0),
                            ),
                          ),
                          TextSpan(
                            text: _rupees(deposit.paidAmount),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (deposit.heldAt.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomText(
                            AppStrings.sinceLabel.tr,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 1.4,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            _formatDate(deposit.heldAt),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ],
                      ),
                  ],
                ),
                // Refer & earn — surface the savings when a referral discount
                // was applied at initiate (base struck-through + amount saved).
                if (deposit.discountAmount > 0) ...[
                  const SizedBox(height: 12),
                  _ReferralSavingsChip(
                    baseAmount: deposit.baseAmount > 0
                        ? deposit.baseAmount
                        : deposit.depositAmount,
                    discountAmount: deposit.discountAmount,
                    percent: deposit.referralDiscountPercent,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size14),
          _InfoCard(
            icon: Icons.lock_clock_rounded,
            title: 'Refund eligibility',
            children: [
              _InfoLine(
                label: 'Refundable on',
                value: deposit.refundEligibleAt.isNotEmpty
                    ? _formatDate(deposit.refundEligibleAt)
                    : 'After ${deposit.refundAfterMonths} months',
              ),
            ],
          ),
          if (plan != null && plan.termsAndConditions.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size12),
            _InfoCard(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              children: [_TermsBlock(terms: plan.termsAndConditions)],
            ),
          ],
          SizedBox(height: SizeConfig.size16),
          Obx(() {
            final busy = controller.isProcessing.value;
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: busy
                    ? null
                    : () => controller.requestRefund(
                          onLocked: (eligibleAt) => _showLockedDialog(
                            context,
                            _formatDate(eligibleAt),
                          ),
                        ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : CustomText(
                        'Request Refund',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showLockedDialog(BuildContext context, String eligibleDate) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText(
          'Refund not available yet',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        content: CustomText(
          'This deposit is refundable on or after $eligibleDate.',
          fontSize: 13,
          color: AppColors.secondaryTextColor,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: CustomText(
              'OK',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF064E3B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        status.isEmpty ? AppStrings.activeStatusLabel.tr : status.toUpperCase(),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
    );
  }
}

/// Refer-&-earn savings stamp on the active-deposit hero card. Shows the
/// pre-discount base struck-through and the rupee amount saved via the
/// referral, mirroring docs §8 ("show base_amount vs final_amount").
class _ReferralSavingsChip extends StatelessWidget {
  const _ReferralSavingsChip({
    required this.baseAmount,
    required this.discountAmount,
    required this.percent,
  });

  final int baseAmount; // paise
  final int discountAmount; // paise
  final int percent;

  @override
  Widget build(BuildContext context) {
    final savedLabel = '₹${_rupees(discountAmount)}';
    final percentLabel = percent > 0 ? ' ($percent% off)' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard_rounded,
              size: 14, color: Color(0xFF6EE7B7)),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '₹${_rupees(baseAmount)} ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  TextSpan(
                    text: 'Referral saved $savedLabel$percentLabel',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Flexible(
            child: CustomText(
              text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: CustomText(
              label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
          Expanded(
            child: CustomText(
              value,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsBlock extends StatelessWidget {
  const _TermsBlock({required this.terms});
  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: terms
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomText(
                        t,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 4,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              CustomText(
                title,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              message.isEmpty ? AppStrings.somethingWentWrong.tr : message,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: SizeConfig.size16),
            OutlinedButton(
              onPressed: onRetry,
              child: CustomText(
                'Retry',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber "test environment" strip — shown when the backend reports
/// `mode == 'test'`.
class _TestModeBanner extends StatelessWidget {
  const _TestModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        SizeConfig.size8,
        SizeConfig.size12,
        0,
      ),
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6B84A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, size: 16, color: Color(0xFFB8860B)),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              AppStrings.testModeBanner.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8A6500),
            ),
          ),
        ],
      ),
    );
  }
}
