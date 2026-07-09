import 'dart:convert';

import 'package:hive/hive.dart';

/// A tiny reusable Hive-backed cache for small JSON blobs keyed by a string
/// (typically the logged-in user's id).
///
/// Used to make "fetch once after login, then serve from cache" flows trivial:
/// a controller reads [get] first and only hits the network on a miss, writing
/// back via [save]. The box opens lazily and reopens itself if it was closed
/// (e.g. after logout via `Hive.deleteFromDisk()`), so callers never touch a
/// closed box and the cache auto-resets on logout — the next login refetches.
/// Call [clear] to invalidate after a mutation that changes the cached data.
class KeyedJsonCache {
  final String boxName;

  const KeyedJsonCache(this.boxName);

  Future<Box> _safeBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return await Hive.openBox(boxName);
  }

  /// Caches [data] under [key]. No-op on empty key or any storage error.
  Future<void> save(String key, Map<String, dynamic> data) async {
    if (key.isEmpty) return;
    try {
      final box = await _safeBox();
      await box.put(key, jsonEncode(data));
    } catch (_) {}
  }

  /// Returns the cached map for [key], or null on miss / parse error.
  Future<Map<String, dynamic>?> get(String key) async {
    if (key.isEmpty) return null;
    try {
      final box = await _safeBox();
      final raw = box.get(key);
      if (raw is! String) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clears all entries in this cache box (used to invalidate after a mutation
  /// or on logout).
  Future<void> clear() async {
    try {
      final box = await _safeBox();
      await box.clear();
    } catch (_) {}
  }
}

/// Caches the logged-in rider's onboarding status response (keyed by user id).
/// Served from cache on screen opens; refreshed only when the status changes
/// (document mutations / pull-to-refresh).
const KeyedJsonCache riderOnboardingStatusCache =
    KeyedJsonCache('rider_onboarding_status_box');

/// Caches the logged-in user's followers / following / posts counts (keyed by
/// user id). Served from cache; invalidated on follow/unfollow and post
/// creation, and refreshed on pull-to-refresh.
const KeyedJsonCache userCountsCache = KeyedJsonCache('user_counts_box');

/// Caches the rider's booking-orders list (keyed by user id) so the rider
/// dashboard renders the last-known orders instantly on open, then refreshes
/// in the background (stale-while-revalidate). Stored as `{'orders': [...]}`.
const KeyedJsonCache riderOrdersCache = KeyedJsonCache('rider_orders_box');

/// Caches the Social-tab home feed (first page, capped to 10 posts) keyed by
/// user id, so the Social tab paints the last-known feed instantly on open
/// instead of stalling on a spinner while the live feed loads. Overwritten on
/// every successful first-page fetch (stale-while-revalidate); auto-reset on
/// logout. Stored as `{'feed': [<post json>, ...]}`.
const KeyedJsonCache socialFeedCache = KeyedJsonCache('social_feed_cache_box');

/// Caches the security-deposit explainer videos (global — same for every user)
/// under a constant key, so the contribution screen serves them from Hive and
/// skips the videos API after the first successful fetch. Stores the raw master
/// list as `{'videos': [<video json>, ...]}`. Auto-reset on logout
/// (`Hive.deleteFromDisk()`), so a re-login refetches once.
const KeyedJsonCache securityDepositVideosCache =
    KeyedJsonCache('security_deposit_videos_box');

/// Caches the Social-tab symbol story row (raw grouped-data JSON; the row
/// renders the first 5 user groups) keyed by user id, served instantly on open
/// while the live symbol feed refreshes. Stored as `{'data': {...}}`.
const KeyedJsonCache symbolFeedCache = KeyedJsonCache('symbol_feed_cache_box');

/// Caches the recharge-plans catalog (`GET /recharge/plans?entity_type=…`)
/// keyed by `${userId}_${entityType}`. The catalog rarely changes, so it's
/// fetched once after login and then refreshed at most once every 24h — see
/// [ContributionController.fetchPlans]. Stored as
/// `{'ts': <epochMillis>, 'mode': <str>, 'data': [<plan json>, …]}`, where `ts`
/// drives the 24h freshness window.
const KeyedJsonCache rechargePlansCache =
    KeyedJsonCache('recharge_plans_box');
