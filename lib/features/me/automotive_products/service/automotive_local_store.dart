import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';

/// One cached product list, with the moment it was written.
///
/// [items] is the raw JSON exactly as the API returned it — the caller rebuilds
/// its models with the same `fromJson` it uses for a live response, so there is
/// only ever one parser to keep correct.
class AutomotiveCacheEntry {
  const AutomotiveCacheEntry({required this.data, required this.savedAt});

  /// Raw JSON exactly as the API returned it: a List for the rails and for a
  /// category LIST, a Map for a single category SUBTREE (the by-id endpoints
  /// answer with one object, not a list).
  final dynamic data;
  final DateTime savedAt;

  /// The payload as a list — empty when this entry holds a map.
  List<dynamic> get items => data is List ? data as List<dynamic> : const [];

  /// The payload as a JSON object — null when this entry holds a list. Rebuilt
  /// as `Map<String, dynamic>` because that is what every `fromJson` here
  /// wants.
  Map<String, dynamic>? get map =>
      data is Map ? Map<String, dynamic>.from(data as Map) : null;

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

/// Local (Hive) store for everything the automotive admin screens read.
///
/// The automotive twin of `GroceryLocalStore` / `ProductLocalStore`, entry
/// for entry — its own box, so one feature's cache can never be read as another's.
///
/// ## What it holds
/// * **Products tab** — the top-selling list and the category-with-inventory
///   list, one entry each per store.
/// * **Add-product flow** — the level-0 super-category list, which is global
///   rather than per store.
///
/// ## Why JSON strings and not raw maps
/// Hive hands back `Map<dynamic, dynamic>` for anything written as a bare map,
/// and `GetProductModel.fromJson` / `AutomotiveProductCategoryWithInventoryModel
/// .fromJson` both walk `Map<String, dynamic>` — reading such a cache would
/// throw at the first nested model. Values are therefore `jsonEncode`d on the
/// way in and decoded on the way out.
///
/// ## Freshness
/// Nothing here expires on its own, because nothing needs to: the merchant's
/// own writes are the only thing that can change their catalogue on this
/// device, and every one of them runs
/// `AutomotiveInventoryController.markInventoryChanged()`, which deletes the
/// snapshot and refetches. The one exception is the super-category list — no local action
/// can invalidate it, so it carries [catalogTtl].
///
/// ## Lifetime
/// The box opens lazily and reopens itself if it was closed, so it survives
/// logout's `Hive.deleteFromDisk()`; [clearAll] is called from
/// `LogoutHelper.clearAccountLocalData()` regardless, so the intent is explicit
/// at the place where account data is dropped.
class AutomotiveLocalStore {
  const AutomotiveLocalStore._();

  static const String boxName = 'automotive_local_cache_box';

  /// Life of the add-product super-category list before the network is
  /// consulted.
  static const Duration catalogTtl = Duration(hours: 24);

  /// How many stores' caches to keep. The admin only ever writes its own, but
  /// the same lists back "visit another store", so without a cap a browsing
  /// session would grow the box without bound. Oldest go first.
  static const int _maxStoreEntries = 10;

  static const String _kTopSelling = 'topSelling';
  static const String _kCategories = 'categories';
  static const String _kCatalog = 'catalog:superCategories';

  /// Every category-tree key starts with this, so [_prune] can hold the whole
  /// family out of the per-store cap with one test.
  static const String _kCatalogPrefix = 'catalog';

  /// One entry per drilled-into branch: `catalog:child:<key or id>`.
  static const String _kCatalogChild = 'catalog:child:';

  /// How many category branches to keep. The add flow drills a few levels at a
  /// time; well past that, the least recently opened branch is the one nobody
  /// is coming back to.
  static const int _maxCatalogEntries = 40;

  static Future<Box?> _safeBox() async {
    try {
      return Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
    } catch (e) {
      log('AutomotiveLocalStore: box unavailable — $e');
      return null;
    }
  }

  /// Scopes an entry to the store AND to how it was fetched: the owner and
  /// public endpoints return different shapes for the same store id, so one key
  /// for both would let a visitor's payload render on the admin screen.
  static String _storeKey(String storeId, String kind, bool otherStore) =>
      '$kind|$storeId|${otherStore ? 'public' : 'owner'}';

  // ─── Products tab ────────────────────────────────────────────────

  static Future<AutomotiveCacheEntry?> readTopSelling(
    String storeId, {
    required bool otherStore,
  }) =>
      _read(_storeKey(storeId, _kTopSelling, otherStore));

  static Future<void> writeTopSelling(
    String storeId, {
    required bool otherStore,
    required List<dynamic> items,
  }) =>
      _write(_storeKey(storeId, _kTopSelling, otherStore), items);

  static Future<AutomotiveCacheEntry?> readCategories(
    String storeId, {
    required bool otherStore,
  }) =>
      _read(_storeKey(storeId, _kCategories, otherStore));

  static Future<void> writeCategories(
    String storeId, {
    required bool otherStore,
    required List<dynamic> items,
  }) =>
      _write(_storeKey(storeId, _kCategories, otherStore), items);

