import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
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
  final Rx<SelfWorkStatsPeriod> period = SelfWorkStatsPeriod.week.obs;
  final Rx<ApiResponse> statsResponse = ApiResponse.initial('Initial').obs;
  final Rxn<SelfWorkStatisticsModel> stats = Rxn<SelfWorkStatisticsModel>();

  /// Per-period cache, so switching windows is instant after the first load.
  final Map<SelfWorkStatsPeriod, SelfWorkStatisticsModel> _cache = {};

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
}
