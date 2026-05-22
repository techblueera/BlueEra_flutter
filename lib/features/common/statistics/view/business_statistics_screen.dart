import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/statistics/controller/business_statistics_controller.dart';
import 'package:BlueEra/features/me/medical/model/chat_click_analytics_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Statistics tab shared across every business-type screen (medical, hotel,
/// hospital, lab, school, food, grocery, manufacturer, etc.).
///
/// Renders KPI cards backed by the centralized chat-click analytics endpoint
/// (`GET /business/:businessId/chat-clicks?format=full`). Each card shows a
/// big headline number plus a line chart of the matching timeseries — the
/// design mirrors `assets/dummy/chart.png`.
class BusinessStatisticsScreen extends StatefulWidget {
  final String businessId;

  const BusinessStatisticsScreen({super.key, required this.businessId});

  @override
  State<BusinessStatisticsScreen> createState() =>
      _BusinessStatisticsScreenState();
}

class _BusinessStatisticsScreenState extends State<BusinessStatisticsScreen>
    with AutomaticKeepAliveClientMixin {
  late final BusinessStatisticsController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = getOrPut(() => BusinessStatisticsController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.init(businessId: widget.businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ColoredBox(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        final status = _controller.analyticsResponse.value.status;
        final hasData = _controller.analytics.value != null;

        if (status == Status.LOADING && !hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 120),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (status == Status.ERROR && !hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: _ErrorState(
              message: _controller.errorMessage.value ??
                  'Unable to load statistics',
              onRetry: _controller.refresh,
            ),
          );
        }

        final data = _controller.analytics.value?.data;
        if (data == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: _ErrorState(
              message: 'No analytics data available',
              onRetry: _controller.refresh,
            ),
          );
        }

        return _StatisticsBody(
          data: data,
          range: _controller.selectedRange.value,
          onRangeChanged: _controller.changeRange,
        );
      }),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  final ChatClickAnalyticsData data;
  final StatsRange range;
  final ValueChanged<StatsRange> onRangeChanged;

  const _StatisticsBody({
    required this.data,
    required this.range,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final ts = data.timeseries;
    final lastClickedAt = summary.lastClickedAt;

    final clickPoints = ts?.series ?? const <ChatClickSeriesPoint>[];
    final clicksAvg = _averageOf(clickPoints, (p) => p.clicks);
    final usersAvg = _averageOf(clickPoints, (p) => p.uniqueUsers);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.paddingS,
        SizeConfig.paddingS,
        SizeConfig.paddingS,
        SizeConfig.paddingXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RangeSelector(selected: range, onChanged: onRangeChanged),
          SizedBox(height: SizeConfig.paddingS),
          _StatCard(
            title: 'Chat Count',
            headlineLabel: '${range.label} average',
            headlineValue: _formatLakh(summary.totalClicks),
            asOfDate: lastClickedAt,
            asOfValue: clickPoints.isNotEmpty
                ? _formatLakh(clickPoints.last.clicks)
                : _formatLakh(summary.totalClicks),
            trailingAverage: clicksAvg,
            spots: _toSpots(clickPoints, (p) => p.clicks),
            xLabels: _xAxisLabels(clickPoints),
            lineColor: AppColors.darkBlueShade,
          ),
          SizedBox(height: SizeConfig.paddingS),
          _StatCard(
            title: 'Profile visits',
            headlineLabel: '${range.label} average',
            headlineValue: _formatLakh(summary.uniqueUsers),
            asOfDate: lastClickedAt,
            asOfValue: clickPoints.isNotEmpty
                ? _formatLakh(clickPoints.last.uniqueUsers)
                : _formatLakh(summary.uniqueUsers),
            trailingAverage: usersAvg,
            spots: _toSpots(clickPoints, (p) => p.uniqueUsers),
            xLabels: _xAxisLabels(clickPoints),
            lineColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  static double _averageOf(
    List<ChatClickSeriesPoint> points,
    int Function(ChatClickSeriesPoint) reader,
  ) {
    if (points.isEmpty) return 0;
    final total = points.fold<int>(0, (sum, p) => sum + reader(p));
    return total / points.length;
  }

  static List<FlSpot> _toSpots(
    List<ChatClickSeriesPoint> points,
    int Function(ChatClickSeriesPoint) reader,
  ) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), reader(points[i]).toDouble()));
    }
    return spots;
  }

  static List<String> _xAxisLabels(List<ChatClickSeriesPoint> points) {
    if (points.length < 2) {
      return points
          .map((p) => p.bucket == null ? '' : DateFormat('d MMM').format(p.bucket!))
          .toList();
    }
    final formatter = DateFormat('d MMM');
    return [
      points.first.bucket == null ? '' : formatter.format(points.first.bucket!),
      points.last.bucket == null ? '' : formatter.format(points.last.bucket!),
    ];
  }

  static String _formatLakh(num value) {
    if (value >= 100000) {
      final v = value / 100000.0;
      final formatted = v >= 10
          ? v.toStringAsFixed(2)
          : v.toStringAsFixed(2);
      return '${formatted}L';
    }
    if (value >= 1000) {
      return NumberFormat('#,##0').format(value);
    }
    return value.toString();
  }
}

