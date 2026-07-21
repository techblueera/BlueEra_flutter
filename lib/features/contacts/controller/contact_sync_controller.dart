import 'dart:convert';
import 'dart:typed_data';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/contacts/model/blue_era_contact.dart';
import 'package:BlueEra/features/contacts/repo/contact_repo.dart';
import 'package:convert/convert.dart';
import 'package:get/get.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Owns the `contact-service` integration: uploading the phonebook and
/// rendering "Contacts on BlueEra".
///
/// Deliberately SEPARATE from `ChatViewController.uploadContacts` /
/// `refreshContacts`, which keep talking to `chat-service/connections/sync`
/// for the Connect tab. Both run off the SAME phonebook read (see
/// `ConnectMainPage._syncContactsIfNeeded`) — a failure here must never
/// affect the Connect tab.
class ContactSyncController extends GetxController {
  final ContactRepo _repo = ContactRepo();

  /// Server cap per sync request.
  static const int _maxContactsPerRequest = 2000;

  /// Re-upload cadence when the phonebook fingerprint is unchanged.
  static const Duration _resyncInterval = Duration(hours: 24);

  static const int _pageSize = 50;

  Rx<ApiResponse> blueEraContactsResponse = ApiResponse.initial('Initial').obs;
  RxList<BlueEraContact> blueEraContacts = <BlueEraContact>[].obs;

  /// Contacts of mine that are on BlueEra, as reported by the last sync /
  /// sync-state call.
  RxInt matchedCount = 0.obs;

  /// True while a phonebook upload is in flight — guards against the Connect
  /// tab re-entering while the previous sync is still running.
  RxBool isSyncing = false.obs;

  // Pagination state for the "Contacts on BlueEra" screen.
  RxInt currentPage = 1.obs;
  RxBool hasNextPage = false.obs;
  RxBool isLoadingMore = false.obs;
  String _activeSearch = '';

  // ---------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------

  /// Upload [contacts] to the contact service.
  ///
  /// Skips the network entirely when the phonebook fingerprint matches the
  /// last successful upload and that upload is younger than 24h (unless
  /// [force]). Batches above the server's 2000-per-request cap, marking only
  /// the LAST batch `full_sync` — otherwise each batch would prune the one
  /// before it.
  ///
  /// Never throws and never shows a snackbar: this runs in the background
  /// behind the Connect tab.
  Future<void> syncPhonebook(
    List<Map<String, dynamic>> contacts, {
    bool force = false,
    String countryCode = '91',
  }) async {
    if (contacts.isEmpty || isSyncing.value) return;

    final digest = computeDigest(contacts);
    if (!force && !await _isSyncDue(digest)) {
      logs('contact sync: phonebook unchanged and synced < 24h ago — skipped');
      return;
    }

    isSyncing.value = true;
    try {
      bool allOk = true;
      for (var i = 0; i < contacts.length; i += _maxContactsPerRequest) {
        final batch = contacts.skip(i).take(_maxContactsPerRequest).toList();
        final isLast = i + _maxContactsPerRequest >= contacts.length;
        final ok = await _syncBatchWithRetry(
          batch,
          // full_sync prunes anything not in the payload — only the last
          // batch may do that.
          fullSync: isLast,
          digest: isLast ? digest : null,
          countryCode: countryCode,
        );
        if (!ok) {
          allOk = false;
          break;
        }
      }
      if (allOk) {
        await _rememberSync(digest);
      }
    } finally {
      isSyncing.value = false;
    }
  }

  /// One batch, with backoff on transient failures. Returns true on success.
  ///
  /// `ApiBaseHelper` throws a raw `String` for non-`badResponse` Dio errors
  /// (timeout, no internet), so every attempt is wrapped. 400 (bad payload)
  /// and 429 (rate limited: 20 syncs / 15 min) are permanent — never retried.
  Future<bool> _syncBatchWithRetry(
    List<Map<String, dynamic>> batch, {
    required bool fullSync,
    String? digest,
    required String countryCode,
  }) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final ResponseModel res = await _repo.syncContacts({
          'contacts': batch,
          'full_sync': fullSync,
          'country_code': countryCode,
          if (digest != null) 'digest': digest,
        });

        if (res.isSuccess) {
          final data = res.data;
          if (data is Map) {
            matchedCount.value =
                (data['matched_count'] as num?)?.toInt() ?? matchedCount.value;
          }
          return true;
        }

