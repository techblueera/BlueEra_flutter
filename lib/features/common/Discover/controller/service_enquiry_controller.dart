import 'dart:async';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// Service enquiries from Discover: the per-profession enquiry options (cached
/// for the session) and sending / answering an enquiry. Holds no account data.
class ServiceEnquiryController extends GetxController {
  /// Registered on first use and kept, so the option caches survive re-opens.
  static ServiceEnquiryController get to =>
      Get.isRegistered<ServiceEnquiryController>()
          ? Get.find<ServiceEnquiryController>()
          : Get.put(ServiceEnquiryController(), permanent: true);

  /// Service-enquiry submission used by the Discover self-profession
  /// "Enquire" form. **Dummy for now** — it simulates a successful network
  /// round-trip so the form → chat flow works end-to-end. Swap the body for
  /// the real `DiscoverRepo` call once the backend endpoint exists (which,
  /// like the grocery order flow, should also create the in-chat enquiry card
  /// + emit a socket event so it surfaces on the provider's side).
  /// Backend `earn-service/service-enquiries` endpoints are live, so the real
  /// REST calls run. Set to `true` only to fall back to a simulated success
  /// (e.g. for local UI testing without the backend).
  static const bool _useServiceEnquiryStub = false;

  RxBool isServiceEnquiryLoading = false.obs;

