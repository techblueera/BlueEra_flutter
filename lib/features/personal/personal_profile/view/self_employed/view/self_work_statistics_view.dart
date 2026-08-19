import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_statistics_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/self_work_statistics_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// **Statics tab for a self-employed skilled worker** — electrician, plumber,
/// carpenter, painter, tutor, gardener, AC technician, and the rest of the
/// trades that run on a `selfWork` earn-service profile.
///
/// This deliberately replaces the generic [ProfileStatisticsScreen] (chat
/// clicks + profile visits) that every profile type used to share. Those two
/// numbers describe a *page*; a tradesperson runs a *business*, and the
/// questions they actually open this tab with are different:
///
///   1. **What did I make, and how much is still owed to me?**
///   2. **How much work did that take?**
///   3. **Where am I losing the people who contact me?**  ← the funnel
///   4. **Which of my services actually pay?**
///   5. **What are customers saying?**
///   6. **Was I even available?**
///   7. **Did anyone find me in the first place?**
///   8. **How do I compare to other <trade>s around me?**  ← industry level
///
/// The sections are ordered as that list, because that is the order the
/// questions get asked. Anything the worker cannot act on is left out.
///
/// One measure per chart, one hue per chart, no second y-axis anywhere.
class SelfWorkStatisticsView extends StatelessWidget {
  const SelfWorkStatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => SelfWorkStatisticsController());

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Obx(() {
        final status = controller.statsResponse.value.status;
        final data = controller.stats.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodSelector(controller: controller),
            // The dates the tab is actually reporting on, straight from the
            // response. "This Week" is a label; this is the answer to "which
            // week?", and it also confirms the numbers moved when the worker
            // switches tabs.
            if (data != null && _rangeLabel(data.range) != null) ...[
              SizedBox(height: SizeConfig.size8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                child: CustomText(
                  _rangeLabel(data.range)!,
                  fontSize: SizeConfig.small11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                ),
              ),
            ],
            SizedBox(height: SizeConfig.size12),
            if (status == Status.LOADING && data == null)
              const _StatsLoading()
            else if (status == Status.ERROR && data == null)
              _StatsMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Statistics unavailable',
                body: "We couldn't load your numbers just now.",
                onRetry: controller.reload,
              )
            else if (data == null || data.isEmpty)
              _StatsMessage(
                icon: Icons.insights_outlined,
                title: 'Nothing to show yet',
                body: 'Go live and finish a job — your earnings, enquiries and '
                    'ratings will start showing up here.',
                onRetry: controller.reload,
              )
            else ...[
              _EarningsCard(earnings: data.earnings),
              SizedBox(height: SizeConfig.size12),
              _WorkloadCard(jobs: data.jobs),
              SizedBox(height: SizeConfig.size12),
              if (data.trend.length >= 2) ...[
                _TrendCard(trend: data.trend),
                SizedBox(height: SizeConfig.size12),
              ],
              if (data.funnel.hasAny) ...[
                _FunnelCard(funnel: data.funnel),
                SizedBox(height: SizeConfig.size12),
              ],
              if (data.topServices.isNotEmpty) ...[
                _ServiceMixCard(services: data.topServices),
                SizedBox(height: SizeConfig.size12),
              ],
              if (data.reputation.hasRating) ...[
                _ReputationCard(reputation: data.reputation),
                SizedBox(height: SizeConfig.size12),
              ],
              if (data.availability.hasAny) ...[
                _AvailabilityCard(availability: data.availability),
                SizedBox(height: SizeConfig.size12),
              ],
              if (data.reach.hasAny) ...[
                _ReachCard(reach: data.reach),
                SizedBox(height: SizeConfig.size12),
              ],
              if (data.benchmark.isReliable)
                _BenchmarkCard(benchmark: data.benchmark),
            ],
            SizedBox(height: SizeConfig.size16),
          ],
        );
      }),
    );
  }
}

// ── formatting ───────────────────────────────────────────────────────────────

