import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/rider_statistics_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_statistics_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// The rider's Statistics tab: what they earned, what they drove, and how they
/// are scoring — for today, this week, or this month.
///
/// Reading order is deliberate and matches how a rider actually checks the tab:
/// the money first as a single hero number, then the work behind it, then the
/// trend, then the ratings that gate future work, then payouts. Anything a
/// rider cannot act on is left out.
///
/// One measure per chart, one hue per chart, no second y-axis anywhere.
class RiderStatisticsView extends StatelessWidget {
  const RiderStatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => RiderStatisticsController());

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Obx(() {
        final status = controller.statsResponse.value.status;
        final data = controller.stats.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodSelector(controller: controller),
            SizedBox(height: SizeConfig.size12),
            if (controller.isSample) ...[
              const _SampleDataBanner(),
              SizedBox(height: SizeConfig.size12),
            ],
            if (status == Status.LOADING && data == null)
              const _StatsLoading()
            else if (status == Status.ERROR && data == null)
              _StatsMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Statistics unavailable',
                // Surface the server's own `message` when there is one (guide
                // §8) — a 400 for a bad period or a 403 for a caller who isn't
                // an onboarded rider both say something more useful than our
                // generic line, and a rider reading "not an onboarded rider"
                // knows to finish onboarding instead of retrying forever.
                body: _errorBody(controller.statsResponse.value.message),
                onRetry: controller.reload,
              )
            else if (data == null || data.isEmpty)
              _StatsMessage(
                icon: Icons.insights_outlined,
                title: 'No rides in this period',
                body: 'Go live and complete a ride — your earnings and score '
                    'will show up here.',
                onRetry: controller.reload,
              )
            else ...[
              // Every section below gates on `data.meta`, not on the value. A
              // zero means "you earned nothing"; an entry in `_meta.unavailable`
              // means "there is no ledger for this at all", and only the second
              // one should remove a card. See
              // docs/backend/RIDER_STATISTICS_FLUTTER_GUIDE.md §2.
              _EarningsCard(earnings: data.earnings, meta: data.meta),
              SizedBox(height: SizeConfig.size12),
              _WorkSummaryCard(
                trips: data.trips,
                earnings: data.earnings,
                meta: data.meta,
              ),
              SizedBox(height: SizeConfig.size12),
              if (data.trend.length >= 2) ...[
                _EarningsTrendCard(trend: data.trend),
                SizedBox(height: SizeConfig.size12),
              ],
              _PerformanceCard(
                performance: data.performance,
                trips: data.trips,
              ),
              // Payouts needs BOTH: the backend has to actually source it, and
              // there has to be something to show. `hasAny` alone would hide it
              // for a rider who is simply square with us.
              if (data.meta.has('payouts.pending') && data.payouts.hasAny) ...[
                SizedBox(height: SizeConfig.size12),
                _PayoutCard(payouts: data.payouts),
              ],
            ],
          ],
        );
      }),
    );
  }
}

// ── formatting ─────────────────────────────────────────────────────────────

/// Indian grouping (₹1,24,500) — this is what the rider sees on every other
/// money surface in the app and on their bank SMS.
final NumberFormat _rupees = NumberFormat.decimalPattern('en_IN');

String _money(double value) => '₹${_rupees.format(value.round())}';

/// The server's error text, or our own line when there isn't one worth showing.
///
/// Dio's own strings ("DioException [connection timeout]", stack-trace text
/// from a thrown object) are not error messages a rider can act on, so anything
/// that looks like plumbing falls back to the generic line.
String _errorBody(String? message) {
  const fallback = "We couldn't load your numbers just now.";
  final text = message?.trim() ?? '';
  if (text.isEmpty) return fallback;
  final looksInternal = text.startsWith('DioException') ||
      text.startsWith('Exception') ||
      text.contains('#0 ') ||
      text.length > 160;
  return looksInternal ? fallback : text;
}

String _hoursMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

