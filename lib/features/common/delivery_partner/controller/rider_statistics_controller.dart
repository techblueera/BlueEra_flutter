import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_statistics_model.dart';
import 'package:BlueEra/features/common/delivery_partner/repo/delivery_partner_repo.dart';
import 'package:get/get.dart';

/// The three windows the Statistics tab offers. Deliberately only three: a
/// rider asks "what did I make today", "how is this week going", "what did the
/// month come to" — anything finer is a report, not a dashboard.
enum RiderStatsPeriod { today, week, month }

extension RiderStatsPeriodX on RiderStatsPeriod {
  /// Value sent as `?period=`.
  String get slug => switch (this) {
        RiderStatsPeriod.today => 'today',
        RiderStatsPeriod.week => 'week',
        RiderStatsPeriod.month => 'month',
      };

  String get label => switch (this) {
        RiderStatsPeriod.today => 'Today',
        RiderStatsPeriod.week => 'This Week',
        RiderStatsPeriod.month => 'This Month',
      };
}

/// Loads the rider's earnings + performance dashboard.
///
/// One request per period, cached per period for the life of the screen, so
/// flicking between Today / Week / Month doesn't re-hit the API each time.
/// Pull-to-refresh and [reload] force a refetch.
class RiderStatisticsController extends GetxController {
  // ─────────────────────────────────────────────────────────────────────────
  // SAMPLE DATA — OFF. The endpoint is live.
  //
  // `rider-service/riders/statistics` is implemented and serving
  // (docs/backend/RIDER_STATISTICS_FLUTTER_GUIDE.md). The sample generator is
  // kept for working on the layout without a rider account or a network — flip
  // this to true and the tab renders invented numbers behind a loud "SAMPLE
  // DATA" banner. Never ship it true.
  //
  // The samples carry the same `_meta.unavailable` list the live backend sends
  // today, so what you preview is what a rider actually sees — a preview that
  // showed payouts and hours-online would be a preview of a screen nobody has.
  static const bool useSampleData = false;
  // ─────────────────────────────────────────────────────────────────────────

  final Rx<RiderStatsPeriod> period = RiderStatsPeriod.today.obs;
  final Rx<ApiResponse> statsResponse = ApiResponse.initial('Initial').obs;
  final Rxn<RiderStatisticsModel> stats = Rxn<RiderStatisticsModel>();

  /// Per-period cache, so switching tabs is instant after the first load.
  final Map<RiderStatsPeriod, RiderStatisticsModel> _cache = {};

  bool get isSample => useSampleData;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectPeriod(RiderStatsPeriod value) {
    if (period.value == value) return;
    period.value = value;
    load();
  }

  Future<void> reload() => load(forceRefresh: true);

  Future<void> load({bool forceRefresh = false}) async {
    final selected = period.value;

    if (!forceRefresh && _cache.containsKey(selected)) {
      stats.value = _cache[selected];
      statsResponse.value = ApiResponse.complete();
      return;
    }

    statsResponse.value = ApiResponse.loading('Loading');

    if (useSampleData) {
      final sample = _sampleFor(selected);
      _cache[selected] = sample;
      stats.value = sample;
      statsResponse.value = ApiResponse.complete();
      return;
    }

    try {
      final ResponseModel response =
          await DeliveryPartnerRepo().getRiderStatisticsRepo(
        period: selected.slug,
      );
      if (!response.isSuccess) {
        statsResponse.value = ApiResponse.error(response.message?.toString());
        return;
      }
      // Accepts both `{...}` and `{ data: {...} }` — which one the service
      // returns is the sort of thing that changes late.
      final body = response.response?.data;
      final payload = (body is Map && body['data'] is Map)
          ? Map<String, dynamic>.from(body['data'])
          : (body is Map ? Map<String, dynamic>.from(body) : null);
      if (payload == null) {
        statsResponse.value = ApiResponse.error('Unexpected response');
        return;
      }
      final parsed = RiderStatisticsModel.fromJson(payload);
      _cache[selected] = parsed;
      stats.value = parsed;
      statsResponse.value = ApiResponse.complete();
    } catch (e) {
      statsResponse.value = ApiResponse.error('$e');
    }
  }