/// Indian grouping (₹1,24,500) — what the worker sees on every other money
/// surface in the app and on their bank SMS.
final NumberFormat _grouped = NumberFormat.decimalPattern('en_IN');

String _money(double value) => '₹${_grouped.format(value.round())}';

String _count(num value) => _grouped.format(value);

String _pct(double value) => '${value.round()}%';

/// The window under the period tabs: `7 Aug`, `3 – 7 Aug`, `28 Jul – 3 Aug`,
/// `28 Dec 2025 – 3 Jan 2026`.
///
/// The year is printed only when the window isn't in the current one — on a
/// dashboard showing this week, "2026" is a fact nobody needed. Collapses to a
/// single date when the window is one day (`period=today`), because "7 Aug –
/// 7 Aug" reads like a bug.
///
/// Null when the backend didn't send `range`, and the line is then not drawn.
String? _rangeLabel(SelfWorkStatsRange range) {
  final from = range.from;
  final to = range.to;
  if (from == null || to == null) return null;

  final thisYear = DateTime.now().year;
  final needsYear = from.year != thisYear || to.year != thisYear;
  final end = needsYear ? _fullDate.format(to) : _dayMonth.format(to);

  if (from.year == to.year && from.month == to.month) {
    if (from.day == to.day) return end;
    // Same month — the month name only needs saying once.
    return '${_dayOnly.format(from)} – $end';
  }
  if (from.year == to.year) return '${_dayMonth.format(from)} – $end';
  return '${_fullDate.format(from)} – ${_fullDate.format(to)}';
}

final DateFormat _dayOnly = DateFormat('d');
final DateFormat _dayMonth = DateFormat('d MMM');
final DateFormat _fullDate = DateFormat('d MMM yyyy');

String _hoursMinutes(int minutes) {
  if (minutes <= 0) return '0m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Response times are read as "how fast do I reply", so minutes stay minutes
/// until they stop being legible.
String _responseTime(int minutes) {
  if (minutes <= 0) return '—';
  if (minutes < 60) return '$minutes min';
  return _hoursMinutes(minutes);
}

// ── shared shells ────────────────────────────────────────────────────────────

/// Card shell used by every section. Matches the self-employed dashboard's
/// existing card language (white sheet, hairline border, soft shadow, tracked
/// uppercase eyebrow) so the Statics tab reads as part of the same screen.
class _Card extends StatelessWidget {
  final String title;

  /// Optional one-line explanation under the title. Used where a number is
  /// only meaningful with its definition attached.
  final String? subtitle;
  final Widget child;

  const _Card({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryTextColor,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: SizeConfig.size6),
            CustomText(
              subtitle!,
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 3,
            ),
          ],
          SizedBox(height: SizeConfig.size12),
          child,
        ],
      ),
    );
  }
}

/// One number with a caption. The workhorse of the whole tab.
class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _Metric({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.mainTextColor,
            height: 1.1,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        CustomText(
          label,
          fontSize: SizeConfig.small11,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
          maxLines: 2,
        ),
      ],
    );
  }
}

/// Evenly-spaced metric row with hairline seams. Takes 2–4 metrics; more than
/// that and the numbers stop being readable on a phone.
class _MetricRow extends StatelessWidget {
  final List<_Metric> metrics;

  const _MetricRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < metrics.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 1,
          height: 32,
          margin: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          color: const Color(0xFFEDEFF4),
        ));
      }
      children.add(Expanded(child: metrics[i]));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}

/// Labelled progress bar — `label … value` over a track. Used by the funnel,
/// the service mix, the rating distribution and the benchmark, so all four read
/// with the same visual grammar.
class _LabelledBar extends StatelessWidget {
  final String label;
  final String value;

  /// 0–1.
  final double fraction;
  final Color color;