// ── period selector ────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final RiderStatisticsController controller;

  const _PeriodSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.period.value;
      return Container(
        padding: EdgeInsets.all(SizeConfig.size4),
        decoration: BoxDecoration(
          color: AppColors.whiteF3,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: RiderStatsPeriod.values.map((p) {
            final isSelected = p == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectPeriod(p),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: SizeConfig.size8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CustomText(
                    p.label,
                    textAlign: TextAlign.center,
                    fontSize: SizeConfig.small,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

/// Shown while the numbers are invented rather than fetched. Loud on purpose:
/// a rider must never mistake a layout preview for their actual earnings.
class _SampleDataBanner extends StatelessWidget {
  const _SampleDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        color: AppColors.yellow00.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.yellow00.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: SizeConfig.size16, color: AppColors.yellow00),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              'Sample data — live statistics are not connected yet',
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── earnings ───────────────────────────────────────────────────────────────

/// The headline. One number, as large as the card allows, because it is the
/// only thing most riders open this tab for; the breakdown explains it and the
/// deduction line makes sure the number is never a surprise at payout.
class _EarningsCard extends StatelessWidget {
  final RiderEarningsStats earnings;
  final RiderStatsMeta meta;

  const _EarningsCard({required this.earnings, required this.meta});

  @override
  Widget build(BuildContext context) {
    // Only the lines the backend actually fills. Today that is trip fare alone;
    // incentives, tips and deductions have no ledger behind them yet.
    final chips = <_BreakdownChip>[
      _BreakdownChip(label: 'Trip fare', value: _money(earnings.tripFare)),
      if (meta.has('earnings.incentives'))
        _BreakdownChip(label: 'Incentives', value: _money(earnings.incentives)),
      if (meta.has('earnings.tips'))
        _BreakdownChip(label: 'Tips', value: _money(earnings.tips)),
    ];

    // With incentives and tips gone, `total == tripFare` — so a lone "Trip
    // fare" chip would just restate the hero number one line below itself. Drop
    // the whole row in that case; it comes back the moment there is a second
    // component to break out.
    final showBreakdown =
        chips.length > 1 || earnings.tripFare != earnings.total;

    final showDeductions =
        meta.has('earnings.deductions') && earnings.deductions > 0;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Total earnings',
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CustomText(
              _money(earnings.total),
              fontSize: SizeConfig.size32,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ),
          if (showBreakdown) ...[
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  if (i > 0) SizedBox(width: SizeConfig.size8),
                  Expanded(child: chips[i]),
                ],
              ],
            ),
          ],
          if (showDeductions) ...[
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                Icon(Icons.remove_circle_outline_rounded,
                    size: SizeConfig.size14,
                    color: AppColors.secondaryTextColor),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                  child: CustomText(
                    'Platform fee already deducted',
                    fontSize: SizeConfig.small11,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                CustomText(
                  _money(earnings.deductions),
                  fontSize: SizeConfig.small11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  final String label;
  final String value;

  const _BreakdownChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: SizeConfig.extraSmall,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: SizeConfig.size2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CustomText(
              value,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── work summary ───────────────────────────────────────────────────────────

/// What the money cost in work: rides, distance, hours online, and the per-ride
/// average — the number riders actually compare between days.
class _WorkSummaryCard extends StatelessWidget {
  final RiderTripStats trips;
  final RiderEarningsStats earnings;
  final RiderStatsMeta meta;

  const _WorkSummaryCard({
    required this.trips,
    required this.earnings,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final perTrip =
        trips.completed > 0 ? earnings.total / trips.completed : null;

    final tiles = <_StatTile>[
      _StatTile(
        icon: Icons.check_circle_outline_rounded,
        value: '${trips.completed}',
        label: 'Rides done',
      ),
      _StatTile(
        icon: Icons.route_outlined,
        value: '${trips.distanceKm.toStringAsFixed(1)} km',
        // The backend measures this straight-line pickup→drop, not along the
        // road, so it reads low against the odometer. Saying "approx" costs a
        // word and stops a rider deciding our numbers are wrong.
        label: 'Distance (approx)',
      ),
      // No go-live session log yet, so there is nothing behind this number.
      // Showing "0h" would read as a rider who never went online.
      if (meta.has('trips.onlineMinutes'))
        _StatTile(
          icon: Icons.access_time_rounded,
          value: _hoursMinutes(trips.onlineMinutes),
          label: 'Online',
        ),
      _StatTile(
        icon: Icons.payments_outlined,
        value: perTrip == null ? '—' : _money(perTrip),
        label: 'Avg / ride',
      ),
    ];

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      // Three tiles fit one row; four want a 2×2. Laid out from the list rather
      // than hardcoded so the grid reflows on its own when `onlineMinutes`
      // starts arriving, instead of leaving a hole where the tile used to be.
      child: tiles.length <= 3
          ? _TileRow(tiles: tiles)
          : Column(
              children: [
                _TileRow(tiles: tiles.sublist(0, 2)),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                  child: Container(height: 1, color: AppColors.greyE5),
                ),
                _TileRow(tiles: tiles.sublist(2)),
              ],
            ),
    );
  }
}

/// Evenly-spaced tiles with hairline seams between them.
class _TileRow extends StatelessWidget {
  final List<_StatTile> tiles;

  const _TileRow({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) _TileDivider(),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _TileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: SizeConfig.size32,
      color: AppColors.greyE5,
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: SizeConfig.size18, color: AppColors.primaryColor),
        SizedBox(height: SizeConfig.size6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: CustomText(
            value,
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ),
        SizedBox(height: SizeConfig.size2),
        CustomText(
          label,
          fontSize: SizeConfig.extraSmall,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
        ),
      ],
    );
  }
}

// ── trend ──────────────────────────────────────────────────────────────────

/// Daily earnings as bars — one measure, one hue, no legend (a single series is
/// named by the title). The best day is direct-labelled and every bar answers
/// on tap; labelling all seven would be noise.
class _EarningsTrendCard extends StatelessWidget {
  final List<RiderTrendPoint> trend;

  const _EarningsTrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final maxEarning =
        trend.map((e) => e.earnings).reduce((a, b) => a > b ? a : b);
    // Headroom so the tallest bar never touches the card's top edge.
    final maxY = maxEarning <= 0 ? 100.0 : maxEarning * 1.25;
    final bestIndex = trend.indexWhere((e) => e.earnings == maxEarning);

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Daily earnings',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size2),
          CustomText(
            'Tap a bar for that day\'s total',
            fontSize: SizeConfig.extraSmall,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size16),
          SizedBox(
            height: SizeConfig.size160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                // Recessive by design: no grid, no border, no left axis. The
                // bars carry the comparison and the tap carries the value —
                // a y-axis of rupee ticks would be four extra numbers to read.
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: SizeConfig.size6),
                          child: CustomText(
                            trend[i].shortLabel,
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.secondaryTextColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.mainTextColor,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, _, rod, __) {
                      final point = trend[group.x];
                      return BarTooltipItem(
                        '${_money(point.earnings)}\n',
                        TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.small,
                        ),
                        children: [
                          TextSpan(
                            text: '${point.trips} '
                                '${point.trips == 1 ? 'ride' : 'rides'}',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                              fontSize: SizeConfig.small11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < trend.length; i++)
                    BarChartGroupData(
                      x: i,
                      showingTooltipIndicators: const [],
                      barRods: [
                        BarChartRodData(
                          toY: trend[i].earnings,
                          width: SizeConfig.size18,
                          // Rounded data-end, square base — the bar is anchored
                          // to the baseline, so only the top is capped.
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          // One hue throughout; the best day is the same hue at
                          // full strength rather than a different colour, so
                          // nothing reads as a second series.
                          color: i == bestIndex
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size10),
          Row(
            children: [
              Container(
                width: SizeConfig.size10,
                height: SizeConfig.size10,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: SizeConfig.size6),
              Expanded(
                child: CustomText(
                  'Best day: ${trend[bestIndex].shortLabel} · '
                  '${_money(trend[bestIndex].earnings)}',
                  fontSize: SizeConfig.small11,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── performance ────────────────────────────────────────────────────────────

/// The scores that decide how much work a rider is offered. Each rate carries a
/// worded status beside its meter — the colour alone never has to be read, and
/// a rider who is colourblind or in bright sun still gets the message.
class _PerformanceCard extends StatelessWidget {
  final RiderPerformanceStats performance;
  final RiderTripStats trips;

  const _PerformanceCard({required this.performance, required this.trips});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'Your performance',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),
              if (performance.hasRating) ...[
                Icon(Icons.star_rounded,
                    size: SizeConfig.size18, color: AppColors.yellow00),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  performance.rating.toStringAsFixed(1),
                  fontSize: SizeConfig.medium15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  '(${performance.ratingCount})',
                  fontSize: SizeConfig.small11,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          _RateMeter(
            label: 'Acceptance',
            percent: performance.acceptanceRate,
            higherIsBetter: true,
            goodAt: 80,
            warnAt: 60,
            hint: 'Rides you accepted when offered',
          ),
          SizedBox(height: SizeConfig.size14),
          _RateMeter(
            label: 'Completion',
            percent: performance.completionRate,
            higherIsBetter: true,
            goodAt: 90,
            warnAt: 75,
            hint: 'Accepted rides you finished',
          ),
          SizedBox(height: SizeConfig.size14),
          _RateMeter(
            label: 'Cancellation',
            percent: performance.cancellationRate,
            higherIsBetter: false,
            goodAt: 5,
            warnAt: 15,
            hint: '${trips.cancelledByRider} cancelled by you',
          ),
        ],
      ),
    );
  }
}

/// A single rate: number, meter, and a word for how it's doing.
///
/// [goodAt] / [warnAt] are thresholds in the direction set by
/// [higherIsBetter] — so a 4% cancellation reads "Good" while a 4% acceptance
/// would read "Needs work", without either meter needing its own logic.
class _RateMeter extends StatelessWidget {
  final String label;
  final double percent;
  final bool higherIsBetter;
  final double goodAt;
  final double warnAt;
  final String hint;

  const _RateMeter({
    required this.label,
    required this.percent,
    required this.higherIsBetter,
    required this.goodAt,
    required this.warnAt,
    required this.hint,
  });

  bool get _isGood => higherIsBetter ? percent >= goodAt : percent <= goodAt;

  bool get _isWarning => higherIsBetter
      ? percent >= warnAt && percent < goodAt
      : percent > goodAt && percent <= warnAt;

  Color get _statusColor {
    if (_isGood) return AppColors.green1A;
    if (_isWarning) return AppColors.yellow00;
    return AppColors.redLite;
  }

  String get _statusWord {
    if (_isGood) return 'Good';
    if (_isWarning) return 'Watch';
    return 'Needs work';
  }

  @override
  Widget build(BuildContext context) {
    final clamped = (percent / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                label,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ),
            CustomText(
              '${percent.toStringAsFixed(0)}%',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
            SizedBox(width: SizeConfig.size8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size2,
              ),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText(
                _statusWord,
                fontSize: SizeConfig.extraSmall,
                fontWeight: FontWeight.w700,
                color: _statusColor,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: SizeConfig.size6,
            backgroundColor: AppColors.whiteF3,
            valueColor: AlwaysStoppedAnimation(_statusColor),
          ),
        ),
        SizedBox(height: SizeConfig.size4),
        CustomText(
          hint,
          fontSize: SizeConfig.extraSmall,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── payouts ────────────────────────────────────────────────────────────────

class _PayoutCard extends StatelessWidget {
  final RiderPayoutStats payouts;

  const _PayoutCard({required this.payouts});

  @override
  Widget build(BuildContext context) {
    final paidAt = DateTime.tryParse(payouts.lastPaidAt ?? '');

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'To be paid out',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  _money(payouts.pending),
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green1A,
                ),
              ],
            ),
          ),
          if (payouts.lastAmount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  'Last payout',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  _money(payouts.lastAmount),
                  fontSize: SizeConfig.medium15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                if (paidAt != null)
                  CustomText(
                    DateFormat('d MMM').format(paidAt.toLocal()),
                    fontSize: SizeConfig.extraSmall,
                    color: AppColors.secondaryTextColor,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── states ─────────────────────────────────────────────────────────────────

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size60),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
    );
  }
}

class _StatsMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onRetry;

  const _StatsMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size20),
      child: Column(
        children: [
          Icon(icon, size: SizeConfig.size40, color: AppColors.grey9A),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            title,
            fontSize: SizeConfig.medium15,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            body,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          SizedBox(height: SizeConfig.size12),
          TextButton(
            onPressed: onRetry,
            child: CustomText(
              'Retry',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