  // ── sample data ──────────────────────────────────────────────────────────

  /// What `be_rider_service` currently reports it cannot source. Mirrored into
  /// the samples so the offline preview matches the live screen exactly.
  static const RiderStatsMeta _sampleMeta = RiderStatsMeta(unavailable: [
    'earnings.incentives',
    'earnings.tips',
    'earnings.deductions',
    'trips.onlineMinutes',
    'payouts.pending',
    'payouts.lastAmount',
    'payouts.lastPaidAt',
  ]);

  RiderStatisticsModel _sampleFor(RiderStatsPeriod period) {
    switch (period) {
      case RiderStatsPeriod.today:
        return RiderStatisticsModel(
          period: period.slug,
          earnings: const RiderEarningsStats(
            total: 742,
            tripFare: 690,
            incentives: 40,
            tips: 30,
            deductions: 18,
          ),
          trips: const RiderTripStats(
            completed: 6,
            cancelledByRider: 0,
            cancelledByCustomer: 1,
            distanceKm: 38.4,
            onlineMinutes: 305,
          ),
          performance: const RiderPerformanceStats(
            acceptanceRate: 88,
            cancellationRate: 6,
            completionRate: 94,
            rating: 4.7,
            ratingCount: 132,
          ),
          trend: _sampleTrend(1),
          payouts: const RiderPayoutStats(pending: 742, lastAmount: 3120),
          meta: _sampleMeta,
        );
      case RiderStatsPeriod.week:
        return RiderStatisticsModel(
          period: period.slug,
          earnings: const RiderEarningsStats(
            total: 4685,
            tripFare: 4290,
            incentives: 300,
            tips: 210,
            deductions: 115,
          ),
          trips: const RiderTripStats(
            completed: 39,
            cancelledByRider: 2,
            cancelledByCustomer: 3,
            distanceKm: 244.8,
            onlineMinutes: 1985,
          ),
          performance: const RiderPerformanceStats(
            acceptanceRate: 91,
            cancellationRate: 5,
            completionRate: 95,
            rating: 4.7,
            ratingCount: 132,
          ),
          trend: _sampleTrend(7),
          payouts: const RiderPayoutStats(pending: 1565, lastAmount: 3120),
          meta: _sampleMeta,
        );
      case RiderStatsPeriod.month:
        return RiderStatisticsModel(
          period: period.slug,
          earnings: const RiderEarningsStats(
            total: 19420,
            tripFare: 17800,
            incentives: 1100,
            tips: 520,
            deductions: 480,
          ),
          trips: const RiderTripStats(
            completed: 164,
            cancelledByRider: 6,
            cancelledByCustomer: 11,
            distanceKm: 1032.6,
            onlineMinutes: 8460,
          ),
          performance: const RiderPerformanceStats(
            acceptanceRate: 93,
            cancellationRate: 4,
            completionRate: 96,
            rating: 4.8,
            ratingCount: 132,
          ),
          trend: _sampleTrend(7),
          payouts: const RiderPayoutStats(pending: 1565, lastAmount: 3120),
          meta: _sampleMeta,
        );
    }
  }

  List<RiderTrendPoint> _sampleTrend(int days) {
    const amounts = [520.0, 690.0, 430.0, 880.0, 610.0, 812.0, 742.0];
    const counts = [4, 6, 3, 8, 5, 7, 6];
    final today = DateTime.now();
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final idx = (7 - days + i).clamp(0, 6);
      return RiderTrendPoint(
        date: '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}',
        earnings: amounts[idx],
        trips: counts[idx],
      );
    });
  }
}
