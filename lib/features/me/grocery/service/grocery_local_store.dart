import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';

/// One cached grocery list, with the moment it was written.
///
/// [items] is the raw JSON exactly as the API returned it — the caller rebuilds
/// its models with the same `fromJson` it uses for a live response, so there is
/// only ever one parser to keep correct.
class GroceryCacheEntry {
  const GroceryCacheEntry({required this.items, required this.savedAt});

  final List<dynamic> items;
  final DateTime savedAt;

  bool get isEmpty => items.isEmpty;

  Duration get age => DateTime.now().difference(savedAt);

  bool isOlderThan(Duration ttl) => age >= ttl;
}

/// Local (Hive) store for everything the grocery admin screens read.
///
/// ## What it holds
/// * **Products tab** — the top-selling list and the category-with-inventory
///   list, one entry each per store.
/// * **Add-grocery flow** — the super-category catalog tree, which is global
///   rather than per store.
///
/// ## Why JSON strings and not raw maps
/// Hive hands back `Map<dynamic, dynamic>` for anything written as a bare map,
/// and every model here parses `Map<String, dynamic>` — reading such a cache
/// would throw at the first `fromJson`. Values are therefore `jsonEncode`d on
/// the way in and decoded on the way out, which is also what [KeyedJsonCache]
/// does for the same reason.
///
/// ## Freshness
/// Nothing here expires on its own. Each entry carries [GroceryCacheEntry
/// .savedAt] and the caller decides: the products tab hydrates from any age and
/// then revalidates in the background (a merchant must never be shown stock
/// that quietly went stale), while the catalog tree — which changes on the
/// order of weeks — skips the network entirely inside [catalogTtl].
///
/// ## Lifetime
/// The box opens lazily and reopens itself if it was closed, so it survives
/// logout's `Hive.deleteFromDisk()`; [clearAll] is called from
/// `LogoutHelper.clearAllLocalData()` regardless, so the intent is explicit at
/// the place where account data is dropped.
class GroceryLocalStore {
  const GroceryLocalStore._();

  static const String boxName = 'grocery_local_cache_box';

  /// Life of the add-grocery catalog tree before the network is consulted.
  static const Duration catalogTtl = Duration(hours: 24);

  /// How many stores' product caches to keep. The admin only ever writes its
  /// own store, but the same lists back "visit another store", so without a cap
  /// a browsing session would grow the box without bound. Oldest go first.
  static const int _maxStoreEntries = 10;

  static const String _kTopSelling = 'topSelling';
  static const String _kCategories = 'categories';
  static const String _kCatalog = 'catalog:superCategories';

  static Future<Box?> _safeBox() async {
    try {
      return Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
    } catch (e) {
      log('GroceryLocalStore: box unavailable — $e');
      return null;
    }
  }

  /// Scopes an entry to the store AND to how it was fetched: the owner and
  /// public endpoints return different shapes for the same store id, so one key
  /// for both would let a visitor's payload render on the admin screen.
  static String _storeKey(String kind, String storeId, bool otherStore) =>
      '$kind|$storeId|${otherStore ? 'public' : 'owner'}';

  // ─── Products tab ────────────────────────────────────────────────

  static Future<GroceryCacheEntry?> readTopSelling(
    String storeId, {
    required bool otherStore,
  }) =>
      _read(_storeKey(_kTopSelling, storeId, otherStore));

  static Future<void> writeTopSelling(
    String storeId, {
    required bool otherStore,
    required List<dynamic> items,
  }) =>
      _write(_storeKey(_kTopSelling, storeId, otherStore), items);

  static Future<GroceryCacheEntry?> readCategories(
    String storeId, {
    required bool otherStore,
  }) =>
      _read(_storeKey(_kCategories, storeId, otherStore));

  static Future<void> writeCategories(
    String storeId, {
    required bool otherStore,
    required List<dynamic> items,
  }) =>
      _write(_storeKey(_kCategories, storeId, otherStore), items);

  // ─── Add-grocery catalog tree (global) ───────────────────────────

  static Future<GroceryCacheEntry?> readCatalogCategories() =>
      _read(_kCatalog);

  static Future<void> writeCatalogCategories(List<dynamic> items) =>
      _write(_kCatalog, items);

  // ─── Invalidation ────────────────────────────────────────────────

  /// Drops both product caches for one store, in both scopes. Used when the
  /// cached snapshot is known to be wrong and cannot be rebuilt locally.
  static Future<void> clearStore(String storeId) async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.deleteAll([
        for (final kind in const [_kTopSelling, _kCategories])
          for (final other in const [true, false]) _storeKey(kind, storeId, other),
      ]);
    } catch (e) {
      log('GroceryLocalStore.clearStore error: $e');
    }
  }

  /// Everything, including the catalog tree. Called on logout.
  static Future<void> clearAll() async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.clear();
    } catch (e) {
      log('GroceryLocalStore.clearAll error: $e');
    }
  }

  // ─── Storage ─────────────────────────────────────────────────────

  static Future<GroceryCacheEntry?> _read(String key) async {
    final box = await _safeBox();
    if (box == null) return null;
    try {
      final raw = box.get(key);
      if (raw is! String || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final items = decoded['items'];
      final savedAt = decoded['savedAt'];
      if (items is! List || savedAt is! int) return null;
      return GroceryCacheEntry(
        items: items,
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
      );
    } catch (e) {
      log('GroceryLocalStore._read($key) error: $e');
      return null;
    }
  }

  /// Writes [items] under [key]. An empty list is stored as a deletion rather
  /// than an empty entry: "the server has nothing for this store" is better
  /// re-asked than cached, and it keeps a failed parse from pinning an empty
  /// screen.
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
          'items': items,
        }),
      );
      await _prune(box);
    } catch (e) {
      // A payload that won't encode (unexpected non-JSON value) must not take
      // the write path down with it — the screen already has its live data.
      log('GroceryLocalStore._write($key) error: $e');
    }
  }

  /// Keeps at most [_maxStoreEntries] stores, dropping the least recently
  /// written. The catalog entry is never a candidate — it is global and small.
  static Future<void> _prune(Box box) async {
    try {
      final storeKeys = box.keys
          .whereType<String>()
          .where((k) => k != _kCatalog)
          .toList();
      // Two entries per store (top-selling + categories), so the cap is on
      // stores rather than on rows.
      if (storeKeys.length <= _maxStoreEntries * 2) return;

      final stamped = <({String key, int savedAt})>[];
      for (final key in storeKeys) {
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
      final excess = stamped.take(stamped.length - _maxStoreEntries * 2);
      await box.deleteAll(excess.map((e) => e.key));
    } catch (e) {
      log('GroceryLocalStore._prune error: $e');
    }
  }
}
