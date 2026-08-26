import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';

/// One cached food payload, with the moment it was written.
///
/// [data] is the raw JSON exactly as the API returned it — a List for the
/// paginated rails, a Map for the home object — so the caller rebuilds its
/// models with the same `fromJson` it uses for a live response, and there is
/// only ever one parser to keep correct.
class FoodCacheEntry {
  const FoodCacheEntry({required this.data, required this.savedAt});

  final dynamic data;
  final DateTime savedAt;

  /// The payload as a list — empty when this entry holds a map.
  List<dynamic> get items => data is List ? data as List<dynamic> : const [];

  /// The payload as a JSON object — null when this entry holds a list.
  /// Rebuilt as `Map<String, dynamic>` because every `fromJson` here wants
  /// that shape (see the class doc on why the box stores JSON strings).
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

/// Local (Hive) store for everything the restaurant admin screens read.
///
/// The food twin of `GroceryLocalStore`, entry for entry.
///
/// ## What it holds
/// * **Products tab** — the restaurant home object (menu categories,
///   restaurant specials, contact / profile) and the first page of the Offer
///   Dish rail, one entry each per restaurant.
/// * **Add-food flow** — the nested food-category tree, which is global rather
///   than per restaurant.
///
/// ## Why JSON strings and not raw maps
/// Hive hands back `Map<dynamic, dynamic>` for anything written as a bare map,
/// and `FoodData.fromJson` / `MyFoodProductData.fromJson` walk it as
/// `Map<String, dynamic>` — reading such a cache would throw at the first
/// nested model. Values are therefore `jsonEncode`d on the way in and decoded
/// on the way out, which also gives every nested map the right type for free.
///
/// ## Freshness
/// Nothing here expires on its own, because nothing needs to: the merchant's
/// own writes are the only thing that can change their menu on this device, and
/// every one of them runs `RestaurantController.markMenuChanged()`, which
/// deletes the snapshot and refetches. The one exception is the category tree —
/// no local action can invalidate it, so it carries [catalogTtl].
///
/// ## Lifetime
/// The box opens lazily and reopens itself if it was closed, so it survives
/// logout's `Hive.deleteFromDisk()`; [clearAll] is called from
/// `LogoutHelper.clearAccountLocalData()` regardless, so the intent is explicit
/// at the place where account data is dropped.
class FoodLocalStore {
  const FoodLocalStore._();

  static const String boxName = 'food_local_cache_box';

  /// Life of the add-food category tree before the network is consulted.
  static const Duration catalogTtl = Duration(hours: 24);

  /// How many restaurants' caches to keep. The admin only ever writes its own,
  /// but nothing stops the box growing if that ever changes, so the oldest go
  /// first. Two entries per restaurant (home + discount).
  static const int _maxStoreEntries = 10;

  static const String _kHome = 'home';
  static const String _kDiscount = 'discount';

  /// The productVariant ids already in this restaurant's inventory. Per-store
  /// like [_kHome] / [_kDiscount], and invalidated by exactly the same writes:
  /// adding or deleting a variant is what changes this set.
  static const String _kStockedVariantIds = 'stockedVariantIds';
  static const String _kCatalog = 'catalog:foodCategories';

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
      log('FoodLocalStore: box unavailable — $e');
      return null;
    }
  }

  /// Owner scope is the only one written (see
  /// `RestaurantController._hydrateFoodDataFromCache`), but the scope stays in
  /// the key so a visitor's payload could never render on the admin screen if
  /// that ever changes.
  static String _storeKey(String kind, String businessId) =>
      '$kind|$businessId|owner';

  // ─── Products tab ────────────────────────────────────────────────

  static Future<FoodCacheEntry?> readHome(String businessId) =>
      _read(_storeKey(_kHome, businessId));

  static Future<void> writeHome(
    String businessId, {
    required Map<String, dynamic> data,
  }) =>
      _write(_storeKey(_kHome, businessId), data);

  static Future<FoodCacheEntry?> readDiscount(String businessId) =>
      _read(_storeKey(_kDiscount, businessId));

  static Future<void> writeDiscount(
    String businessId, {
    required List<dynamic> items,
  }) =>
      _write(_storeKey(_kDiscount, businessId), items);

  /// The productVariant ids this restaurant already stocks.
  ///
  /// Cached like the rest of the admin data, and correct for exactly as long:
  /// the merchant's own publishes and deletes are the only thing that moves the
  /// set on this device, and both go through [clearStore].
  static Future<FoodCacheEntry?> readStockedVariantIds(String businessId) =>
      _read(_storeKey(_kStockedVariantIds, businessId));

  static Future<void> writeStockedVariantIds(
    String businessId, {
    required List<dynamic> ids,
  }) =>
      _write(_storeKey(_kStockedVariantIds, businessId), ids);

  // ─── Add-food category tree (global) ─────────────────────────────

  static Future<FoodCacheEntry?> readCatalogCategories() => _read(_kCatalog);

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
  static Future<FoodCacheEntry?> readCatalogChild(String key) =>
      key.isEmpty ? Future.value(null) : _read('$_kCatalogChild$key');

  static Future<void> writeCatalogChild(String key, dynamic data) =>
      key.isEmpty ? Future.value() : _write('$_kCatalogChild$key', data);

  // ─── Invalidation ────────────────────────────────────────────────

  /// Drops both caches for one restaurant. Used when the cached snapshot is
  /// known to be wrong and cannot be rebuilt locally.
  static Future<void> clearStore(String businessId) async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.deleteAll([
        for (final kind in const [_kHome, _kDiscount, _kStockedVariantIds])
          _storeKey(kind, businessId),
      ]);
    } catch (e) {
      log('FoodLocalStore.clearStore error: $e');
    }
  }

  /// Everything, including the category tree. Called on logout.
  static Future<void> clearAll() async {
    final box = await _safeBox();
    if (box == null) return;
    try {
      await box.clear();
    } catch (e) {
      log('FoodLocalStore.clearAll error: $e');
    }
  }

  // ─── Storage ─────────────────────────────────────────────────────

  static Future<FoodCacheEntry?> _read(String key) async {
    final box = await _safeBox();
    if (box == null) return null;
    try {
      final raw = box.get(key);
      if (raw is! String || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final data = decoded['data'];
      final savedAt = decoded['savedAt'];
      if (data == null || savedAt is! int) return null;
      return FoodCacheEntry(
        data: data,
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
      );
    } catch (e) {
      log('FoodLocalStore._read($key) error: $e');
      return null;
    }
  }

  /// Writes [data] under [key]. An empty list / map is stored as a deletion
  /// rather than an empty entry: "the server has nothing for this restaurant"
  /// is better re-asked than cached, and it keeps a failed parse from pinning
  /// an empty screen.
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
      log('FoodLocalStore._write($key) error: $e');
    }
  }

  /// Keeps the box bounded, in two INDEPENDENT families:
  ///
  /// * per-store snapshots — at most [_maxStoreEntries] restaurants, two rows
  ///   each;
  /// * category-tree entries — the root list plus one per drilled-into branch,
  ///   capped at [_maxCatalogEntries].
  ///
  /// Separate on purpose. One shared cap would let a merchant who browsed a few
  /// category branches evict their own restaurant's Products-tab snapshot; and
  /// the previous version, which exempted only the single root key, would have
  /// evicted the branches themselves the moment they outnumbered the cap.
  static Future<void> _prune(Box box) async {
    try {
      final keys = box.keys.whereType<String>().toList();
      // Two entries per restaurant (home + discount), so the cap is on
      // restaurants rather than on rows.
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
      log('FoodLocalStore._prune error: $e');
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
