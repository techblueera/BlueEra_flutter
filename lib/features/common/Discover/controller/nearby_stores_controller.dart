import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_discover_models.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_sections_models.dart';
import 'package:BlueEra/features/common/Discover/repo/nearby_discover_repo.dart';
import 'package:get/get.dart';

/// Backs the "Near You" rail on Discover. Fetches
/// `map-service/api/nearby/discover` for the user's location and exposes the
/// mixed nearby set — stores (grocery/food/product) + service providers +
/// riders — plus loading/degraded state.
///
/// Freshness is three-tiered like [StoreController.getAllStoreNearByIfNeeded]:
///  1. in-session memory ([FetchCache]);
///  2. persistent Hive cache with a **24-hour TTL** + a move-distance guard —
///     the cached set is shown instantly and revalidated silently when stale;
///  3. network.
class NearbyStoresController extends GetxController {
  final NearbyDiscoverRepo _repo = NearbyDiscoverRepo();

  final RxList<NearbyStoreCard> stores = <NearbyStoreCard>[].obs;

  /// Nearby self-employed / professional service providers (guide's `services`).
  final RxList<NearbyWorkerCard> services = <NearbyWorkerCard>[].obs;

  /// Nearby gig-worker riders (guide's `riders`).
  final RxList<NearbyWorkerCard> riders = <NearbyWorkerCard>[].obs;

  final RxBool isLoading = false.obs;

  /// True once at least one fetch attempt has settled.
  final RxBool loaded = false.obs;

  /// True when a slice this rail draws from failed upstream (an outage) rather
  /// than genuinely having nothing nearby — see the guide's §4 `meta.degraded`.
  /// An empty rail + this flag must show a retry, never an empty state: the
  /// user can't recover from "nothing nearby" when the truth is "we failed".
  final RxBool degraded = false.obs;

  /// The radius the backend searched, in km (`meta.radius`). 0 until the first
  /// response lands.
  final RxDouble radiusKm = 0.0.obs;

  // ── The SECTIONED payload (Discover v2) ───────────────────────────────────
  //
  // `nearby-discover` now answers three ready-made sections — `shops_near_me`,
  // `services_near_me`, `recent_visited` — instead of the raw store buckets the
  // three lists above are built from. Both shapes are parsed from the SAME
  // response on every fetch, and each yields empty against the other's payload,
  // so the v1 rail and the v2 sections coexist without either having to know
  // which shape the server sent.
  //
  // The two rails here are CATEGORIES, not businesses: one tile per kind of
  // shop nearby, with how many there are and how far the closest is.

  /// "Shops Near Me" — aggregated store categories.
  final RxList<NearbySectionCategory> shopCategories =
      <NearbySectionCategory>[].obs;

  /// "Services Near Me" — aggregated service categories.
  final RxList<NearbySectionCategory> serviceCategories =
      <NearbySectionCategory>[].obs;

  /// "Recent Visited Stores" — actual businesses, server-ranked.
  final RxList<NearbyVisitedStore> recentVisited = <NearbyVisitedStore>[].obs;

  /// The BUSINESSES in the shops rail, flattened out of their categories.
  ///
  /// The rails draw one tile per shop — its own photo, its real name, its
  /// category underneath — not one per category. The category grouping is how
  /// the server ships them and how they are ORDERED (category `rank`, then the
  /// server's order within each), which is why the flatten preserves that
  /// sequence instead of re-sorting by distance.
  ///
  /// Computed rather than stored: it reads [shopCategories], so calling it
  /// inside an `Obx` registers the dependency exactly as reading the list
  /// directly would.
  List<NearbySectionItem> get shopBusinesses =>
      flattenNearbyBusinesses(shopCategories);

  /// The businesses in the services rail. Same shape and same rules.
  List<NearbySectionItem> get serviceBusinesses =>
      flattenNearbyBusinesses(serviceCategories);

  /// Section headings as the server words them, so a backend rename reaches
  /// the UI without a release.
  final RxString shopsTitle = 'Shops Near Me'.obs;
  final RxString servicesTitle = 'Services Near Me'.obs;
  final RxString recentTitle = 'Recent Visited Stores'.obs;

  final FetchCache _cache = FetchCache(ttl: const Duration(hours: 24));

  /// A persisted set older than this triggers a silent background refresh on
  /// re-entry (the cached set is still shown instantly meanwhile). A day is
  /// fine for the passive path — users can force fresh data any time with
  /// pull-to-refresh on Discover.
  static const Duration _persistTtl = Duration(hours: 24);

