import 'dart:convert';
import 'dart:math';

import 'package:BlueEra/core/services/keyed_json_cache.dart';
import 'package:BlueEra/features/common/promo/model/promo_ad_models.dart';
import 'package:BlueEra/features/common/promo/repo/promo_ads_repo.dart';
import 'package:flutter/foundation.dart';

/// The promo creatives, served from `other-service/ads` instead of the app
/// bundle.
///
/// ## Why this exists
///
/// The Qureka promo artwork used to be eight JPG/PNGs in `assets/qureka/`, so
/// swapping a campaign, pausing one or adding a size meant an app release. The
/// same artwork now comes from the backend, keyed by PLACEMENT — a placement is
/// a pixel size, and every creative under it is drawn at exactly that size, so
/// a slot never has to guess an aspect ratio or crop. See
/// docs/backend/ADS_API_FLUTTER_GUIDE.md.
///
/// ## How it loads — Hive first, network only on a miss
///
/// 1. [hydrateFromCache] reads the last bundle out of Hive **synchronously** at
///    boot (the box is opened in `main`), so the first Discover / feed frame
///    already has artwork. No spinner, no pop-in.
/// 2. [ensureLoaded] hits the API **only when nothing is cached**. A stored
///    bundle is a snapshot that REPLACES the request: once the artwork is on
///    disk the app serves it and makes no call at all, on this launch or any
///    later one. The payload is a weekly-ish creative set, not live data —
///    re-fetching it per app open would spend a round-trip for a byte-identical
///    answer.
/// 3. [refresh] is the deliberate way to go and get a new bundle (a settings
///    action, a push telling the app the campaign changed, a QA build). It is
///    the ONLY path that talks to the network with a cache present.
/// 4. Whenever a bundle lands with a new `version`, [revision] ticks and every
///    mounted banner rebuilds itself onto the new artwork.
///
/// The cache is dropped on logout with the rest of Hive (`deleteFromDisk`), so
/// a re-login refetches once. Beyond that, a campaign swap reaches an installed
/// app on the next [refresh] or the next reinstall — the trade for making the
/// steady state zero requests.
///
/// Nothing here ever throws or blocks: ads are decorative. A failed fetch keeps
/// whatever was already loaded, and an empty bundle simply means the promo
/// slots collapse (`SizedBox.shrink()`), never a grey box.
class PromoAdsService {
  PromoAdsService._();

  /// Single Hive entry — the bundle is global, identical for every user.
  static const String _cacheKey = 'bundle';

  static Map<String, AdPlacement> _placements = const {};
  static List<AdNotificationCopy> _notifications = const [];
  static String _version = '';
  static Future<void>? _pending;

  /// Ticks whenever the bundle changes. Banners listen to this instead of
  /// holding controllers, so a `const` promo widget still repaints when the
  /// artwork arrives after its first build.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// The bundle version currently in memory (the API's cache key).
  static String get version => _version;

  /// Bilingual push copy that ships with the bundle. Copy only — the API sends
  /// no pushes; hand these to whatever scheduler is doing the sending.
  static List<AdNotificationCopy> get notifications => _notifications;

  /// True once any bundle (cached or fresh) is in memory with at least one
  /// creative.
  static bool get hasAds => _placements.values.any((p) => !p.isEmpty);

  /// The slot for [key], or null when the bundle has no such placement — which
  /// is not an error: the caller collapses.
  static AdPlacement? of(String key) {
    final p = _placements[key];
    if (p == null || p.isEmpty) return null;
    return p;
  }

  /// One creative for a slot.
  ///
  /// [index] makes the choice STABLE and distinct: a list with several promo
  /// rows passes each row's ordinal, so the rows differ from each other and
  /// stay put across rebuilds instead of reshuffling on every repaint. Omit it
  /// for a random pick (used once per mount, not per build).
  static AdCreative? pick(String key, {int? index}) {
    final p = of(key);
    if (p == null) return null;
    final i = index ?? _rng.nextInt(p.creatives.length);
    return p.creatives[i.abs() % p.creatives.length];
  }

  static final Random _rng = Random();

  /// Reads the last cached bundle without an await. Safe to call before the
  /// box is open — it just returns false, and [ensureLoaded] fills in.
  static bool hydrateFromCache() {
    final cached = promoAdsCache.getSync(_cacheKey);
    if (cached == null) return false;
    return _adopt(cached, notify: true);
  }

