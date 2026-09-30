import 'dart:developer';

import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/medical/model/hospital_appointment_models.dart';

/// The OPD doctors a hospital offers, for the appointment sheet's picker.
class HospitalDoctorCatalog {
  HospitalDoctorCatalog({BusinessProfileRepo? repo})
      : _repo = repo ?? BusinessProfileRepo();

  final BusinessProfileRepo _repo;

  /// In-memory cache of a hospital's doctors keyed by hospitalId.
  ///
  /// Populated by callers that already have the doctor list (e.g. the
  /// hospital-detail screen from discover) so the enquiry-first flow —
  /// where this sheet is opened from a chat card that doesn't itself
  /// hold the doctors — can still render a real picker instead of an
  /// empty state.
  ///
  /// Session cache: OK to lose on app restart; sheet still opens but
  /// shows an empty picker + prompts the customer to go back through
  /// the hospital screen.
  static final Map<String, List<HospitalAppointmentDoctorOption>> _cache = {};

  /// Register the doctors for [hospitalId]. Call this right before
  /// opening the enquiry sheet from the hospital detail screen so the
  /// eventual appointment sheet can find them. Safe to call multiple
  /// times — later calls overwrite the entry.
  static void remember(
      String hospitalId, List<HospitalAppointmentDoctorOption> doctors) {
    final id = hospitalId.trim();
    if (id.isEmpty) return;
    if (doctors.isEmpty) {
      // Don't blow away a good cache with an empty list — the hospital
      // screen sometimes caches lazily on tap (before the merge lands)
      // and again after merge. Keep whichever list is non-empty.
      if (!_cache.containsKey(id)) {
        // No prior entry → still record the empty so lookups know we
        // tried; the sheet will fall through to its empty state.
        _cache[id] = const [];
      }
    } else {
      _cache[id] = List.unmodifiable(doctors);
    }
    log('[APPOINTMENT] cacheDoctorsForHospital hospitalId=$id '
        'doctors=${doctors.length} (cache size=${_cache.length})');
  }

  /// Fetches the hospital's OPD doctors on demand when the session cache is
  /// empty — happens when the sheet is opened from the accepted-enquiry chat
  /// card without a prior hospital-screen visit (e.g. cold start, deep link,
  /// notification). Mirrors `discover_hospital_home_screen.dart`'s
  /// `viewBusinessProfileById → HospitalFullData → flatten` pipeline, then
  /// seeds the same session cache used by the discover flow.
  ///
  /// Returns whatever it finds (possibly empty) so the picker can fall
  /// through to its empty state on genuine failure.
  Future<List<HospitalAppointmentDoctorOption>> fetch(String hospitalId) async {
    final key = hospitalId.trim();
    if (key.isEmpty) return const [];
    final cached = _cache[key];
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final res = await _repo.viewBusinessProfileById(key);
      if (!res.isSuccess) {
        log('[APPOINTMENT] _fetchDoctorsForHospital hospitalId=$key '
            'profile fetch failed: ${res.message}');
        return const [];
      }
      final hospitalJson = _extractHospitalJson(res.response?.data);
      if (hospitalJson == null) {
        log('[APPOINTMENT] _fetchDoctorsForHospital hospitalId=$key '
            'no hospital JSON in profile response');
        return const [];
      }
      final data = HospitalFullData.fromJson(hospitalJson);
      final doctors = _flattenDoctors(data);
      log('[APPOINTMENT] _fetchDoctorsForHospital hospitalId=$key '
          'fetched ${doctors.length} doctor(s)');
      remember(key, doctors);
      return doctors;
    } catch (e, s) {
      log('[APPOINTMENT] _fetchDoctorsForHospital error hospitalId=$key: $e\n$s');
      return const [];
    }
  }

  /// Field names read by [HospitalFullData.fromJson]. Duplicated from
  /// discover_hospital_home_screen.dart to keep the two flows independent.
  static const _hospitalKeys = <String>[
    '_id',
    'name',
    'description',
    'userId',
    'location',
    'coverUrl',
    'logoUrl',
    'visionMission',
    'history',
    'management',
    'departments',
    'emergencyCare',
    'otherFacilities',
    'emergencyContact',
    'gallery',
    'contacts',
  ];

  /// Builds a flat hospital-JSON map from the business-profile response.
  /// Sections may live at the root, under `data`, or under `vertical_profile`
  /// — pull each key from the first container that carries it. Mirrors the
  /// discover screen's extractor.
  static Map<String, dynamic>? _extractHospitalJson(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'];
    final vp = raw['vertical_profile'];
    final containers = <Map>[
      if (vp is Map && vp['data'] is Map) vp['data'],
      if (vp is Map) vp,
      if (raw['hospital'] is Map) raw['hospital'],
      if (raw['hospitalDetails'] is Map) raw['hospitalDetails'],
      if (data is Map && data['hospital'] is Map) data['hospital'],
      if (data is Map && data['hospitalDetails'] is Map)
        data['hospitalDetails'],
      if (data is Map) data,
      raw,
    ];
    final merged = <String, dynamic>{};
    for (final key in _hospitalKeys) {
      for (final c in containers) {
        if (c.containsKey(key) && c[key] != null) {
          merged[key] = c[key];
          break;
        }
      }
    }
    return merged.isEmpty ? null : merged;
  }

  /// Flattens `departments[].opd[]` into the sheet's slim doctor shape.
  /// Iterates every department (not just `type == 'OPD'`) — the backend
  /// sometimes leaves `type` blank on OPD-only entries.
  static List<HospitalAppointmentDoctorOption> _flattenDoctors(
      HospitalFullData? data) {
    final out = <HospitalAppointmentDoctorOption>[];
    for (final dept in data?.departments ?? const <IpdOpdDepartments>[]) {
      final deptName = (dept.name ?? '').trim();
      for (final doc in dept.opd ?? const <Opd>[]) {
        final id = (doc.id ?? '').trim();
        if (id.isEmpty) continue;
        out.add(HospitalAppointmentDoctorOption(
          id: id,
          name: (doc.name ?? '').trim(),
          department: deptName.isNotEmpty ? deptName : null,
          image: doc.imageUrl,
          timing: doc.timing,
        ));
      }
    }
    return out;
  }

  /// The doctors remembered for [hospitalId], if any.
  static List<HospitalAppointmentDoctorOption>? cached(String hospitalId) =>
      _cache[hospitalId.trim()];

  /// The hospital ids with remembered doctors (for logging).
  static List<String> get cachedIds => _cache.keys.toList();

  /// Forgets every hospital's doctors (tests).
  static void clear() => _cache.clear();
}