class _RangeSelector extends StatelessWidget {
  final StatsRange selected;
  final ValueChanged<StatsRange> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: StatsRange.values.length,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.paddingXS),
        itemBuilder: (_, index) {
          final value = StatsRange.values[index];
          final isSelected = value == selected;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.paddingS,
                vertical: SizeConfig.paddingXSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.darkBlueShade
                    : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.darkBlueShade
                      : AppColors.borderGray,
                ),
              ),
              alignment: Alignment.center,
              child: CustomText(
                value.label,
                color: isSelected ? AppColors.white : AppColors.black28,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String headlineLabel;
  final String headlineValue;
  final DateTime? asOfDate;
  final String asOfValue;
  final double trailingAverage;
  final List<FlSpot> spots;
  final List<String> xLabels;
  final Color lineColor;

  const _StatCard({
    required this.title,
    required this.headlineLabel,
    required this.headlineValue,
    required this.asOfDate,
    required this.asOfValue,
    required this.trailingAverage,
    required this.spots,
    required this.xLabels,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final asOfLabel = asOfDate != null
        ? DateFormat('d MMM yyyy').format(asOfDate!)
        : '—';

    return Container(
      padding: EdgeInsets.all(SizeConfig.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  title,
                  color: AppColors.black28,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 20,
                color: AppColors.black28,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      headlineLabel,
                      color: AppColors.grey6D,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: SizeConfig.paddingXSmall),
                    CustomText(
                      headlineValue,
                      color: AppColors.black28,
                      fontSize: SizeConfig.title,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    asOfLabel,
                    color: AppColors.grey6D,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: SizeConfig.paddingXSmall),
                  CustomText(
                    asOfValue,
                    color: AppColors.black28,
                    fontSize: SizeConfig.title,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingS),
          SizedBox(
            height: 140,
            child: spots.isEmpty
                ? _ChartEmptyState()
                : _LineChart(
                    spots: spots,
                    lineColor: lineColor,
                  ),
          ),
          SizedBox(height: SizeConfig.paddingXSmall),
          if (xLabels.length >= 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  xLabels.first,
                  color: AppColors.grey6D,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                ),
                CustomText(
                  xLabels.last,
                  color: AppColors.grey6D,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color lineColor;

  const _LineChart({required this.spots, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY) * 0.15;
    final chartMin = (minY - padding).clamp(0, double.infinity).toDouble();
    final chartMax = maxY + padding;
    final ySpan = chartMax - chartMin;
    final yInterval = ySpan <= 0 ? 1.0 : ySpan / 2;

    return LineChart(
      LineChartData(
        minX: spots.first.x,
        maxX: spots.last.x,
        minY: chartMin,
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.greyE6,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yInterval,
              getTitlesWidget: (value, _) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _yLabel(value),
                    style: TextStyle(
                      color: AppColors.grey6D,
                      fontSize: SizeConfig.extraSmall,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.black28,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (s) => LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    TextStyle(
                      color: AppColors.white,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  String _yLabel(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(3)}L';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _ChartEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomText(
        'No data available',
        color: AppColors.grey6D,
        fontSize: SizeConfig.small,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.paddingL,
        vertical: SizeConfig.paddingXXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: AppColors.grey6D,
          ),
          SizedBox(height: SizeConfig.paddingS),
          CustomText(
            message,
            color: AppColors.black28,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.paddingS),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
