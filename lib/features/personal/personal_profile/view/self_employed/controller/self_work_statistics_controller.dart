import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/self_work_statistics_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/repo/earn_service_repo.dart';
import 'package:get/get.dart';

/// The three windows the Statics tab offers. Deliberately only three: a
/// tradesperson asks "what did I make today", "how is this week going", "what
/// did the month come to". Anything finer is a report, not a dashboard.
enum SelfWorkStatsPeriod { today, week, month }

extension SelfWorkStatsPeriodX on SelfWorkStatsPeriod {
  /// Value sent as `?period=`.
  String get slug => switch (this) {
        SelfWorkStatsPeriod.today => 'today',
        SelfWorkStatsPeriod.week => 'week',
        SelfWorkStatsPeriod.month => 'month',
      };

  String get label => switch (this) {
        SelfWorkStatsPeriod.today => 'Today',
        SelfWorkStatsPeriod.week => 'This Week',
        SelfWorkStatsPeriod.month => 'This Month',
      };
}

/// Loads the skilled worker's statistics dashboard.
///
/// One request per period, cached per period for the life of the screen, so
/// flicking between Today / Week / Month doesn't re-hit the API each time.
/// [reload] forces a refetch.
class SelfWorkStatisticsController extends GetxController {
  // ───────────────────────────────────────────────────────────────────────────
  // SAMPLE DATA — REMOVE WHEN THE ENDPOINT SHIPS
  //
  // `earn-service/self-work/statistics` does not exist yet; the contract we
  // built against is in docs/backend/SELF_WORK_STATISTICS_API_GUIDE.md. While
  // this is true the tab renders representative numbers so the layout can be
  // reviewed, and the view shows a loud "SAMPLE DATA" banner so nobody
  // mistakes them for real earnings.
  //
  // Flip to false the day the endpoint lands — nothing else changes.
  static const bool useSampleData = true;
  // ───────────────────────────────────────────────────────────────────────────

  final Rx<SelfWorkStatsPeriod> period = SelfWorkStatsPeriod.week.obs;
  final Rx<ApiResponse> statsResponse = ApiResponse.initial('Initial').obs;
  final Rxn<SelfWorkStatisticsModel> stats = Rxn<SelfWorkStatisticsModel>();

  /// Per-period cache, so switching windows is instant after the first load.
  final Map<SelfWorkStatsPeriod, SelfWorkStatisticsModel> _cache = {};

