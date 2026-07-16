import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_discover_models.dart';
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

  /// True when the stores slice failed upstream (outage) rather than genuinely
  /// having nothing nearby — see the guide's `meta.degraded`.
  final RxBool degraded = false.obs;

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
  String get _identity => 'nearby-discover|$userId';

  /// Where the data currently in memory was fetched, for the move check.
  double? _lastFetchLat;
  double? _lastFetchLng;

  bool get _hasData =>
      stores.isNotEmpty || services.isNotEmpty || riders.isNotEmpty;

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
      if (parsed != null && (parsed.stores.isNotEmpty ||
          parsed.services.isNotEmpty ||
          parsed.riders.isNotEmpty)) {
        _apply(parsed);
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
        degraded.value = parsed.storesDegraded;
        _lastFetchLat = lat;
        _lastFetchLng = lng;
        _cache.mark(_identity);

        // Persist the raw response (24h TTL). Skip on outage so a degraded
        // payload doesn't get cached as if it were real.
        if (!parsed.storesDegraded) {
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
    _logResult(parsed);
  }

  /// TEST logging — dumps the parsed nearby set so you can eyeball what the
  /// "Near You" rail receives. Remove once verified.
  void _logResult(NearbyDiscoverResult parsed) {
    log('[NearbyDiscover] stores=${parsed.stores.length} '
        'services=${parsed.services.length} riders=${parsed.riders.length} '
        'degraded=${parsed.degraded}');
    for (final s in parsed.stores) {
      log('[NearbyDiscover]   STORE type=${s.type} name="${s.businessName}" '
          'category="${s.displayCategory}" dist=${s.distance}km '
          'id=${s.id} userId=${s.userId} '
          'products=${s.totalProductCount} categories=${s.totalCategoryCount} '
          'rating=${s.avgRating} logo="${s.logo}"');
    }
    for (final w in parsed.services) {
      log('[NearbyDiscover]   SERVICE name="${w.name}" '
          'designation="${w.designation}" profession=${w.profession} '
          'live=${w.live} dist=${w.distance}km userId=${w.userId}');
    }
    for (final w in parsed.riders) {
      log('[NearbyDiscover]   RIDER name="${w.name}" '
          'designation="${w.designation}" live=${w.live} '
          'dist=${w.distance}km userId=${w.userId}');
    }
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
}