  /// Serves the bundle: Hive if it's there, one API call if it isn't.
  ///
  /// **Makes no request when a bundle is already cached** — that is the whole
  /// point of storing it. Safe to call from anywhere and as often as you like;
  /// with a cache present it returns without touching the network, and
  /// concurrent callers share the one in-flight fetch.
  ///
  /// Never awaited by UI. Call it at boot — it needs no token, so it can run
  /// before login.
  static Future<void> ensureLoaded({bool forceRefresh = false}) {
    // Already in memory → nothing to do at all, not even a Hive read.
    if (_placements.isNotEmpty && !forceRefresh) return Future<void>.value();
    return _pending ??= _load(forceRefresh: forceRefresh).whenComplete(() {
      // Cleared so a later refresh — or a retry after a failed first fetch —
      // can run. With a bundle stored, the guard above is what makes every
      // subsequent call free.
      _pending = null;
    });
  }

  /// Deliberately go and fetch a new bundle, cache or no cache, and store it.
  ///
  /// The only path that spends a request when the artwork is already on disk.
  /// Wire it to an explicit trigger (a campaign-changed push, a debug action) —
  /// never to a screen build.
  static Future<void> refresh() => ensureLoaded(forceRefresh: true);

  static Future<void> _load({bool forceRefresh = false}) async {
    try {
      // Cache first — including the async read, for callers that run before the
      // box was opened at boot (or before hydrateFromCache ran).
      if (_placements.isEmpty) {
        final cached = await promoAdsCache.get(_cacheKey);
        if (cached != null) _adopt(cached, notify: true);
      }
      // Stored bundle → done. No API call, this launch or any later one.
      if (!forceRefresh && _placements.isNotEmpty) return;

      final res = await PromoAdsRepo().getAds();
      if (!res.isSuccess) return; // keep whatever we had

      final body = res.response?.data;
      final map = body is String
          ? jsonDecode(body) as Map<String, dynamic>
          : Map<String, dynamic>.from(body as Map);
      if (map['placements'] is! Map) return;

      final stamped = <String, dynamic>{
        ...map,
        'fetchedAt': DateTime.now().millisecondsSinceEpoch,
      };
      // Adopt before writing: the screen gets the new artwork on this frame,
      // the disk write is bookkeeping for the next launch.
      _adopt(stamped, notify: true);
      await promoAdsCache.save(_cacheKey, stamped);
    } catch (_) {
      // Decorative. Never let this surface anywhere.
    }
  }

  /// When the stored bundle was fetched. Kept for diagnostics only — nothing
  /// expires on it; a cached bundle is served until [refresh] or a logout.
  static DateTime? _fetchedAt;

  /// Exposed so a debug screen can show how old the stored artwork is.
  static DateTime? get fetchedAt => _fetchedAt;

  /// Parses a bundle (from the API or from Hive) into memory. Returns false and
  /// leaves the previous bundle untouched when it carries nothing usable, so a
  /// bad payload can't blank artwork that is already showing.
  static bool _adopt(Map<String, dynamic> body, {bool notify = false}) {
    try {
      final raw = body['placements'];
      if (raw is! Map) return false;

      final parsed = <String, AdPlacement>{};
      raw.forEach((k, v) {
        if (v is Map) {
          final placement = AdPlacement.fromJson(Map<String, dynamic>.from(v));
          if (!placement.isEmpty) parsed['$k'] = placement;
        }
      });
      if (parsed.isEmpty) return false;

      final incomingVersion = (body['version'] ?? '').toString();
      final unchanged = incomingVersion.isNotEmpty &&
          incomingVersion == _version &&
          _placements.isNotEmpty;

      _placements = parsed;
      _version = incomingVersion;
      _notifications = ((body['notifications'] as List?) ?? const [])
          .whereType<Map>()
          .map((n) => AdNotificationCopy.fromJson(Map<String, dynamic>.from(n)))
          .toList();
      final stamp = body['fetchedAt'];
      _fetchedAt = stamp is int
          ? DateTime.fromMillisecondsSinceEpoch(stamp)
          : DateTime.now();

      // Only repaint when the artwork actually changed — a same-version refresh
      // must not reshuffle banners under the user.
      if (notify && !unchanged) revision.value++;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Test/debug seam: drops everything in memory.
  @visibleForTesting
  static void reset() {
    _placements = const {};
    _notifications = const [];
    _version = '';
    _fetchedAt = null;
    _pending = null;
  }
}