  const _LabelledBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            CustomText(
              value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: const Color(0xFFF1F3F8),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── period selector + banners ────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final SelfWorkStatisticsController controller;

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
          children: SelfWorkStatsPeriod.values.map((p) {
            final isSelected = p == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectPeriod(p),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
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

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size40),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size32),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.secondaryTextColor),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            title,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            body,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
          SizedBox(height: SizeConfig.size12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── 1. EARNINGS ──────────────────────────────────────────────────────────────

/// The money, as one hero number, then the part that has actually been paid.
/// The collected/pending split gets its own bar because "I billed ₹18,450" and
/// "₹4,250 of it is still with customers" are two different facts, and only the
/// second one makes a worker pick up the phone.
class _EarningsCard extends StatelessWidget {
  final SelfWorkEarningsStats earnings;

  const _EarningsCard({required this.earnings});

  @override
  Widget build(BuildContext context) {
    final change = earnings.changePercent;
    final collectedFraction =
        earnings.total <= 0 ? 0.0 : earnings.collected / earnings.total;

    return _Card(
      title: 'Earnings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _money(earnings.total),
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (change != null) _DeltaChip(percent: change),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          _LabelledBar(
            label: 'Collected',
            value: _money(earnings.collected),
            fraction: collectedFraction,
            color: AppColors.green1A,
          ),
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 13, color: AppColors.orange),
              SizedBox(width: SizeConfig.size6),
              Expanded(
                child: CustomText(
                  '${_money(earnings.pending)} still to be collected',
                  fontSize: SizeConfig.small11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size14),
          _MetricRow(metrics: [
            _Metric(
              value: _money(earnings.averageJobValue),
              label: 'Avg. per job',
            ),
            _Metric(
              value: _money(earnings.highestJobValue),
              label: 'Biggest job',
            ),
          ]),
        ],
      ),
    );
  }
}

/// Up/down chip against the previous window. Only rendered when there IS a
/// previous window to compare against — see [SelfWorkEarningsStats.changePercent].
class _DeltaChip extends StatelessWidget {
  final double percent;

  const _DeltaChip({required this.percent});

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;
    final color = up ? AppColors.green1A : AppColors.redLite;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          CustomText(
            '${percent.abs().round()}%',
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ],
      ),
    );
  }
}

// ── 2. WORKLOAD ──────────────────────────────────────────────────────────────

/// The work behind the money. Repeat customers sit here rather than under
/// reputation because a trade lives or dies on people calling back, and this is
/// where the worker is already counting jobs.
class _WorkloadCard extends StatelessWidget {
  final SelfWorkJobStats jobs;

  const _WorkloadCard({required this.jobs});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Jobs',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(metrics: [
            _Metric(value: _count(jobs.completed), label: 'Completed'),
            _Metric(value: _count(jobs.inProgress), label: 'In progress'),
            _Metric(
              value: _count(jobs.cancelledTotal),
              label: 'Cancelled',
              valueColor:
                  jobs.cancelledTotal > 0 ? AppColors.redLite : null,
            ),
          ]),
          SizedBox(height: SizeConfig.size14),
          _MetricRow(metrics: [
            _Metric(
              value: _hoursMinutes(jobs.workedMinutes),
              label: 'Time on jobs',
            ),
            _Metric(
              value: '${jobs.repeatCustomers} · ${_pct(jobs.repeatRate)}',
              label: 'Repeat customers',
              valueColor: AppColors.green1A,
            ),
          ]),
        ],
      ),
    );
  }
}

