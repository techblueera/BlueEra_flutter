import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral_new/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral_new/view/referral_history_screen.dart';
import 'package:BlueEra/features/common/referral_new/widgets/stat_donut_chart.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Statics tab — matches `assets/business_chat_window.png`.
///
/// Four white cards, each with a donut chart on the left and a
/// colored-dot legend on the right:
///   1. Joining Bonus            (Withdraw, no balance pill)
///   2. Direct Referral Income   (3-column Estd/Total/Balance + full-
///                                width Withdraw)
///   3. Order Income             (Balance pill + Withdraw)
///   4. Content Creation Income  (Balance pill + Withdraw)
///
/// Values are the dummy figures from the mockup; swap them with live
/// controller fields when the matching endpoints ship.
class StaticsTab extends StatelessWidget {
  final ReferralControllerNew controller;
  const StaticsTab({super.key, required this.controller});

  // ─── Palette used across the legend dots / donut segments ─────────
  static const _grey = Color(0xFFB6BBC4);
  static const _green = Color(0xFF34C77B);
  static const _yellow = Color(0xFFFFC93C);
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size10,
        SizeConfig.paddingXSL,
        SizeConfig.size10,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _myStaticsHeader(),
          SizedBox(height: SizeConfig.paddingXSL),
          _joiningBonusCard(),
          SizedBox(height: SizeConfig.paddingXSL),
          _directReferralCard(),
          SizedBox(height: SizeConfig.paddingXSL),
          _orderIncomeCard(),
          SizedBox(height: SizeConfig.paddingXSL),
          _contentCreationCard(),
        ],
      ),
    );
  }

  // ─── "My Statics" / All ▼ filter header ───────────────────────────
  Widget _myStaticsHeader() {
    return Row(
      children: [
        CustomText(
          'My Statics',
          fontSize: SizeConfig.extraLarge,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        const Spacer(),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                CustomText(
                  'All',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.mainTextColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Joining Bonus ────────────────────────────────────────────────
  Widget _joiningBonusCard() {
    return _StatsCard(
      title: 'Joining Bonus',
      onViewDetails: () {},
      body: _ChartRow(
        donut: StatDonutChart(
          segments: const [
            DonutSegment(color: _grey, value: 1),     // Days 1/100
            DonutSegment(color: _green, value: 2),    // Hours 2/580
            DonutSegment(color: _yellow, value: 5),   // Tasks 5/20
          ],
          center: const _CenterText(value: '₹400', label: 'Total Bonus'),
        ),
        rows: const [
          _LegendRow(color: _grey, label: 'Days', value: '1/100 Days'),
          _LegendRow(
              color: _green, label: 'Work Hours', value: '2/580 hrs.'),
          _LegendRow(
              color: _yellow, label: 'Assign Task', value: '5/20 Tasks'),
        ],
      ),
      footer: const _FooterWithdrawOnly(),
    );
  }

  // ─── Direct Referral Income ───────────────────────────────────────
  Widget _directReferralCard() {
    return _StatsCard(
      title: 'Direct Referral Income',
      onViewDetails: () => Get.to(() => const ReferralHistoryScreenNew()),
      body: _ChartRow(
        donut: StatDonutChart(
          segments: const [
            DonutSegment(color: _green, value: 20),    // Subscribe
            DonutSegment(color: _yellow, value: 370),  // Pending
            DonutSegment(color: _grey, value: 370),    // Un-Subscribe
            DonutSegment(color: _red, value: 10),      // Expired
          ],
          center: const _CenterText(value: '400', label: 'Referral Count'),
        ),
        rows: const [
          _LegendRow(color: _green, label: 'Subscribe', value: '20'),
          _LegendRow(color: _yellow, label: 'Pending', value: '370'),
          _LegendRow(color: _grey, label: 'Un-Subscribe', value: '370'),
          _LegendRow(color: _red, label: 'Expired', value: '10'),
        ],
      ),
      footer: const _FooterReferral(
        estdEarning: '₹ 1000',
        totalEarn: '₹ 2000',
        balance: '₹ 3000',
      ),
    );
  }

  // ─── Order Income ─────────────────────────────────────────────────
  Widget _orderIncomeCard() {
    return _StatsCard(
      title: 'Order Income',
      onViewDetails: () {},
      body: _ChartRow(
        donut: StatDonutChart(
          segments: const [
            DonutSegment(color: _grey, value: 100),   // My Order
            DonutSegment(color: _green, value: 50),   // Referral Order
            DonutSegment(color: _yellow, value: 200), // Bonus
          ],
          center: const _CenterText(value: '₹400', label: 'Total Amount'),
        ),
        rows: const [
          _LegendRow(color: _grey, label: 'My Order', value: '₹100'),
          _LegendRow(
              color: _green, label: 'Referral Order', value: '₹50'),
          _LegendRow(color: _yellow, label: 'Bonus', value: '₹200'),
        ],
      ),
      footer: const _FooterBalanceWithdraw(balance: '₹2500'),
    );
  }

  // ─── Content Creation Income ──────────────────────────────────────
  Widget _contentCreationCard() {
    return _StatsCard(
      title: 'Content Creation Income',
      onViewDetails: () {},
      body: _ChartRow(
        donut: StatDonutChart(
          segments: const [
            DonutSegment(color: _grey, value: 150),    // Total Video
            DonutSegment(color: _green, value: 50000), // View Count
            DonutSegment(color: _yellow, value: 200),  // Bonus
          ],
          center: const _CenterText(value: '₹400', label: 'Total Income'),
        ),
        rows: const [
          _LegendRow(color: _grey, label: 'Total Video', value: '150'),
          _LegendRow(color: _green, label: 'View Count', value: '50,000'),
          _LegendRow(color: _yellow, label: 'Bonus', value: '₹200'),
        ],
      ),
      footer: const _FooterBalanceWithdraw(balance: '₹2500'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────

/// White card shell: title row at top, body + footer below, separated
/// by a hairline divider.
class _StatsCard extends StatelessWidget {
  final String title;
  final VoidCallback onViewDetails;
  final Widget body;
  final Widget footer;
  const _StatsCard({
    required this.title,
    required this.onViewDetails,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size14,
              SizeConfig.size12,
              SizeConfig.size14,
              SizeConfig.size10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onViewDetails,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    child: CustomText(
                      'View Details',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEF1F4)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size14,
              SizeConfig.size12,
              SizeConfig.size14,
              SizeConfig.size12,
            ),
            child: body,
          ),
          footer,
        ],
      ),
    );
  }
}

/// Donut on the left, vertical legend on the right.
class _ChartRow extends StatelessWidget {
  final Widget donut;
  final List<_LegendRow> rows;
  const _ChartRow({required this.donut, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        donut,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One legend row — coloured dot, label on the left, value on the
/// right.
class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            label,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        CustomText(
          value,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
      ],
    );
  }
}

/// Big rupee value + small caption inside the donut.
class _CenterText extends StatelessWidget {
  final String value;
  final String label;
  const _CenterText({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          value,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
        const SizedBox(height: 2),
        CustomText(
          label,
          fontSize: 10,
          color: AppColors.secondaryTextColor,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}

// ─── Footer variants ─────────────────────────────────────────────────

/// Just a "Withdraw" button right-aligned — used by Joining Bonus.
class _FooterWithdrawOnly extends StatelessWidget {
  const _FooterWithdrawOnly();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        0,
        SizeConfig.size14,
        SizeConfig.size12,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: _WithdrawButton(width: 140, onTap: () {}),
      ),
    );
  }
}

/// Three-column "Estd. Earning / Total Earn / Balance" strip on top
/// of a full-width Withdraw — used by Direct Referral.
class _FooterReferral extends StatelessWidget {
  final String estdEarning;
  final String totalEarn;
  final String balance;
  const _FooterReferral({
    required this.estdEarning,
    required this.totalEarn,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        0,
        SizeConfig.size14,
        SizeConfig.size12,
      ),
      child: Column(
        children: [
          Container(height: 1, color: const Color(0xFFEEF1F4)),
          SizedBox(height: SizeConfig.size10),
          Row(
            children: [
              Expanded(child: _summaryCell('Estd. Earning', estdEarning)),
              _vDivider(),
              Expanded(child: _summaryCell('Total Earn', totalEarn)),
              _vDivider(),
              Expanded(child: _summaryCell('Balance', balance)),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          SizedBox(
            width: double.infinity,
            child: _WithdrawButton(onTap: () {}),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value) {
    return Column(
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.extraSmall,
          color: AppColors.secondaryTextColor,
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 4),
        CustomText(
          value,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 28,
        color: const Color(0xFFEEF1F4),
      );
}

/// Outlined "Balance - ₹X" pill + filled Withdraw — used by Order
/// Income and Content Creation Income.
class _FooterBalanceWithdraw extends StatelessWidget {
  final String balance;
  const _FooterBalanceWithdraw({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        0,
        SizeConfig.size14,
        SizeConfig.size12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: CustomText(
                'Balance - $balance',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _WithdrawButton(onTap: () {})),
        ],
      ),
    );
  }
}

/// Solid primary-blue Withdraw button. Width defaults to filling its
/// parent — callers that need a fixed width (e.g. the Joining Bonus
/// footer) pass [width].
class _WithdrawButton extends StatelessWidget {
  final VoidCallback onTap;
  final double? width;
  const _WithdrawButton({required this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: CustomText(
          'Withdraw',
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}