  /// Moving farther than this (metres) from where the set was fetched marks the
  /// cache stale — the user is effectively browsing a new area.
  static const double _moveInvalidationMeters = 1500;

  /// Dataset identity (per user). Location isn't baked in — it's tracked as a
  /// distance delta so a small walk doesn't refetch but a relocation does. Also
  /// the Hive key. Reuses the near-by store box with a distinct key namespace.
  /// Cache SCHEMA version. **Bump this whenever the shape the UI reads out of
  /// the cached response changes.**
  ///
  /// The Hive entry stores the RAW response, so an app update that changes how
  /// that response is read silently inherits the previous build's blob. Two
  /// real cases this exists for:
  ///
  ///  * a v1-shape blob (`grocery` / `food` / `services` buckets) satisfied the
  ///    hydrate gate, marked the cache fresh, and left the v2 rails EMPTY for
  ///    up to the full 24h TTL — no refetch, because nothing was stale;
  ///  * a sectioned blob from before `categories[].items` existed parsed into
  ///    perfectly good-looking categories carrying no businesses, so the rails
  ///    were empty while the cache looked healthy. Worse than the first case,
  ///    because there was data to point at.
  ///
  /// Bumping the version changes the KEY, so every pre-existing entry becomes
  /// unreachable: each user pays exactly ONE fetch on the update, then caching
  /// resumes normally. That is far cheaper than forcing a network call on
  /// every open of the tab, and unlike sniffing the blob's shape it cannot be
  /// fooled by a payload that is merely shaped right.
  static const int _cacheSchema = 2;

  String get _identity => 'nearby-discover|v$_cacheSchema|$userId';

  /// Where the data currently in memory was fetched, for the move check.
  double? _lastFetchLat;
  double? _lastFetchLng;

  /// Anything worth painting, in EITHER shape. The sectioned lists count: on
  /// the new payload the three v1 lists are always empty, so leaving them out
  /// would make the freshness guard read a good response as "no data" and
  /// re-request on every screen entry.
  bool get _hasData =>
      stores.isNotEmpty ||
      services.isNotEmpty ||
      riders.isNotEmpty ||
      shopCategories.isNotEmpty ||
      serviceCategories.isNotEmpty ||
      recentVisited.isNotEmpty;

  bool _movedFarFromLastFetch() {
    final lat = _lastFetchLat;
    final lng = _lastFetchLng;
    if (lat == null || lng == null) return false;
    return LocationService.metersFromCurrent(lat, lng) > _moveInvalidationMeters;
  }

  /// Fetch only when not already loaded & fresh. Safe to call on every section
  /// build / screen (re)entry.
  Future<void> fetchIfNeeded() async {
    if (isLoading.value) return;

    // Drop the in-memory set if the user has relocated since it loaded.
    if (_movedFarFromLastFetch()) _cache.invalidate();

    // 1) In-session memory cache still fresh.
    if (_cache.isFresh(_identity, hasData: _hasData)) return;

    // 2) Persistent disk cache — show instantly, revalidate only when stale.
    final entry = HiveServices()
        .getGeoList(boxName: HiveServices.nearByStoreBox, key: _identity);
    if (entry != null && entry.items.isNotEmpty) {
      final raw = entry.items.first;
      final parsed = _decode(raw);
      // Both shapes are read back out of the same cached blob. A cached
      // SECTIONED payload leaves `parsed` empty, so gating the hydrate on the
      // v1 lists alone would throw away a perfectly good cache and shimmer on
      // every entry.
      final sections = _decodeSections(raw);
      final hasLegacy = parsed != null &&
          (parsed.stores.isNotEmpty ||
              parsed.services.isNotEmpty ||
              parsed.riders.isNotEmpty);
      // Deliberately NOT `!sections.isEmpty`. The rails draw the BUSINESSES
      // nested under each category, so a payload carrying categories with no
      // `items` is not a usable cache however healthy it looks — accepting it
      // marked the cache fresh and left the rails blank until the TTL expired.
      // [_cacheSchema] already makes that blob unreachable; this is the guard
      // that keeps the NEXT shape change from repeating it.
      final hasSections = sections != null &&
          (sections.shops.any((c) => c.items.isNotEmpty) ||
              sections.services.any((c) => c.items.isNotEmpty) ||
              sections.recentVisited.isNotEmpty);
      if (hasLegacy || hasSections) {
        if (parsed != null) _apply(parsed);
        if (sections != null) _applySections(sections);
        loaded.value = true;
        _lastFetchLat = entry.lat;
        _lastFetchLng = entry.lng;
        _cache.mark(_identity);

        final tooOld = DateTime.now().difference(entry.savedAt) > _persistTtl;
        final movedFar =
            LocationService.metersFromCurrent(entry.lat, entry.lng) >
                _moveInvalidationMeters;
        if (tooOld || movedFar) {
          // Stale-while-revalidate: keep the cached set on screen, refresh
          // quietly so it swaps to fresh data without a blocking shimmer.
          unawaited(fetch(silent: true));
        }
        return;
      }
    }

    // 3) Nothing usable cached — normal fetch.
    await fetch();
  }