// ── 3. TREND ─────────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  final List<SelfWorkTrendPoint> trend;

  const _TrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < trend.length; i++)
        FlSpot(i.toDouble(), trend[i].earnings),
    ];
    final values = spots.map((s) => s.y).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);
    // Baseline at zero: for daily earnings a floating baseline exaggerates a
    // quiet day into a cliff, which is exactly the wrong story to tell someone
    // deciding whether to go live tomorrow.
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.2;

    // A month sends up to 31 points. Labelling every one overlaps them into a
    // smear, and weekday names repeat four or five times over that window — so
    // past a week the axis thins out to ~6 ticks and switches to day numbers.
    final weekOrLess = trend.length <= 8;
    final tickEvery = weekOrLess ? 1 : (trend.length / 6).ceil();

    return _Card(
      title: 'Earnings trend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (trend.length - 1).toDouble(),
                minY: 0,
                maxY: chartMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 2,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.greyE6, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: chartMax / 2,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          _axisLabel(value),
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: SizeConfig.extraSmall,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: tickEvery.toDouble(),
                      getTitlesWidget: (value, _) {
                        final i = value.round();
                        if (i < 0 || i >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        // Belt and braces: fl_chart can still ask for an
                        // off-interval tick at the axis ends.
                        if (i % tickEvery != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            weekOrLess ? trend[i].shortLabel : trend[i].dayLabel,
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: SizeConfig.extraSmall,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.mainTextColor,
                    getTooltipItems: (touched) => touched
                        .map((s) => LineTooltipItem(
                              _money(s.y),
                              TextStyle(
                                color: AppColors.white,
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w700,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    // Without this a flat run followed by a spike dips BELOW
                    // the baseline before shooting up — the line appears to go
                    // down on a day the worker earned nothing extra.
                    preventCurveOverShooting: true,
                    color: AppColors.primaryColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
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

  static String _axisLabel(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

// ── 4. ENQUIRY FUNNEL ────────────────────────────────────────────────────────

/// Where the work is won and lost. Bars are all scaled against [received], not
/// against each other, so the drop between two steps is a real visual drop —
/// that gap is the entire point of the section.
class _FunnelCard extends StatelessWidget {
  final SelfWorkEnquiryFunnel funnel;

  const _FunnelCard({required this.funnel});

  @override
  Widget build(BuildContext context) {
    final total = funnel.received;
    double frac(int step) => total <= 0 ? 0 : step / total;

    return _Card(
      title: 'Enquiries',
      subtitle: 'Of every 100 people who enquire, '
          '${funnel.conversionRate.round()} end up hiring you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelledBar(
            label: 'Received',
            value: _count(funnel.received),
            fraction: 1,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: SizeConfig.size10),
          _LabelledBar(
            label: 'You replied',
            value: _count(funnel.responded),
            fraction: frac(funnel.responded),
            color: AppColors.primaryColor.withValues(alpha: 0.75),
          ),
          SizedBox(height: SizeConfig.size10),
          _LabelledBar(
            label: 'You quoted a price',
            value: _count(funnel.quoted),
            fraction: frac(funnel.quoted),
            color: AppColors.primaryColor.withValues(alpha: 0.55),
          ),
          SizedBox(height: SizeConfig.size10),
          _LabelledBar(
            label: 'Became a job',
            value: _count(funnel.converted),
            fraction: frac(funnel.converted),
            color: AppColors.green1A,
          ),
          SizedBox(height: SizeConfig.size14),
          _MetricRow(metrics: [
            _Metric(
              value: _pct(funnel.conversionRate),
              label: 'Conversion',
              valueColor: AppColors.green1A,
            ),
            _Metric(
              value: _responseTime(funnel.medianResponseMinutes),
              label: 'Usual reply time',
            ),
            _Metric(
              value: _count(funnel.missed),
              label: 'Never answered',
              valueColor: funnel.missed > 0 ? AppColors.redLite : null,
            ),
          ]),
        ],
      ),
    );
  }
}

// ── 5. SERVICE MIX ───────────────────────────────────────────────────────────

/// Which of the worker's own listed services actually pay.
///
/// Bars are scaled to the **top earner**, not to 100%, because the useful
/// comparison is "wiring brings in twice what fan fitting does". The backend's
/// `sharePercent` still rides along in the row label — it is share of the
/// worker's TOTAL revenue, which the shown rows don't add up to once the list
/// is truncated, so it can't be derived here.
class _ServiceMixCard extends StatelessWidget {
  final List<SelfWorkServiceBreakdown> services;

  const _ServiceMixCard({required this.services});

  @override
  Widget build(BuildContext context) {
    final top = services
        .map((s) => s.earnings)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return _Card(
      title: 'What pays best',
      subtitle: 'Revenue by the services on your Service tab.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < services.length; i++) ...[
            if (i > 0) SizedBox(height: SizeConfig.size12),
            _LabelledBar(
              label: '${services[i].name}  ·  ${services[i].jobs} jobs'
                  '${services[i].sharePercent > 0 ? '  ·  ${_pct(services[i].sharePercent)}' : ''}',
              value: _money(services[i].earnings),
              fraction: top <= 0 ? 0 : services[i].earnings / top,
              color: AppColors.primaryColor,
            ),
          ],
        ],
      ),
    );
  }
}

// ── 6. REPUTATION ────────────────────────────────────────────────────────────

class _ReputationCard extends StatelessWidget {
  final SelfWorkReputationStats reputation;

  const _ReputationCard({required this.reputation});

  @override
  Widget build(BuildContext context) {
    final max = reputation.maxBucket;

    return _Card(
      title: 'What customers say',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                reputation.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: AppConstants.OpenSans,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  height: 1.05,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final filled = reputation.rating >= i + 0.5;
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 15,
                        color: AppColors.yellow00,
                      );
                    }),
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    '${_count(reputation.ratingCount)} ratings',
                    fontSize: SizeConfig.small11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size14),
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) SizedBox(height: SizeConfig.size6),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: CustomText(
                    '${5 - i}★',
                    fontSize: SizeConfig.small11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: max <= 0 ? 0 : reputation.distribution[i] / max,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F3F8),
                      valueColor: AlwaysStoppedAnimation(AppColors.yellow00),
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                SizedBox(
                  width: 30,
                  child: CustomText(
                    _count(reputation.distribution[i]),
                    fontSize: SizeConfig.small11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: SizeConfig.size14),
          _MetricRow(metrics: [
            // On-time is hidden rather than shown as 0%. The guide (§3
            // `reputation`) says to send `onTimeRate: 0` where there is no
            // "promised completion time" concept yet — rendering that reads as
            // "you are never on time", which is the opposite of the truth.
            if (reputation.onTimeRate > 0)
              _Metric(
                value: _pct(reputation.onTimeRate),
                label: 'Finished on time',
              ),
            _Metric(
              value: _count(reputation.unansweredReviews),
              label: 'Reviews to reply to',
              valueColor:
                  reputation.unansweredReviews > 0 ? AppColors.orange : null,
            ),
          ]),
        ],
      ),
    );
  }
}

