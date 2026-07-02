import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/others/model/predefined_enquiry_group.dart';
import 'package:BlueEra/features/me/others/repo/other_enquiry_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the "other" business enquiry flow (banking / insurance
/// / loans / capital-market / data). JSON-only endpoint — photos are
/// presign-uploaded before submission so the request body can carry public
/// URLs (see lib/docs/other-enquiry-ui-integration.md §1 + §2).
class OtherEnquiryController extends GetxController {
  /// Backend is live. Flip to `true` to exercise the sheet offline.
  static const bool _useStub = false;

  final RxBool isSubmitting = false.obs;

  /// Per-category cache of the server-driven chip catalog. Populated by
  /// [loadPredefinedEnquiryOptions] and drained on logout via [onClose].
  /// Keeps the sheet snappy: prefetch on the listing detail screen means
  /// tapping "Enquire" opens a fully-rendered form with no network wait.
  /// See lib/docs/predefined-enquiry-ui-integration.md §2 "Prefetch + cache".
  ///
  /// Special sentinel: the empty list is cached for categories the server
  /// doesn't recognise (400/404) so the sheet stops re-hitting the endpoint
  /// for that category in the same session.
  final Map<String, List<PredefinedEnquiryGroup>> _optionsCache = {};

  /// In-flight fetch de-dupe — coalesces concurrent prefetch + open-sheet
  /// calls into a single request per category.
  final Map<String, Future<List<PredefinedEnquiryGroup>>> _optionsInFlight = {};

  /// Fetch (or return cached) chip catalog for [category]. The sheet
  /// should await this; on any failure it resolves to an empty list —
  /// callers then fall back to the static defaults / note-only form
  /// (§1 error table). Never surfaces a snackbar — this is a
  /// prefetch-friendly, best-effort call.
  Future<List<PredefinedEnquiryGroup>> loadPredefinedEnquiryOptions(
      String category) {
    final slug = category.trim().toUpperCase();
    if (slug.isEmpty) return Future.value(const []);
    final cached = _optionsCache[slug];
    if (cached != null) return Future.value(cached);
    final pending = _optionsInFlight[slug];
    if (pending != null) return pending;

    final future = _fetchPredefinedEnquiryOptions(slug);
    _optionsInFlight[slug] = future;
    // Clean the in-flight map whether the future completes or throws so
    // subsequent calls after an error still cache-miss cleanly (they'll
    // return the empty-sentinel entry we wrote inside [_fetch...]).
    future.whenComplete(() => _optionsInFlight.remove(slug));
    return future;
  }

  Future<List<PredefinedEnquiryGroup>> _fetchPredefinedEnquiryOptions(
      String slug) async {
    try {
      log('[ENQUIRY] predefined options → GET '
          'other-service/predefined-enquiry/$slug');
      final res = await OtherEnquiryRepo().getPredefinedEnquiryOptions(slug);
      log('[ENQUIRY] predefined options response: '
          'success=${res.isSuccess} statusCode=${res.statusCode}');
      if (!res.isSuccess) {
        // Cache empty so a 404 doesn't retrigger a request each time the
        // sheet is opened for this category in the same session.
        return _optionsCache[slug] = const [];
      }
      final data = res.response?.data;
      final inner = (data is Map ? data['data'] : null);
      final rawGroups = (inner is Map ? inner['groups'] : null);
      if (rawGroups is! List) return _optionsCache[slug] = const [];
      final groups = rawGroups
          .whereType<Map>()
          .map((m) =>
              PredefinedEnquiryGroup.fromJson(Map<String, dynamic>.from(m)))
          .where((g) => g.title.trim().isNotEmpty && g.options.isNotEmpty)
          .toList(growable: false);
      return _optionsCache[slug] = groups;
    } catch (e) {
      log('[ENQUIRY] predefined options threw: $e');
      return _optionsCache[slug] = const [];
    }
  }

  /// Synchronous accessor — returns null when no cached entry exists yet
  /// so callers can distinguish "never fetched" from "server said none"
  /// (empty list). The sheet uses this to decide whether to render the
  /// static-default fallback while the async fetch is still in-flight.
  List<PredefinedEnquiryGroup>? cachedPredefinedEnquiryOptions(
      String category) {
    final slug = category.trim().toUpperCase();
    if (slug.isEmpty) return null;
    return _optionsCache[slug];
  }

  @override
  void onClose() {
    _optionsCache.clear();
    _optionsInFlight.clear();
    super.onClose();
  }

