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
  final Rx<RiderStatsPeriod> period = RiderStatsPeriod.today.obs;
  final Rx<ApiResponse> statsResponse = ApiResponse.initial('Initial').obs;
  final Rxn<RiderStatisticsModel> stats = Rxn<RiderStatisticsModel>();

  /// Per-period cache, so switching tabs is instant after the first load.
  final Map<RiderStatsPeriod, RiderStatisticsModel> _cache = {};

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
}