  // ─── Add-product super categories (global) ───────────────────────

  static Future<AutomotiveCacheEntry?> readCatalogCategories() => _read(_kCatalog);

  static Future<void> writeCatalogCategories(List<dynamic> items) =>
      _write(_kCatalog, items);

  /// One drilled-into BRANCH of the category tree, keyed by whatever identifies
  /// it in the request — a category key for the by-key endpoints, a category id
  /// for the by-id ones.
  ///
  /// Carries [catalogTtl] like the root, and for the same reason: the platform
  /// catalogue is not something the merchant can change from this device, so
  /// age is the only refresh trigger it can have.
  ///
  /// The payload is a List for the by-key endpoints and a Map for the by-id
  /// ones (they answer with a single node) — the entry holds whichever, and the
  /// caller reads `items` or `map`.
  static Future<AutomotiveCacheEntry?> readCatalogChild(String key) =>
      key.isEmpty ? Future.value(null) : _read('$_kCatalogChild$key');

  static Future<void> writeCatalogChild(String key, dynamic data) =>
      key.isEmpty ? Future.value() : _write('$_kCatalogChild$key', data);

  // ─── Invalidation ────────────────────────────────────────────────

  /// Drops both product caches for one store, in both scopes. Used when the
  /// cached snapshot is known to be wrong and cannot be rebuilt locally.
  static Future<void> clearStore(String storeId) async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.deleteAll([
        for (final kind in const [_kTopSelling, _kCategories])
          for (final other in const [true, false])
            _storeKey(storeId, kind, other),
      ]);
    } catch (e) {
      log('AutomotiveLocalStore.clearStore error: $e');
    }
  }

  /// Everything, including the super-category list. Called on logout.
  static Future<void> clearAll() async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.clear();
    } catch (e) {
      log('AutomotiveLocalStore.clearAll error: $e');
    }
  }

  // ─── Storage ─────────────────────────────────────────────────────

  static Future<AutomotiveCacheEntry?> _read(String key) async {
    final box = await _safeBox();
    if (box == null) return null;
    try {
      final raw = box.get(key);
      if (raw is! String || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      // `items` is the legacy envelope key, written back when every payload
      // here was a list; `data` is the current one and also carries subtree
      // objects. Reading both keeps snapshots written before subtrees existed
      // readable instead of silently dropping them.
      final payload = decoded['data'] ?? decoded['items'];
      final savedAt = decoded['savedAt'];
      if (payload == null || savedAt is! int) return null;
      return AutomotiveCacheEntry(
        data: payload,
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
      );
    } catch (e) {
      log('AutomotiveLocalStore._read($key) error: $e');
      return null;
    }
  }

  /// Writes [data] under [key]. An empty list / map is stored as a deletion rather
  /// than an empty entry: "the server has nothing for this store" is better
  /// re-asked than cached, and it keeps a failed parse from pinning an empty
  /// screen.
  static Future<void> _write(String key, dynamic data) async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      final isEmpty = data == null ||
          (data is List && data.isEmpty) ||
          (data is Map && data.isEmpty);
      if (isEmpty) {
        await box.delete(key);
        return;
      }
      await box.put(
        key,
        jsonEncode({
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        }),
      );
      await _prune(box);
    } catch (e) {
      // A payload that won't encode (unexpected non-JSON value) must not take
      // the write path down with it — the screen already has its live data.
      log('AutomotiveLocalStore._write($key) error: $e');
    }
  }

  /// Keeps the box bounded, in two INDEPENDENT families:
  ///
  /// * per-store snapshots — at most [_maxStoreEntries] stores, two rows each;
  /// * category-tree entries — the root list plus one per drilled-into branch,
  ///   capped at [_maxCatalogEntries].
  ///
  /// Separate on purpose. One shared cap would let a merchant who browsed a few
  /// category branches evict their own store's Products-tab snapshot; and the
  /// previous version, which exempted only the single root key, would have
  /// evicted the branches themselves the moment they outnumbered the cap.
  static Future<void> _prune(Box box) async {
    try {
      final keys = box.keys.whereType<String>().toList();
      // Two entries per store (top-selling + categories), so the cap is on
      // stores rather than on rows.
      await _pruneFamily(
        box,
        keys.where((k) => !k.startsWith(_kCatalogPrefix)),
        _maxStoreEntries * 2,
      );
      await _pruneFamily(
        box,
        keys.where((k) => k.startsWith(_kCatalogChild)),
        _maxCatalogEntries,
      );
    } catch (e) {
      log('AutomotiveLocalStore._prune error: $e');
    }
  }

  /// Drops the least recently written of [keys] until at most [cap] remain. An
  /// entry with no readable stamp sorts oldest, so a corrupt row goes first.
  static Future<void> _pruneFamily(
      Box box, Iterable<String> keys, int cap) async {
    final list = keys.toList();
    if (list.length <= cap) return;

    final stamped = <({String key, int savedAt})>[];
    for (final key in list) {
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
    await box.deleteAll(stamped.take(list.length - cap).map((e) => e.key));
  }
}
