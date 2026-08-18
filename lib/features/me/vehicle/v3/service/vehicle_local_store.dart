import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';

/// One cached vehicle catalogue payload, with the moment it was written.
///
/// [data] is the raw JSON list exactly as the API returned it (already unwrapped
/// from its envelope), so the caller rebuilds its models with the same
/// `VehicleCategoryV3.listFrom` a live response goes through — one parser, not
/// two.
class VehicleCacheEntry {
  const VehicleCacheEntry({required this.data, required this.savedAt});

  final dynamic data;
  final DateTime savedAt;

  /// The payload as a list — empty when this entry somehow holds anything else.
  List<dynamic> get items => data is List ? data as List<dynamic> : const [];

  bool get isEmpty {
    final payload = data;
    if (payload == null) return true;
    if (payload is List) return payload.isEmpty;
    if (payload is Map) return payload.isEmpty;
    return false;
  }

  Duration get age => DateTime.now().difference(savedAt);

  bool isOlderThan(Duration ttl) => age >= ttl;
}

/// Local (Hive) store for the vehicle v3 SELLER catalogue.
///
/// The vehicle member of the same family as `GroceryLocalStore` /
/// `ProductLocalStore` — its own box, so one feature's cache can never be read
/// as another's.
///
/// ## What it holds — and what it deliberately does not
/// Only the platform category tree: the level-0 roots and one entry per
/// drilled-into branch (`parentId|level`), which is the brand → model walk the
/// add-vehicle picker makes.
///
/// There is no per-store snapshot here, unlike the other verticals. A vehicle
/// showroom's own data — `my listings`, the summary, the stocked-categories
/// rail — changes every time the seller publishes or sells, and
/// `fetchMyStockedCategories` is inventory-derived rather than catalogue, so
/// none of it belongs behind a 24-hour TTL.
///
/// The vehicle BUYER strips keep their own cache in `HiveServices`
/// (`vehicleLevel0` / `vehicleLevel1_<parentId>`) and stay there: these stores
/// are the me-side (seller) caches.
///
/// ## Why JSON strings and not raw lists
/// Hive hands back `Map<dynamic, dynamic>` for anything written as a bare map,
/// and `VehicleCategoryV3.fromJson` walks `Map<String, dynamic>` — reading such
/// a cache would throw at the first node. Values are therefore `jsonEncode`d on
/// the way in and decoded on the way out.
///
/// ## Freshness
/// [catalogTtl] is the only refresh trigger, because it is the only one that
/// can be: the catalogue is the platform's, and nothing the seller does from
/// this device changes it.
///
/// ## Lifetime
/// The box opens lazily and reopens itself if it was closed, so it survives
/// logout's `Hive.deleteFromDisk()`; [clearAll] is called from
/// `LogoutHelper.clearAccountLocalData()` regardless, so the intent is explicit
/// at the place where account data is dropped.
class VehicleLocalStore {
  const VehicleLocalStore._();

  static const String boxName = 'vehicle_local_cache_box';

  /// Life of a cached category level before the network is consulted.
  static const Duration catalogTtl = Duration(hours: 24);

  /// How many branches to keep. The picker walks root → brand → model, so a
  /// seller listing a handful of makes stays well inside this; past it, the
  /// least recently opened branch is the one nobody is coming back to.
  static const int _maxCatalogEntries = 40;

  static const String _kCatalogRoots = 'catalog:roots';
  static const String _kCatalogChild = 'catalog:child:';

  static Future<Box?> _safeBox() async {
    try {
      return Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
    } catch (e) {
      log('VehicleLocalStore: box unavailable — $e');
      return null;
    }
  }

  // ─── Category tree ───────────────────────────────────────────────

  static Future<VehicleCacheEntry?> readCatalogRoots() => _read(_kCatalogRoots);

  static Future<void> writeCatalogRoots(List<dynamic> items) =>
      _write(_kCatalogRoots, items);

  /// One drilled-into BRANCH, keyed by its parent AND its level — the endpoint
  /// takes both, and the same parent answers differently per level, so the
  /// level has to be part of the key or one would serve the other.
  static Future<VehicleCacheEntry?> readCatalogChild(String key) =>
      key.isEmpty ? Future.value(null) : _read('$_kCatalogChild$key');

  static Future<void> writeCatalogChild(String key, List<dynamic> items) =>
      key.isEmpty ? Future.value() : _write('$_kCatalogChild$key', items);

  // ─── Invalidation ────────────────────────────────────────────────

  /// Everything. Called on logout.
  static Future<void> clearAll() async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.clear();
    } catch (e) {
      log('VehicleLocalStore.clearAll error: $e');
    }
  }

  // ─── Storage ─────────────────────────────────────────────────────

  static Future<VehicleCacheEntry?> _read(String key) async {
    final box = await _safeBox();
    if (box == null) return null;
    try {
      final raw = box.get(key);
      if (raw is! String || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final payload = decoded['data'];
      final savedAt = decoded['savedAt'];
      if (payload == null || savedAt is! int) return null;
      return VehicleCacheEntry(
        data: payload,
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
      );
    } catch (e) {
      log('VehicleLocalStore._read($key) error: $e');
      return null;
    }
  }

  /// Writes [items] under [key]. An empty list is stored as a deletion rather
  /// than an empty entry: "the catalogue has nothing here" is better re-asked
  /// than cached, and it keeps a failed parse from pinning an empty picker.
  static Future<void> _write(String key, List<dynamic> items) async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      if (items.isEmpty) {
        await box.delete(key);
        return;
      }
      await box.put(
        key,
        jsonEncode({
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'data': items,
        }),
      );
      await _prune(box);
    } catch (e) {
      // A payload that won't encode (unexpected non-JSON value) must not take
      // the write path down with it — the screen already has its live data.
      log('VehicleLocalStore._write($key) error: $e');
    }
  }

  /// Keeps at most [_maxCatalogEntries] branches, dropping the least recently
  /// written. The roots entry is never a candidate — it is the one every walk
  /// starts from. An entry with no readable stamp sorts oldest, so a corrupt
  /// row goes first.
  static Future<void> _prune(Box box) async {
    try {
      final keys = box.keys
          .whereType<String>()
          .where((k) => k.startsWith(_kCatalogChild))
          .toList();
      if (keys.length <= _maxCatalogEntries) return;

      final stamped = <({String key, int savedAt})>[];
      for (final key in keys) {
        final raw = box.get(key);
        var savedAt = 0;
        if (raw is String) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map && decoded['savedAt'] is int) {
              savedAt = decoded['savedAt'] as int;
            }
          } catch (_) {}
        }
        stamped.add((key: key, savedAt: savedAt));
      }
      stamped.sort((a, b) => a.savedAt.compareTo(b.savedAt));
      await box.deleteAll(
          stamped.take(keys.length - _maxCatalogEntries).map((e) => e.key));
    } catch (e) {
      log('VehicleLocalStore._prune error: $e');
    }
  }
}
