import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/referral_history_screen.dart';
import 'package:BlueEra/features/common/referral/widgets/stat_donut_chart.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StaticsTab extends StatefulWidget {
  final ReferralController controller;
  const StaticsTab({super.key, required this.controller});

  @override
  State<StaticsTab> createState() => _StaticsTabState();
}

class _StaticsTabState extends State<StaticsTab> {
  // ─── Palette used across the legend dots / donut segments ─────────
  static const _grey = Color(0xFFB6BBC4);
  static const _green = Color(0xFF34C77B);
  static const _yellow = Color(0xFFFFC93C);
  static const _red = Color(0xFFEF4444);

  ReferralController get controller => widget.controller;

  static const _filterAll = 'All';
  static const _filterJoining = 'Joining Bonus';
  static const _filterDirectReferral = 'Direct Referral Income';
  static const _filterOrder = 'Order Income';
  static const _filterContent = 'Content Creation Income';
  static const _filters = <String>[
    _filterAll,
    _filterJoining,
    _filterDirectReferral,
    _filterOrder,
    _filterContent,
  ];

  String _selectedFilter = _filterAll;

  bool _showCard(String filter) =>
      _selectedFilter == _filterAll || _selectedFilter == filter;

  // Format a rupee amount: integers render without decimals, fractions
  // keep two digits. Falls back to ₹0 when null.
  String _money(num? v) {
    final n = v ?? 0;
    final body = n == n.truncateToDouble()
        ? _withCommas(n.toInt())
        : n.toStringAsFixed(2);
    return '₹$body';
  }

  String _count(num? v) {
    final n = v ?? 0;
    return n == n.truncateToDouble()
        ? _withCommas(n.toInt())
        : n.toString();
  }