  /// [selections] is keyed by the enquiry group api key
  /// (`serviceType` / `typesOfWork` / `servicesOffered`); each value is the
  /// list of options the customer ticked. Sent as-is in the request body.
  Future<bool> submitServiceEnquiry({
    required String providerId,
    required Map<String, List<String>> selections,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    try {
      isServiceEnquiryLoading.value = true;
      AppLoader.show();

      if (_useServiceEnquiryStub) {
        await Future.delayed(const Duration(milliseconds: 600));
        return true;
      }

      // Only non-empty arrays (filtered upstream) + a non-empty note are sent,
      // mirroring the server-side "at least one selection or a note" gating.
      final body = <String, dynamic>{
        ApiKeys.provider_id: providerId,
        ...selections,
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      final response = await DiscoverRepo()
          .sendServiceEnquiry(params: body, photoPaths: photoPaths);
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      AppLoader.hide();
      isServiceEnquiryLoading.value = false;
    }
  }

  /// Segment query key → enquiry-body apiKey + display title for the dynamic
  /// enquiry options. The segments are fetched from the predefined-category API
  /// per the provider's profession so the customer picks profession-relevant
  /// choices (electrician / plumber / …) instead of static data.
  static const List<Map<String, String>> _enquiryOptionSegments = [
    {'segment': 'serviceTypes', 'apiKey': 'serviceType', 'title': 'Service Type'},
    {'segment': 'typesOfWork', 'apiKey': 'typesOfWork', 'title': 'Type of Work'},
    {
      'segment': 'workCategories',
      'apiKey': 'workCategories',
      'title': 'Work Categories'
    },
    {
      'segment': 'servicesOffered',
      'apiKey': 'servicesOffered',
      'title': 'Services Offered'
    },
  ];

  /// Per-profession cache so the enquiry sheet never refetches the same
  /// profession — across providers, tab switches, and re-opens. Keyed by the
  /// category slug (e.g. ELECTRICIAN). [_enquiryOptionsInflight] dedupes
  /// concurrent callers (e.g. a prefetch racing with an open) onto one request.
  final Map<String, List<Map<String, dynamic>>> _enquiryOptionsCache = {};
  final Map<String, Future<List<Map<String, dynamic>>>>
      _enquiryOptionsInflight = {};

  /// Warm the cache for a profession [category] without awaiting — called when
  /// a profession tab loads so the Enquire sheet opens instantly later and the
  /// same profession is never fetched twice.
  void prefetchEnquiryOptions(String? category) {
    final key = (category ?? '').trim();
    if (key.isEmpty || _enquiryOptionsCache.containsKey(key)) return;
    fetchEnquiryOptions(key);
  }

  /// Returns the predefined option catalog for a provider's profession
  /// [category] as `{apiKey, title, options}` groups. Cached: a profession is
  /// fetched at most once per session. An empty [category] yields an empty list.
  Future<List<Map<String, dynamic>>> fetchEnquiryOptions(String category) async {
    final key = category.trim();
    if (key.isEmpty) return [];

    final cached = _enquiryOptionsCache[key];
    if (cached != null) return cached;
    final inflight = _enquiryOptionsInflight[key];
    if (inflight != null) return inflight;

    final future = _fetchEnquiryOptionsFromApi(key);
    _enquiryOptionsInflight[key] = future;
    try {
      final result = await future;
      _enquiryOptionsCache[key] = result;
      return result;
    } finally {
      _enquiryOptionsInflight.remove(key);
    }
  }

  /// ONE network call — no `segment` param, so the backend returns the whole
  /// predefined catalog for the profession; we split it client-side into the
  /// enquiry segments.
  Future<List<Map<String, dynamic>>> _fetchEnquiryOptionsFromApi(
      String category) async {
    Map<String, List<String>> bySegment = const {};
    try {
      final response = await DiscoverRepo().fetchPredefinedCategory(
        professionCategory: category,
        queryParams: const {},
      );
      if (response.isSuccess) {
        bySegment = _parseAllPredefinedSegments(response.response?.data);
      }
    } catch (_) {}

    final out = <Map<String, dynamic>>[];
    for (final seg in _enquiryOptionSegments) {
      final items = (bySegment[seg['segment']] ?? const <String>[])
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        out.add({
          'apiKey': seg['apiKey']!,
          'title': seg['title']!,
          'options': items,
        });
      }
    }
    return out;
  }

  /// Splits the all-segments predefined response into a `segment → options`
  /// map. The response is a flat document keyed by segment, e.g.:
  /// `{ "category":"LABOUR", "serviceTypes":[], "typesOfWork":[…],
  ///    "workCategories":[…], "servicesOffered":[…], "expertise":[…] }`.
  /// (A `data` envelope is unwrapped if present.)
  Map<String, List<String>> _parseAllPredefinedSegments(dynamic data) {
    final result = <String, List<String>>{};
    dynamic root = data;
    if (root is Map && root['data'] is Map) root = root['data'];
    if (root is! Map) return result;
    for (final seg in _enquiryOptionSegments) {
      final v = root[seg['segment']];
      if (v is List) {
        result[seg['segment']!] = v.map((e) => e.toString()).toList();
      }
    }
    return result;
  }

  // ── Professional-consultant enquiry options ─────────────────────────
  // Consultants use a different predefined endpoint
  // (`earn-service/predefined-professional/<slug>`) that returns a single
  // `servicesOffered` segment. Cached per profession slug, same as self-work.
  final Map<String, List<Map<String, dynamic>>> _consultantOptionsCache = {};
  final Map<String, Future<List<Map<String, dynamic>>>>
      _consultantOptionsInflight = {};

  void prefetchConsultantEnquiryOptions(String? professionSlug) {
    final key = (professionSlug ?? '').trim();
    if (key.isEmpty || _consultantOptionsCache.containsKey(key)) return;
    fetchConsultantEnquiryOptions(key);
  }

  /// Returns the consultant's predefined option groups (`Services Offered`)
  /// as `{apiKey, title, options}` maps. Cached per profession slug.
  Future<List<Map<String, dynamic>>> fetchConsultantEnquiryOptions(
      String professionSlug) async {
    final key = professionSlug.trim();
    if (key.isEmpty) return [];

    final cached = _consultantOptionsCache[key];
    if (cached != null) return cached;
    final inflight = _consultantOptionsInflight[key];
    if (inflight != null) return inflight;

    final future = _fetchConsultantOptionsFromApi(key);
    _consultantOptionsInflight[key] = future;
    try {
      final result = await future;
      _consultantOptionsCache[key] = result;
      return result;
    } finally {
      _consultantOptionsInflight.remove(key);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchConsultantOptionsFromApi(
      String professionSlug) async {
    var servicesOffered = const <String>[];
    try {
      final response =
          await DiscoverRepo().fetchPredefinedProfession(professionSlug: professionSlug);
      if (response.isSuccess) {
        dynamic root = response.response?.data;
        if (root is Map && root['data'] is Map) root = root['data'];
        if (root is Map && root['servicesOffered'] is List) {
          servicesOffered =
              (root['servicesOffered'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    final items = servicesOffered.where((e) => e.trim().isNotEmpty).toList();
    if (items.isEmpty) return [];
    return [
      {'apiKey': 'servicesOffered', 'title': 'Services Offered', 'options': items},
    ];
  }

  /// Provider accepts / declines a service enquiry from the in-chat card.
  /// [status] is 'accepted' or 'declined'. Returns true on success.
  Future<bool> updateServiceEnquiryStatus({
    required String enquiryId,
    required String status,
  }) async {
    if (_useServiceEnquiryStub) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    try {
      final response = await DiscoverRepo().updateServiceEnquiryStatus(
        enquiryId: enquiryId,
        params: {ApiKeys.status: status},
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }
}