  /// Raise an "other" business enquiry. [selections] is the grouped
  /// chip-checkbox map (each key = section title, e.g. "Services" /
  /// "Purpose" / "Policy Type"). Only non-empty arrays are sent —
  /// mirrors the server-side "at least one selection group or a note"
  /// gating (400 otherwise).
  ///
  /// Returns the newly-created enquiry id on success (or a synthetic
  /// timestamp id in stub mode), and null on failure. The sheet needs
  /// the id to fabricate the in-chat card metadata and to wire Accept/
  /// Decline on the owner side.
  ///
  /// Uploaded photo URLs are surfaced through [uploadedPhotoUrls] so the
  /// sheet can reuse them in the fabricated card without re-uploading.
  Future<String?> submitOtherEnquiry({
    required String businessId,
    required Map<String, List<String>> selections,
    required String note,
    List<String> photoPaths = const [],
    List<String>? uploadedPhotoUrls,
  }) async {
    try {
      isSubmitting.value = true;
      AppLoader.show();

      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 600));
        return 'stub_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Drop empty selection groups so the body matches the server contract.
      final cleanedSelections = <String, List<String>>{};
      selections.forEach((key, value) {
        final items = value.where((s) => s.trim().isNotEmpty).toList();
        if (items.isNotEmpty) cleanedSelections[key] = items;
      });

      final trimmedNote = note.trim();
      final repo = OtherEnquiryRepo();

      // JSON only — photos must be pre-uploaded to S3.
      log('[ENQUIRY] other submit → photoPaths.length=${photoPaths.length}'
          '${photoPaths.isNotEmpty ? " paths=$photoPaths" : ""}');
      final photoUrls = photoPaths.isEmpty ? const <String>[] : await repo.uploadPhotosViaPresign(photoPaths);
      log('[ENQUIRY] other submit → photoUrls.length=${photoUrls.length}'
          '${photoUrls.isNotEmpty ? " urls=$photoUrls" : ""}');
      uploadedPhotoUrls?.addAll(photoUrls);

      final body = <String, dynamic>{
        ApiKeys.business_id: businessId,
        if (cleanedSelections.isNotEmpty) 'selections': cleanedSelections,
        if (trimmedNote.isNotEmpty) ApiKeys.note: trimmedNote,
        if (photoUrls.isNotEmpty) ApiKeys.photos: photoUrls,
      };
      // Log the exact JSON body Dio will send — mirrors the wire shape
      // documented in `lib/docs/other-enquiry-ui-integration.md` §2.
      log('[ENQUIRY] other submit → POST other-service/other-enquiries '
          'photos=${photoUrls.length} body=${jsonEncode(body)}');
      final res = await repo.sendOtherEnquiry(params: body);
      log('[ENQUIRY] other response: '
          'success=${res.isSuccess} statusCode=${res.statusCode} '
          'message=${res.message} data=${res.response?.data}');
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return null;
      }
      return _extractEnquiryId(res.response?.data);
    } catch (e, st) {
      log('[ENQUIRY] other submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Reads `data.enquiryId` (or `_id` / `id`) from the standard
  /// `{ success, data: {…} }` envelope. Returns an empty string when
  /// success came back without an id — the sheet falls back to a
  /// null-id card in that case, so submit still lands.
  String _extractEnquiryId(dynamic data) {
    final inner = (data is Map ? data['data'] : null);
    if (inner is Map) {
      final id = (inner['enquiryId'] ?? inner['_id'] ?? inner['id'])?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return '';
  }

  /// Owner accepts / declines from the in-chat card. [status] is
  /// 'accepted' or 'declined'. Returns true on success; 409 (decision
  /// already made — socket already flipped the card) is treated as
  /// success for idempotency.
  Future<bool> updateOtherEnquiryStatus({
    required String enquiryId,
    required String status,
  }) async {
    if (_useStub) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    log('[ENQUIRY] other updateStatus → PUT enquiryId=$enquiryId '
        'status=$status');
    try {
      final res = await OtherEnquiryRepo().updateOtherEnquiryStatus(
        enquiryId: enquiryId,
        params: {ApiKeys.status: status},
      );
      log('[ENQUIRY] other updateStatus response: '
          'success=${res.isSuccess} statusCode=${res.statusCode} '
          'message=${res.message}');
      if (res.statusCode == 409) return true;
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      log('[ENQUIRY] other updateStatus threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Fetch the current server-side status of an "other" enquiry.
  Future<String?> fetchOtherEnquiryStatus({
    required String enquiryId,
  }) async {
    if (enquiryId.trim().isEmpty) return null;
    try {
      final res = await OtherEnquiryRepo().getOtherEnquiryById(enquiryId);
      if (!res.isSuccess) return null;
      final data = res.response?.data;
      final inner = (data is Map ? (data['data'] ?? data) : null);
      if (inner is Map) {
        final status = inner['status']?.toString();
        if (status != null && status.isNotEmpty) return status.toLowerCase();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
