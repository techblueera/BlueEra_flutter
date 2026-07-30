import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/common/Discover/model/doctor_discover_summary.dart';
import 'package:BlueEra/features/common/Discover/repo/doctor_discover_repo.dart';
import 'package:get/get.dart';

/// Backs the "Clinic Doctors" Discover listing — page 1 on entry, infinite
/// scroll after that.
///
/// Parallel to (and independent of) the hospital list controller: a standalone
/// doctor is its own business account, so mixing the two would drag the doctor
/// enrichment through the hospital adapter that discards it (guide §26).
class DoctorDiscoverController extends GetxController {
  final DoctorDiscoverRepo _repo = DoctorDiscoverRepo();

  final doctors = <DoctorDiscoverSummary>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = ''.obs;

  static const int _pageSize = 20;
  int _page = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  /// Freshness guard so navigating back into the tab doesn't refire the same
  /// request. Keyed by category — `DOCTORS` and `CLINICS` are different feeds.
  final FetchCache _cache = FetchCache();

  String _identity(String category) => 'doctors|$category';

  /// Fetch only when this exact category isn't already loaded & fresh. Use on
  /// screen (re)entry; call [fetchDoctors] directly for pull-to-refresh.
  Future<void> fetchDoctorsIfNeeded({String category = 'DOCTORS'}) async {
    if (_cache.isFresh(_identity(category), hasData: doctors.isNotEmpty)) {
      return;
    }
    await fetchDoctors(category: category);
  }

  /// Loads page 1, replacing the list.
  Future<void> fetchDoctors({String category = 'DOCTORS'}) async {
    isLoading.value = true;
    error.value = '';
    _page = 1;
    _hasMore = true;
    try {
      final res = await _repo.getDoctorListings(
        category: category,
        page: _page,
        limit: _pageSize,
      );
      if (res.isSuccess) {
        final items = _parse(res.response?.data);
        doctors.assignAll(items);
        _hasMore = items.length >= _pageSize;
        // Stamp only on success, and with THIS request's identity, so the next
        // reader can tell whose data is currently in the list.
        _cache.mark(_identity(category));
      } else {
        error.value = res.message ?? AppStrings.somethingWentWrong;
      }
    } catch (e) {
      error.value = AppStrings.somethingWentWrong;
    } finally {
      isLoading.value = false;
    }
  }

  /// Appends the next page. Guarded so hitting the scroll boundary twice can't
  /// double-fire, and so it no-ops once the server has run out of listings.
  Future<void> loadMore({String category = 'DOCTORS'}) async {
    if (isLoading.value || isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final next = _page + 1;
      final res = await _repo.getDoctorListings(
        category: category,
        page: next,
        limit: _pageSize,
      );
      if (res.isSuccess) {
        final items = _parse(res.response?.data);
        if (items.isEmpty) {
          _hasMore = false;
        } else {
          _page = next;
          doctors.addAll(items);
          _hasMore = items.length >= _pageSize;
        }
      } else {
        // A failed page doesn't invalidate what's already on screen — stop
        // paginating rather than clearing the list.
        _hasMore = false;
      }
    } catch (e) {
      _hasMore = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  List<DoctorDiscoverSummary> _parse(dynamic body) {
    final data = (body is Map) ? body['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => DoctorDiscoverSummary.fromJson(
            Map<String, dynamic>.from(e)))
        // A listing with no business id can't be opened, booked or enquired
        // against — drop it rather than render a dead card.
        .where((d) => d.businessId.isNotEmpty)
        .toList();
  }
}