// ── 7. AVAILABILITY ──────────────────────────────────────────────────────────

/// Being reachable is half the job for a trade. Driven by the same go-live the
/// Service tab toggles, so the worker can connect "I was offline on Tuesday"
/// with "Tuesday earned nothing" on the trend chart just above.
class _AvailabilityCard extends StatelessWidget {
  final SelfWorkAvailabilityStats availability;

  const _AvailabilityCard({required this.availability});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Availability',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(metrics: [
            _Metric(
              value: _hoursMinutes(availability.liveMinutes),
              label: 'Live time',
            ),
            _Metric(
              value:
                  '${availability.daysLive}/${availability.daysInPeriod}',
              label: 'Days available',
            ),
            _Metric(
              value: _pct(availability.acceptanceRate),
              label: 'Jobs accepted',
            ),
          ]),
          SizedBox(height: SizeConfig.size14),
          _LabelledBar(
            label: 'Days you were reachable',
            value: _pct(availability.coverageRate),
            fraction: availability.coverageRate / 100,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

// ── 8. REACH ─────────────────────────────────────────────────────────────────

/// Top of the funnel. Sits AFTER the funnel deliberately: a worker with no jobs
/// needs to know first whether the problem is "nobody sees me" or "people see
/// me and don't call", and the two cards read together answer that.
class _ReachCard extends StatelessWidget {
  final SelfWorkReachStats reach;

  const _ReachCard({required this.reach});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'How people found you',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(metrics: [
            _Metric(
              value: _count(reach.searchImpressions),
              label: 'Shown in search',
            ),
            _Metric(
              value: _count(reach.profileViews),
              label: 'Profile opened',
            ),
            _Metric(
              value: _count(reach.contactTaps),
              label: 'Contacted you',
            ),
          ]),
          SizedBox(height: SizeConfig.size14),
          _LabelledBar(
            label: 'Viewers who reached out',
            value: _pct(reach.contactRate),
            fraction: reach.contactRate / 100,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: SizeConfig.size12),
          Wrap(
            spacing: SizeConfig.size6,
            runSpacing: SizeConfig.size6,
            children: [
              _TapChip(
                  icon: Icons.call_rounded, label: 'Call', count: reach.callTaps),
              _TapChip(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  count: reach.chatTaps),
              _TapChip(
                  icon: Icons.directions_rounded,
                  label: 'Directions',
                  count: reach.directionTaps),
            ],
          ),
        ],
      ),
    );
  }
}

