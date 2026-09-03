import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';

/// Local (Hive) snapshot of the "other service" FULL business profile.
///
/// ## Why this exists
///
/// `BusinessProfileFullController` is an in-memory GetX singleton, so its
/// `businessProfile` starts null on every cold start. The Overview tab's guard
/// — "fetch when the profile is null" — therefore fired
/// `GET other-service/business-profile/<id>/full` once per app launch, re-asking
/// for a profile that had not changed since the last run. Nothing was wrong with
/// the guard; there was simply nothing on disk for it to find.
///
/// This is the same shape every other vertical already uses (grocery, food,
/// product, medical, automotive, manufacturer): the raw JSON goes to Hive, and
/// the caller rebuilds its models with the same `fromJson` it uses for a live
/// response, so there is only ever one parser to keep correct.
///
/// ## Freshness
///
/// Cache-first, and a hit REPLACES the request rather than racing it. The
/// profile only changes when this device changes it — adding a photo, editing
/// management, saving timings — and every one of those paths already refetches
/// with `forceRefresh: true` and rewrites this snapshot. A profile edited on
/// another device is picked up on the next write here, on a logout/login, or on
/// a pull-to-refresh.
///
/// ## Why a JSON string and not a raw map
///
/// Hive hands back `Map<dynamic, dynamic>` for anything written as a bare map,
/// and `BusinessProfileFullModel.fromJson` wants `Map<String, dynamic>` —
/// reading such a cache would throw at the first cast. Values are therefore
/// `jsonEncode`d on the way in and decoded on the way out.
class OtherProfileLocalStore {
  OtherProfileLocalStore._();

  static const String boxName = 'other_profile_cache_box';

  /// Keyed by profile id so a stale snapshot can never render under a
  /// different profile. Logout wipes the box outright as well — see
  /// [clearAll] — this is the second line of defence, not the first.
  static String _key(String profileId) => 'full|$profileId';

  static Future<Box?> _safeBox() async {
    try {
      return Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
    } catch (e) {
      log('OtherProfileLocalStore: box unavailable — $e');
      return null;
    }
  }

  /// The cached response envelope for [profileId], or null when there is none.
  ///
  /// Returns exactly what the API returned, so the caller can hand it to the
  /// same `fromJson` it uses for a live response.
  static Future<Map<String, dynamic>?> read(String profileId) async {
    if (profileId.isEmpty) return null;
    final box = await _safeBox();
    if (box == null) return null;
    try {
      final raw = box.get(_key(profileId));
      if (raw is! String || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final payload = decoded['data'];
      if (payload is! Map) return null;
      return Map<String, dynamic>.from(payload);
    } catch (e) {
      log('OtherProfileLocalStore.read($profileId) error: $e');
      return null;
    }
  }

  /// Stores [envelope] — the whole `{success, data}` body — under [profileId].
  ///
  /// An empty or null body is stored as a DELETION rather than an empty entry:
  /// "the server had nothing" is better re-asked than cached, and it stops a
  /// failed parse from pinning an empty Overview tab forever.
  static Future<void> write(String profileId, dynamic envelope) async {
    if (profileId.isEmpty) return;
    final box = await _safeBox();
    if (box == null) return;
    try {
      if (envelope is! Map || envelope.isEmpty) {
        await box.delete(_key(profileId));
        return;
      }
      await box.put(
        _key(profileId),
        jsonEncode({
          'data': envelope,
          'savedAt': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      log('OtherProfileLocalStore.write($profileId) error: $e');
    }
  }

  /// Drops every snapshot. Called from the logout local-data wipe, for the
  /// same reason the other verticals' stores are: this box holds one account's
  /// profile and must not survive into the next.
  static Future<void> clearAll() async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      } else {
        await Hive.deleteBoxFromDisk(boxName);
      }
    } catch (e) {
      log('OtherProfileLocalStore.clearAll error: $e');
    }
  }
}
