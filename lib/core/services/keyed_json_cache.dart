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
      return _decode(box.get(key));
    } catch (_) {
      return null;
    }
  }

  /// The cached map for [key] read **without an await** — null when the box is
  /// not open yet, on a miss, or on a parse error.
  ///
  /// Hive's `box.get` is synchronous once the box is open; only *opening* it is
  /// async. So a screen whose box was opened at boot (see [ensureOpen]) can
  /// hydrate inside `initState` and paint its very first frame with content,
  /// instead of showing a spinner for the one or two frames it takes an
  /// `await`ed [get] to come back. That gap is exactly what makes a
  /// cache-first screen still look like it's loading.
  ///
  /// [get] stays the general path — use this only where a frame matters.
  Map<String, dynamic>? getSync(String key) {
    if (key.isEmpty || !Hive.isBoxOpen(boxName)) return null;
    try {
      return _decode(Hive.box(boxName).get(key));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decode(dynamic raw) {
    if (raw is! String) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  /// Opens the box up front so later [getSync] calls can serve. Call at boot
  /// for the caches whose screens must paint on their first frame; never
  /// required for [get], which opens lazily.
  Future<void> ensureOpen() async {
    try {
      await _safeBox();
    } catch (_) {}
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

/// Caches the Social section's "My Post" grid (first page) keyed by user id, so
/// the tab paints the viewer's own posts instantly on open and refreshes behind
/// them. Stored as `{'cachedAt': <ms>, 'posts': [<post json>, ...]}`.
///
/// Its own box rather than a slot in [socialFeedCache]: the two are written on
/// completely different triggers (the home feed on every first-page fetch, this
/// one only when the viewer's own posts reload) and invalidated separately —
/// publishing a post must drop this without touching the home feed's copy.
const KeyedJsonCache myPostsCache = KeyedJsonCache('my_posts_cache_box');

/// The Social-section caches that must be readable **synchronously** on the
/// first frame of their tab (see [KeyedJsonCache.getSync]). Opened once at boot
/// so Feed / Bites / My Post never paint a spinner over content they already
/// have on disk.
Future<void> openSocialCaches() async {
  await Future.wait([
    socialFeedCache.ensureOpen(),
    myPostsCache.ensureOpen(),
    symbolFeedCache.ensureOpen(),
  ]);
}

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
