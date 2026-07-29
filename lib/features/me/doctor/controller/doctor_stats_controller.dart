import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_stats_model.dart';
import 'package:BlueEra/features/me/doctor/repo/doctor_profile_repo.dart';
import 'package:get/get.dart';

/// Booking analytics for the Statics tab (`GET /doctors/me/stats`).
///
/// Only the booking numbers live in hospital-service; profile visits, chat
/// clicks and ratings come from user-service and are rendered by the existing
/// `ProfileStatisticsScreen`, which this sits above.
class DoctorStatsController extends GetxController {
  final DoctorProfileRepo _repo = DoctorProfileRepo();

  final Rxn<DoctorStats> stats = Rxn<DoctorStats>();
  final RxBool isLoading = false.obs;

  /// A failed load shows `--` in these tiles only — it must never take the
  /// whole Statics screen down, since the user-service tiles are independent.
  final RxString loadError = ''.obs;

  DateTime? _lastLoadedAt;

  @override
  void onInit() {
    super.onInit();
    fetchStats();
  }

  /// Treated as stale after ~60s, so switching back to the tab doesn't refire
  /// the request on every visit. Pull-to-refresh passes [force].
  Future<void> fetchStats({bool force = false}) async {
    if (!force && _lastLoadedAt != null) {
      final age = DateTime.now().difference(_lastLoadedAt!);
      if (age.inSeconds < 60 && stats.value != null) return;
    }
    isLoading.value = true;
    loadError.value = '';
    try {
      final response = await _repo.getMyStats();
      if (!response.isSuccess) {
        loadError.value = response.message?.toString() ??
            AppStrings.somethingWentWrong.tr;
        return;
      }
      final data = response.data;
      if (data is Map) {
        stats.value = DoctorStats.fromJson(Map<String, dynamic>.from(data));
        _lastLoadedAt = DateTime.now();
      }
    } on Exception catch (e) {
      loadError.value = '${AppStrings.errorFetchingData.tr}: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