  bool get isSample => useSampleData;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectPeriod(SelfWorkStatsPeriod value) {
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
          await EarnServiceRepo().getSelfWorkStatisticsRepo(
        period: selected.slug,
      );
      if (!response.isSuccess) {
        statsResponse.value = ApiResponse.error(response.message?.toString());
        return;
      }
      // Accepts both `{...}` and `{ data: {...} }` — which envelope a service
      // settles on is the sort of thing that changes late.
      final body = response.response?.data;
      final payload = (body is Map && body['data'] is Map)
          ? Map<String, dynamic>.from(body['data'])
          : (body is Map ? Map<String, dynamic>.from(body) : null);
      if (payload == null) {
        statsResponse.value = ApiResponse.error('Unexpected response');
        return;
      }
      final parsed = SelfWorkStatisticsModel.fromJson(payload);
      _cache[selected] = parsed;
      stats.value = parsed;
      statsResponse.value = ApiResponse.complete();
    } catch (e) {
      statsResponse.value = ApiResponse.error('$e');
    }
  }

  // ── sample data ────────────────────────────────────────────────────────────
  // Shaped like a mid-tier electrician's month so every section has something
  // believable to draw: a funnel that loses people at the quote step, a service
  // mix where one line item carries the revenue, and a benchmark the worker
  // sits above on rating but below on response time.

  SelfWorkStatisticsModel _sampleFor(SelfWorkStatsPeriod period) {
    final trade = userProfessionGlobal.isNotEmpty
        ? userProfessionGlobal
        : 'ELECTRICIAN';
    switch (period) {
      case SelfWorkStatsPeriod.today:
        return SelfWorkStatisticsModel(
          period: period.slug,
          profession: trade,
          earnings: const SelfWorkEarningsStats(
            total: 2400,
            collected: 1600,
            pending: 800,
            averageJobValue: 800,
            highestJobValue: 1400,
            previousPeriodTotal: 1900,
          ),
          jobs: const SelfWorkJobStats(
            completed: 3,
            inProgress: 1,
            cancelledByCustomer: 1,
            repeatCustomers: 1,
            workedMinutes: 260,
          ),
          funnel: const SelfWorkEnquiryFunnel(
            received: 7,
            responded: 6,
            quoted: 5,
            converted: 3,
            medianResponseMinutes: 14,
            missed: 1,
          ),
          trend: _sampleTrend(1),
          topServices: _sampleServices,
          reputation: _sampleReputation,
          availability: const SelfWorkAvailabilityStats(
            liveMinutes: 430,
            daysLive: 1,
            daysInPeriod: 1,
            acceptanceRate: 86,
          ),
          reach: const SelfWorkReachStats(
            profileViews: 48,
            searchImpressions: 260,
            callTaps: 6,
            chatTaps: 5,
            directionTaps: 2,
          ),
          benchmark: _sampleBenchmark,
        );
      case SelfWorkStatsPeriod.week:
        return SelfWorkStatisticsModel(
          period: period.slug,
          profession: trade,
          earnings: const SelfWorkEarningsStats(
            total: 18450,
            collected: 14200,
            pending: 4250,
            averageJobValue: 1025,
            highestJobValue: 4600,
            previousPeriodTotal: 15900,
          ),
          jobs: const SelfWorkJobStats(
            completed: 18,
            inProgress: 2,
            cancelledByWorker: 1,
            cancelledByCustomer: 3,
            repeatCustomers: 6,
            workedMinutes: 1810,
          ),
          funnel: const SelfWorkEnquiryFunnel(
            received: 46,
            responded: 39,
            quoted: 31,
            converted: 18,
            medianResponseMinutes: 22,
            missed: 7,
          ),
          trend: _sampleTrend(7),
          topServices: _sampleServices,
          reputation: _sampleReputation,
          availability: const SelfWorkAvailabilityStats(
            liveMinutes: 2680,
            daysLive: 6,
            daysInPeriod: 7,
            acceptanceRate: 84,
          ),
          reach: const SelfWorkReachStats(
            profileViews: 312,
            searchImpressions: 1840,
            callTaps: 41,
            chatTaps: 33,
            directionTaps: 12,
          ),
          benchmark: _sampleBenchmark,
        );
      case SelfWorkStatsPeriod.month:
        return SelfWorkStatisticsModel(
          period: period.slug,
          profession: trade,
          earnings: const SelfWorkEarningsStats(
            total: 74800,
            collected: 64100,
            pending: 10700,
            averageJobValue: 1058,
            highestJobValue: 9200,
            previousPeriodTotal: 81200,
          ),
          jobs: const SelfWorkJobStats(
            completed: 71,
            inProgress: 3,
            cancelledByWorker: 4,
            cancelledByCustomer: 9,
            repeatCustomers: 27,
            workedMinutes: 7420,
          ),
          funnel: const SelfWorkEnquiryFunnel(
            received: 184,
            responded: 158,
            quoted: 126,
            converted: 71,
            medianResponseMinutes: 26,
            missed: 26,
          ),
          trend: _sampleTrend(7),
          topServices: _sampleServices,
          reputation: _sampleReputation,
          availability: const SelfWorkAvailabilityStats(
            liveMinutes: 11240,
            daysLive: 26,
            daysInPeriod: 30,
            acceptanceRate: 88,
          ),
          reach: const SelfWorkReachStats(
            profileViews: 1290,
            searchImpressions: 7460,
            callTaps: 168,
            chatTaps: 140,
            directionTaps: 47,
          ),
          benchmark: _sampleBenchmark,
        );
    }
  }

  static const List<SelfWorkServiceBreakdown> _sampleServices = [
    SelfWorkServiceBreakdown(
      name: 'House wiring',
      jobs: 6,
      earnings: 7400,
      sharePercent: 40,
    ),
    SelfWorkServiceBreakdown(
      name: 'Fan & light installation',
      jobs: 7,
      earnings: 4300,
      sharePercent: 23,
    ),
    SelfWorkServiceBreakdown(
      name: 'Inverter / stabiliser setup',
      jobs: 3,
      earnings: 3600,
      sharePercent: 20,
    ),
    SelfWorkServiceBreakdown(
      name: 'Switchboard repair',
      jobs: 2,
      earnings: 3150,
      sharePercent: 17,
    ),
  ];

  static const SelfWorkReputationStats _sampleReputation =
      SelfWorkReputationStats(
    rating: 4.6,
    ratingCount: 87,
    distribution: [58, 19, 6, 3, 1],
    onTimeRate: 92,
    unansweredReviews: 4,
  );

  static const SelfWorkBenchmark _sampleBenchmark = SelfWorkBenchmark(
    peerGroupLabel: 'Electricians near you',
    peerCount: 34,
    earningsPercentile: 68,
    ratingPercentile: 81,
    responsePercentile: 42,
    peerMedianEarnings: 15200,
    peerMedianRating: 4.3,
    peerMedianResponseMinutes: 17,
  );

  List<SelfWorkTrendPoint> _sampleTrend(int days) {
    const amounts = [1900.0, 3200.0, 2100.0, 4100.0, 2750.0, 2000.0, 2400.0];
    const counts = [2, 4, 2, 4, 3, 2, 3];
    final today = DateTime.now();
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final idx = (7 - days + i).clamp(0, 6);
      return SelfWorkTrendPoint(
        date: '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}',
        earnings: amounts[idx],
        jobs: counts[idx],
      );
    });
  }
}