  String _withCommas(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  void initState() {
    super.initState();
    controller.fetchDirectReferralIncome();
  }

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
          if (_showCard(_filterJoining)) ...[
            _joiningBonusCard(),
            SizedBox(height: SizeConfig.paddingXSL),
          ],
          if (_showCard(_filterDirectReferral)) ...[
            _directReferralCard(),
            SizedBox(height: SizeConfig.paddingXSL),
          ],
          if (_showCard(_filterOrder)) ...[
            _orderIncomeCard(),
            SizedBox(height: SizeConfig.paddingXSL),
          ],
          if (_showCard(_filterContent)) _contentCreationCard(),
        ],
      ),
    );
  }

  // ─── "My Statics" / <filter> ▼ filter header ──────────────────────
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
        PopupMenuButton<String>(
          initialValue: _selectedFilter,
          tooltip: 'Filter',
          position: PopupMenuPosition.under,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: AppColors.white,
          onSelected: (value) {
            if (value == _selectedFilter) return;
            setState(() => _selectedFilter = value);
          },
          itemBuilder: (context) => [
            for (final f in _filters)
              PopupMenuItem<String>(
                value: f,
                child: CustomText(
                  f,
                  fontSize: SizeConfig.small,
                  fontWeight: f == _selectedFilter
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: f == _selectedFilter
                      ? AppColors.primaryColor
                      : AppColors.mainTextColor,
                ),
              ),
          ],
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                CustomText(
                  _selectedFilter,
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
    return Obx(() {
      final jb = controller.walletStatics.value?.joiningBonus;
      final days = jb?.progress?.days;
      final hours = jb?.progress?.workHours;
      final tasks = jb?.progress?.assignTask;
      return _StatsCard(
        title: 'Joining Bonus',
        onViewDetails: () {},
        body: _ChartRow(
          donut: StatDonutChart(
            segments: [
              DonutSegment(color: _grey, value: days?.current ?? 0),
              DonutSegment(color: _green, value: hours?.current ?? 0),
              DonutSegment(color: _yellow, value: tasks?.current ?? 0),
            ],
            center: _CenterText(
              value: _money(jb?.totalBonus),
              label: 'Total Bonus',
            ),
          ),
          rows: [
            _LegendRow(
              color: _grey,
              label: 'Days',
              value:
                  '${_count(days?.current)}/${_count(days?.target)} Days',
            ),
            _LegendRow(
              color: _green,
              label: 'Work Hours',
              value:
                  '${_count(hours?.current)}/${_count(hours?.target)} hrs.',
            ),
            _LegendRow(
              color: _yellow,
              label: 'Assign Task',
              value:
                  '${_count(tasks?.current)}/${_count(tasks?.target)} Tasks',
            ),
          ],
        ),
        footer: const _FooterWithdrawOnly(),
      );
    });
  }

  // ─── Direct Referral Income ───────────────────────────────────────
  Widget _directReferralCard() {
    return Obx(() {
      final dr = controller.walletStatics.value?.directReferralIncome;
      final bk = dr?.breakdown;
      final earn = dr?.earnings;
      return _StatsCard(
        title: 'Direct Referral Income',
        onViewDetails: () => Get.to(() => const ReferralHistoryScreenNew()),
        body: _ChartRow(
          donut: StatDonutChart(
            segments: [
              DonutSegment(color: _green, value: bk?.subscribed ?? 0),
              DonutSegment(color: _yellow, value: bk?.pending ?? 0),
              DonutSegment(color: _grey, value: bk?.unsubscribed ?? 0),
              DonutSegment(color: _red, value: bk?.expired ?? 0),
            ],
            center: _CenterText(
              value: _count(dr?.referralCount),
              label: 'Referral Count',
            ),
          ),
          rows: [
            _LegendRow(
                color: _green,
                label: 'Subscribe',
                value: _count(bk?.subscribed)),
            _LegendRow(
                color: _yellow,
                label: 'Pending',
                value: _count(bk?.pending)),
            _LegendRow(
                color: _grey,
                label: 'Un-Subscribe',
                value: _count(bk?.unsubscribed)),
            _LegendRow(
                color: _red,
                label: 'Expired',
                value: _count(bk?.expired)),
          ],
        ),
        footer: _FooterReferral(
          estdEarning: _money(earn?.estimatedEarning),
          totalEarn: _money(earn?.totalEarn),
          balance: _money(earn?.balance),
        ),
      );
    });
  }

  // ─── Order Income ─────────────────────────────────────────────────
  Widget _orderIncomeCard() {
    return Obx(() {
      final oi = controller.walletStatics.value?.orderIncome;
      final bk = oi?.breakdown;
      return _StatsCard(
        title: 'Order Income',
        onViewDetails: () {},
        body: _ChartRow(
          donut: StatDonutChart(
            segments: [
              DonutSegment(color: _grey, value: bk?.myOrder ?? 0),
              DonutSegment(color: _green, value: bk?.referralOrder ?? 0),
              DonutSegment(color: _yellow, value: bk?.bonus ?? 0),
            ],
            center: _CenterText(
              value: _money(oi?.totalAmount),
              label: 'Total Amount',
            ),
          ),
          rows: [
            _LegendRow(
                color: _grey,
                label: 'My Order',
                value: _money(bk?.myOrder)),
            _LegendRow(
                color: _green,
                label: 'Referral Order',
                value: _money(bk?.referralOrder)),
            _LegendRow(
                color: _yellow,
                label: 'Bonus',
                value: _money(bk?.bonus)),
          ],
        ),
        footer: _FooterBalanceWithdraw(balance: _money(oi?.balance)),
      );
    });
  }

  // ─── Content Creation Income ──────────────────────────────────────
  Widget _contentCreationCard() {
    return Obx(() {
      final cc = controller.walletStatics.value?.contentCreationIncome;
      return _StatsCard(
        title: 'Content Creation Income',
        onViewDetails: () {},
        body: _ChartRow(
          donut: StatDonutChart(
            segments: [
              DonutSegment(color: _grey, value: cc?.totalVideo ?? 0),
              DonutSegment(color: _green, value: cc?.viewCount ?? 0),
              DonutSegment(color: _yellow, value: cc?.bonus ?? 0),
            ],
            center: _CenterText(
              value: _money(cc?.totalIncome),
              label: 'Total Income',
            ),
          ),
          rows: [
            _LegendRow(
                color: _grey,
                label: 'Total Video',
                value: _count(cc?.totalVideo)),
            _LegendRow(
                color: _green,
                label: 'View Count',
                value: _count(cc?.viewCount)),
            _LegendRow(
                color: _yellow,
                label: 'Bonus',
                value: _money(cc?.bonus)),
          ],
        ),
        footer: _FooterBalanceWithdraw(balance: _money(cc?.balance)),
      );
    });
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
              SizeConfig.size10,
              SizeConfig.size10,
              SizeConfig.size10,
              SizeConfig.size10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w400,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.greyE5),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size14,
              SizeConfig.size12,
              SizeConfig.size14,
              SizeConfig.size12,
            ),
            child: body,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
            child: const _DashedDivider(),
          ),
          SizedBox(height: SizeConfig.size12),
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
      child: Row(
        children: [
          const Spacer(),
          Expanded(child: _WithdrawButton(onTap: () {})),
        ],
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
          Row(
            children: [
              const Spacer(),
              Expanded(child: _WithdrawButton(onTap: () {})),
            ],
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
        SizeConfig.size20,
        0,
        SizeConfig.size14,
        SizeConfig.size12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
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

/// Solid primary-blue Withdraw button. Width is supplied by the
/// parent (callers wrap it in [Expanded] so it scales across devices
/// instead of carrying a hardcoded pixel width).
class _WithdrawButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WithdrawButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
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
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Horizontal dashed line. Renders as a row of evenly-spaced dashes
/// that span the full available width, so it scales with the card
/// across devices.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  static const _color = Color(0xFFCFD4DA);
  static const _thickness = 1.0;
  static const _dashWidth = 4.0;
  static const _dashSpace = 4.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount =
            (boxWidth / (_dashWidth + _dashSpace)).floor().clamp(0, 10000);
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => const SizedBox(
              width: _dashWidth,
              height: _thickness,
              child: DecoratedBox(decoration: BoxDecoration(color: _color)),
            ),
          ),
        );
      },
    );
  }
}