  Future<void> fetch({bool silent = false}) async {
    if (isLoading.value) return;
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    if (lat == 0 && lng == 0) {
      loaded.value = true;
      return;
    }
    if (!silent) isLoading.value = true;
    try {
      // No `types` filter → all store types; the response also carries services
      // + riders. Each card keeps its own type so the rail routes per kind.
      final res = await _repo.getNearbyDiscover(lat: lat, lng: lng, radius: 5);
      if (res.isSuccess && res.response?.data is Map) {
        final rawData = Map<String, dynamic>.from(res.response!.data);
        final parsed = NearbyDiscoverResult.fromJson(rawData);
        _apply(parsed);
        // The sectioned shape, off the SAME response — see the field block
        // above for why both are parsed every time.
        _applySections(NearbySectionsResult.fromJson(rawData));
        // Covers stores AND workers — the rail mixes both, so either slice
        // failing makes an empty rail a lie.
        degraded.value = parsed.anyDegraded;
        _lastFetchLat = lat;
        _lastFetchLng = lng;
        _cache.mark(_identity);

        // Persist the raw response (24h TTL). Skip on outage so a degraded
        // payload doesn't get cached as if it were real — a partial payload
        // pinned for 24h is worse than no cache.
        if (!parsed.anyDegraded) {
          unawaited(HiveServices().saveGeoList(
            boxName: HiveServices.nearByStoreBox,
            key: _identity,
            jsonList: [rawData],
            lat: lat,
            lng: lng,
          ));
        }
      }
    } catch (e) {
      log('[NearbyDiscover] fetch error: $e');
    } finally {
      loaded.value = true;
      if (!silent) isLoading.value = false;
    }
  }

  void _apply(NearbyDiscoverResult parsed) {
    stores.assignAll(parsed.stores);
    services.assignAll(parsed.services);
    riders.assignAll(parsed.riders);
    if (parsed.radiusKm > 0) radiusKm.value = parsed.radiusKm;
  }

  /// Publish the sectioned shape.
  ///
  /// Guarded on emptiness: the two parses run against the same response, and
  /// on a LEGACY payload this one finds nothing. Assigning unconditionally
  /// would then wipe sections that a cache hydrate had just populated.
  void _applySections(NearbySectionsResult parsed) {
    if (parsed.isEmpty) return;
    shopCategories.assignAll(parsed.shops);
    serviceCategories.assignAll(parsed.services);
    recentVisited.assignAll(parsed.recentVisited);
    shopsTitle.value = parsed.shopsTitle;
    servicesTitle.value = parsed.servicesTitle;
    recentTitle.value = parsed.recentTitle;
    if (parsed.radiusKm > 0) radiusKm.value = parsed.radiusKm;
    // `meta.degraded` is shared by both shapes; the sectioned payload is the
    // one in play when this parse succeeded, so its list wins.
    degraded.value = parsed.degraded.isNotEmpty;
  }

  /// Re-parse a persisted raw response. The JSON round-trip normalises nested
  /// map key types (Hive returns `Map<dynamic, dynamic>`), matching the network
  /// parser's expectations.
  NearbyDiscoverResult? _decode(dynamic raw) {
    try {
      if (raw is! Map) return null;
      final normalised =
          jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      return NearbyDiscoverResult.fromJson(normalised);
    } catch (e) {
      log('[NearbyDiscover] cache decode error: $e');
      return null;
    }
  }

  /// The sectioned shape, read back out of the same cached blob. Mirrors
  /// [_decode] — including the jsonEncode/jsonDecode round-trip, which is what
  /// turns Hive's dynamic-keyed maps back into `Map<String, dynamic>` before
  /// parsing (a stored Map reads back with the wrong key type and every cast
  /// inside fromJson would fail).
  NearbySectionsResult? _decodeSections(dynamic raw) {
    try {
      if (raw is! Map) return null;
      final normalised = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      return NearbySectionsResult.fromJson(normalised);
    } catch (e) {
      log('[NearbyDiscover] sections cache decode error: $e');
      return null;
    }
  }
}