        final status = res.statusCode ?? res.response?.statusCode ?? 0;
        if (status == 400 || status == 429) {
          // Permanent — retrying the same payload can only make it worse.
          logs('contact sync failed permanently ($status): ${res.message}');
          return false;
        }
        logs('contact sync failed ($status), attempt $attempt: ${res.message}');
      } catch (e) {
        // Network-level failure — fall through to the backoff below.
        logs('contact sync threw on attempt $attempt: $e');
      }
      if (attempt < 3) {
        await Future.delayed(Duration(seconds: 2 << attempt)); // 4s, 8s
      }
    }
    return false;
  }

  /// Stable fingerprint of the phonebook. Only used to decide whether an
  /// upload can be skipped, so the exact algorithm doesn't matter as long as
  /// it's deterministic across launches.
  String computeDigest(List<Map<String, dynamic>> contacts) {
    final entries = contacts
        .map((c) =>
            '${c['contact_no'] ?? c['phone'] ?? c['number'] ?? ''}:${c['name'] ?? ''}')
        .toList()
      ..sort();
    final bytes = Uint8List.fromList(utf8.encode(entries.join('|')));
    return hex.encode(SHA256Digest().process(bytes)).substring(0, 16);
  }

  /// True when the phonebook changed, or the last successful sync is older
  /// than [_resyncInterval], or we've never synced.
  Future<bool> _isSyncDue(String digest) async {
    try {
      final storedDigest = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.contactServiceDigestKey);
      if (storedDigest != digest) return true;
      return isTimeBasedSyncDue();
    } catch (_) {
      // Storage hiccup — err on the side of syncing.
      return true;
    }
  }

  /// Cheap, phonebook-free version of [_isSyncDue]: true when we've never
  /// synced or the last successful sync is older than 24h.
  ///
  /// Call this BEFORE reading the device phonebook so a Connect-tab entry
  /// inside the 24h window costs nothing (reading thousands of contacts is
  /// not free).
  Future<bool> isTimeBasedSyncDue() async {
    try {
      final rawLastSync = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.contactServiceLastSyncKey);
      final lastSyncMs = int.tryParse('${rawLastSync ?? ''}');
      if (lastSyncMs == null) return true;

      final last = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      return DateTime.now().difference(last) >= _resyncInterval;
    } catch (_) {
      return true;
    }
  }

  Future<void> _rememberSync(String digest) async {
    try {
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.contactServiceDigestKey, digest);
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.contactServiceLastSyncKey,
          '${DateTime.now().millisecondsSinceEpoch}');
    } catch (_) {}
  }

  /// Clear the local sync bookkeeping so the next call to [syncPhonebook]
  /// always uploads (used after a consent withdrawal).
  Future<void> _forgetSync() async {
    try {
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.contactServiceDigestKey, '');
      await SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.contactServiceLastSyncKey, '');
    } catch (_) {}
  }

  /// Server-side view of the sync state. Returns null on any failure.
  Future<ContactSyncState?> fetchSyncState() async {
    try {
      final res = await _repo.getSyncState();
      if (!res.isSuccess) return null;
      final data = res.data;
      if (data is! Map) return null;
      final state = ContactSyncState.fromJson(Map<String, dynamic>.from(data));
      matchedCount.value = state.matchedCount;
      return state;
    } catch (e) {
      logs('contact sync-state threw: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Contacts on BlueEra
  // ---------------------------------------------------------------------

  Future<void> loadBlueEraContacts({int page = 1, String? search}) async {
    if (page == 1) {
      blueEraContactsResponse.value = ApiResponse.initial('Initial');
      _activeSearch = search ?? '';
    }
    try {
      final res = await _repo.getContactsOnBlueEra({
        'page': page,
        'limit': _pageSize,
        if (_activeSearch.isNotEmpty) 'search': _activeSearch,
      });

      if (res.isSuccess) {
        final list = (res.data as List? ?? [])
            .map((e) => BlueEraContact.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (page == 1) {
          blueEraContacts.value = list;
        } else {
          blueEraContacts.addAll(list);
        }
        currentPage.value = page;

        final pagination = res.getExtraData('pagination');
        hasNextPage.value =
            pagination is Map ? pagination['hasNextPage'] == true : false;

        blueEraContactsResponse.value = ApiResponse.complete(blueEraContacts);
      } else {
        blueEraContactsResponse.value =
            ApiResponse.error(res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs('load blueera contacts threw: $e');
      blueEraContactsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  /// Append the next page. No-op while one is already in flight or when the
  /// server says there's nothing more.
  Future<void> loadMoreBlueEraContacts() async {
    if (isLoadingMore.value || !hasNextPage.value) return;
    isLoadingMore.value = true;
    try {
      await loadBlueEraContacts(page: currentPage.value + 1);
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Pull-to-refresh: re-check matches server-side (no upload), then reload
  /// the first page. `rebuild` is capped at 10/hour, so a failure here is
  /// expected and silently ignored — the reload still happens.
  Future<void> refreshBlueEraContacts() async {
    try {
      await _repo.rebuildMatches();
    } catch (e) {
      logs('contact rebuild threw: $e');
    }
    await loadBlueEraContacts(page: 1, search: _activeSearch);
  }

  /// Whether this device has ever completed a contact-service sync (local
  /// bookkeeping only). Used to make the consent-withdrawal delete a one-shot
  /// instead of firing on every Connect-tab entry after a permanent denial.
  Future<bool> hasSyncedLocally() async {
    try {
      final digest = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.contactServiceDigestKey);
      return digest != null && '$digest'.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Withdraw consent server-side — called when contacts permission is
  /// revoked / permanently denied. Soft-delete, so re-granting restores the
  /// match history.
  Future<void> deleteAllContacts() async {
    try {
      await _repo.deleteAllContacts();
    } catch (e) {
      logs('contact delete threw: $e');
    }
    blueEraContacts.clear();
    matchedCount.value = 0;
    await _forgetSync();
  }
}