class _TapChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _TapChip({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            '$label  $count',
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }
}

// ── 9. INDUSTRY BENCHMARK ────────────────────────────────────────────────────

/// The worker against their own trade in their own area.
///
/// Percentiles, not raw peer numbers: "you earn more than 68% of electricians
/// near you" is actionable and anonymous, whereas publishing what the top
/// earner made would both leak a competitor's business and invite the wrong
/// comparison. Peer *medians* are shown alongside because a percentile with no
/// anchor doesn't tell a worker how far off they are.
///
/// Rendered only when [SelfWorkBenchmark.isReliable] — a comparison against
/// three other electricians is noise, and in a thin market it also
/// de-anonymises them.
class _BenchmarkCard extends StatelessWidget {
  final SelfWorkBenchmark benchmark;

  const _BenchmarkCard({required this.benchmark});

  @override
  Widget build(BuildContext context) {
    final label = benchmark.peerGroupLabel.isNotEmpty
        ? benchmark.peerGroupLabel
        : 'Others in your trade';

    return _Card(
      title: 'You vs your trade',
      subtitle: 'Compared with ${benchmark.peerCount} $label. '
          'Higher is better on all three.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BenchmarkRow(
            label: 'Earnings',
            percentile: benchmark.earningsPercentile,
            peerLine: 'Their median ${_money(benchmark.peerMedianEarnings)}',
          ),
          SizedBox(height: SizeConfig.size12),
          _BenchmarkRow(
            label: 'Rating',
            percentile: benchmark.ratingPercentile,
            peerLine:
                'Their median ${benchmark.peerMedianRating.toStringAsFixed(1)}★',
          ),
          SizedBox(height: SizeConfig.size12),
          _BenchmarkRow(
            label: 'Reply speed',
            percentile: benchmark.responsePercentile,
            peerLine: 'They reply in '
                '${_responseTime(benchmark.peerMedianResponseMinutes)}',
          ),
        ],
      ),
    );
  }
}

class _BenchmarkRow extends StatelessWidget {
  final String label;

  /// 0–100, "you are above this share of your peers".
  final double percentile;
  final String peerLine;

  const _BenchmarkRow({
    required this.label,
    required this.percentile,
    required this.peerLine,
  });

  @override
  Widget build(BuildContext context) {
    // Above the middle of the pack is the bar the worker is really judged
    // against, so the colour flips there rather than at some arbitrary "good"
    // threshold we'd have to justify.
    final ahead = percentile >= 50;
    final color = ahead ? AppColors.green1A : AppColors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelledBar(
          label: label,
          value: 'Top ${(100 - percentile).round()}%',
          fraction: percentile / 100,
          color: color,
        ),
        const SizedBox(height: 4),
        CustomText(
          peerLine,
          fontSize: SizeConfig.small11,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }
}
