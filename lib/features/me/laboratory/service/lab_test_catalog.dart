import 'dart:developer';

import 'package:BlueEra/features/me/laboratory/model/lab_booking_models.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';

/// The tests a laboratory offers, for the lab booking sheet's picker.
///
/// Session cache keyed by laboratoryId. Filled by callers that already have
/// the catalog (e.g. the lab detail screen) so the enquiry-first flow — where
/// the sheet is opened from a chat card that doesn't itself hold the tests —
/// can still render a real picker instead of an empty state; [fetch] fills it
/// on demand otherwise.
class LabTestCatalog {
  LabTestCatalog({LabTestRepo? repo}) : _repo = repo ?? LabTestRepo();

  final LabTestRepo _repo;

  static final Map<String, List<LabBookingTestOption>> _cache = {};

  /// Remembers [tests] for [laboratoryId]. An empty list never replaces a
  /// good one.
  static void remember(String laboratoryId, List<LabBookingTestOption> tests) {
    final id = laboratoryId.trim();
    if (id.isEmpty) return;
    if (tests.isEmpty) {
      if (!_cache.containsKey(id)) _cache[id] = const [];
    } else {
      _cache[id] = List.unmodifiable(tests);
    }
    log('[LAB_BOOKING] cacheTestsForLab labId=$id '
        'tests=${tests.length} (cache size=${_cache.length})');
  }

  /// The tests remembered for [laboratoryId], if any.
  static List<LabBookingTestOption>? cached(String laboratoryId) =>
      _cache[laboratoryId.trim()];

  /// Forgets every lab's tests (tests).
  static void clear() => _cache.clear();

  /// The lab's tests: the cached list when there is a non-empty one, else
  /// `getPathologyTestsByLab(labId, '')`. Empty on failure, so the picker
  /// falls through to its empty state.
  Future<List<LabBookingTestOption>> fetch(String laboratoryId) async {
    final key = laboratoryId.trim();
    if (key.isEmpty) return const [];
    final hit = _cache[key];
    if (hit != null && hit.isNotEmpty) return hit;
    try {
      final res = await _repo.getPathologyTestsByLab(key, '');
      if (!res.isSuccess) {
        log('[LAB_BOOKING] _fetchTestsForLab labId=$key '
            'failed: ${res.message}');
        return const [];
      }
      final data = res.response?.data;
      final list = (data is Map ? data['data'] : null);
      if (list is! List) return const [];
      final options = list
          .whereType<Map>()
          .map((m) => LabBookingTestOption.fromPathology(
              PathologyTest.fromJson(Map<String, dynamic>.from(m))))
          .where((o) => o.id.isNotEmpty)
          .toList();
      remember(key, options);
      return options;
    } catch (e, s) {
      log('[LAB_BOOKING] _fetchTestsForLab error labId=$key: $e\n$s');
      return const [];
    }
  }
}
