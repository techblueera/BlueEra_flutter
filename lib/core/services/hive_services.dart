import 'dart:convert';
import 'dart:developer';
import 'package:BlueEra/core/api/model/admin_video_model_response.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/medical/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:hive/hive.dart';

/// A persisted, location-stamped list cache entry (see [HiveServices.getGeoList]).
/// Holds the raw JSON [items] plus the [lat]/[lng] and [savedAt] of the fetch
/// so the reader can apply its own TTL + "moved too far" rules.
class GeoCacheEntry {
  GeoCacheEntry({
    required this.items,
    required this.lat,
    required this.lng,
    required this.savedAt,
  });

  /// Raw JSON list as stored (each element is typically a `Map`). The caller
  /// maps these into its model type.
  final List<dynamic> items;
  final double lat;
  final double lng;
  final DateTime savedAt;
}

class HiveServices{
  static const String _savedPosts = 'savedPosts';
  static const String _savedVideos = 'savedVideos';
  static const String _savedAllNearByStore = 'savedAllNearByStore';
  static const String _savedAllNearByStoreProduct = 'savedAllNearByStoreProduct';
  static const String _savedAllNearByStoreService = 'savedAllNearByStoreService';
  static const String _savedAllNearByStoresFoodServices = 'savedAllNearByStoresFoodServices';
  static const String _savedBusinessCategoryBox = 'business_categories_box';
  static const String _savedProfessionTypeBox = 'profession_type_box';
  static const String _savedAdminVideosBox = 'savedAdminVideosBox';
  static const String _savedGroceryNestedCategoryBox = 'savedGroceryNestedCategoryBox';
  static const String _savedMedicalNestedCategoryBox = 'savedMedicalNestedCategoryBox';
  static const String _savedProductNestedCategoryBox = 'savedProductNestedCategoryBox';
  static const String _savedFoodNestedCategoryBox = 'savedFoodNestedCategoryBox';
  static const String _savedVehicleCategoryBox = 'savedVehicleCategoryBox';

  /// Product / category counts per store, keyed by store id.
  ///
  /// Deliberately NOT in the geo box beside the stores themselves. That cache
  /// is one entry per dataset identity, scoped to where it was fetched, and is
  /// replaced wholesale on every refresh — counts keyed that way would be
  /// discarded every time the list reloaded, and re-fetched for stores whose
  /// numbers had not changed. A store's counts are a property of the STORE, not
  /// of the place the user was standing when the list came back, so they live
  /// one-row-per-store and survive the list being replaced.
  static const String _savedStoreCountsBox = 'savedStoreCountsBox';

  /// Initialize Hive boxes
  static Future<void> init() async {
    await Hive.openBox(_savedPosts);
    await Hive.openBox(_savedVideos);
    await Hive.openBox(_savedAllNearByStore);
    await Hive.openBox(_savedAllNearByStoreProduct);
    await Hive.openBox(_savedAllNearByStoreService);
    await Hive.openBox(_savedAllNearByStoresFoodServices);
    await Hive.openBox(_savedBusinessCategoryBox);
    await Hive.openBox(_savedProfessionTypeBox);
    await Hive.openBox(_savedAdminVideosBox);
    await Hive.openBox(_savedGroceryNestedCategoryBox);
    await Hive.openBox(_savedMedicalNestedCategoryBox);
    await Hive.openBox(_savedProductNestedCategoryBox);
    await Hive.openBox(_savedFoodNestedCategoryBox);
    await Hive.openBox(_savedVehicleCategoryBox);
    await Hive.openBox(_savedStoreCountsBox);
  }

  static List<String> get allBoxNames => [
    _savedPosts,
    _savedVideos,
    _savedAllNearByStore,
    _savedAllNearByStoreProduct,
    _savedAllNearByStoreService,
    _savedAllNearByStoresFoodServices,
    _savedBusinessCategoryBox,
    _savedProfessionTypeBox,
    _savedAdminVideosBox,
    _savedGroceryNestedCategoryBox,
    _savedMedicalNestedCategoryBox,
    _savedProductNestedCategoryBox,
    _savedFoodNestedCategoryBox,
    _savedVehicleCategoryBox,
    _savedStoreCountsBox,
  ];

  // ── Category-tree caches (raw JSON) ──────────────────────────────────────
  // The super/nested category endpoints return a potentially large tree.
  // We store the RAW decoded list (un-parsed) so the caller can rebuild the
  // model graph on a background isolate via `compute`, keeping the UI thread
  // free. Keyed per-feature; a single fixed key holds the super-category list.

  Future<void> _putRawList(String boxName, String key, List<dynamic> raw) async {
    try {
      final box = Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
      await box.put(key, raw);
    } catch (e) {
      log('Hive _putRawList($boxName/$key) error: $e');
    }
  }

  List<dynamic>? _getRawList(String boxName, String key) {
    try {
      if (!Hive.isBoxOpen(boxName)) return null;
      final data = Hive.box(boxName).get(key);
      return data is List ? data : null;
    } catch (e) {
      log('Hive _getRawList($boxName/$key) error: $e');
      return null;
    }
  }

  /// Default life of a cached category tree. Catalog levels change on the order
  /// of weeks, so anything inside this window is served from Hive and the
  /// endpoint is not called at all — see [_isFresh].
  static const Duration categoryCacheTtl = Duration(hours: 24);

  /// Records when [key] was last written, alongside the payload itself.
  /// A sibling `<key>__ts` entry keeps [_getRawList] returning a plain list.
  Future<void> _stamp(String boxName, String key) async {
    try {
      final box = Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
      await box.put('${key}__ts', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      log('Hive _stamp($boxName/$key) error: $e');
    }
  }

  /// True when [key] was written less than [ttl] ago. False when it was never
  /// stamped, so a cache written before stamping existed simply refreshes once.
  bool _isFresh(String boxName, String key, Duration ttl) {
    try {
      if (!Hive.isBoxOpen(boxName)) return false;
      final ts = Hive.box(boxName).get('${key}__ts');
      if (ts is! int) return false;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      return age >= 0 && age < ttl.inMilliseconds;
    } catch (e) {
      log('Hive _isFresh($boxName/$key) error: $e');
      return false;
    }
  }

  Future<void> saveFoodSuperCategoriesRaw(List<dynamic> raw) =>
      _putRawList(_savedFoodNestedCategoryBox, 'foodSuper', raw);
  List<dynamic>? getFoodSuperCategoriesRaw() =>
      _getRawList(_savedFoodNestedCategoryBox, 'foodSuper');

  // Grocery's category tree moved to `GroceryLocalStore` (one store for every
  // grocery cache, with a savedAt stamp), so there is no `saveGrocerySuper…`
  // here any more.

  Future<void> saveProductSuperCategoriesRaw(List<dynamic> raw) =>
      _putRawList(_savedProductNestedCategoryBox, 'productSuperRaw', raw);
  List<dynamic>? getProductSuperCategoriesRaw() =>
      _getRawList(_savedProductNestedCategoryBox, 'productSuperRaw');

  // Level-0 nested categories backing the automotive consumer
  // category-discover tabs. Cache-first so the tabs render instantly and
  // the network refresh stays silent. Reuses the product nested-category
  // box with a distinct key (no extra box to register).
  Future<void> saveAutomotiveDiscoverCategoriesRaw(List<dynamic> raw) async {
    await _putRawList(
        _savedProductNestedCategoryBox, 'automotiveDiscoverRaw', raw);
    await _stamp(_savedProductNestedCategoryBox, 'automotiveDiscoverRaw');
  }

  List<dynamic>? getAutomotiveDiscoverCategoriesRaw() =>
      _getRawList(_savedProductNestedCategoryBox, 'automotiveDiscoverRaw');

  /// Within the TTL the tabs are served from Hive only — the nested-category
  /// call is skipped outright rather than run silently in the background.
  bool isAutomotiveDiscoverCategoriesFresh(
          {Duration ttl = categoryCacheTtl}) =>
      _isFresh(_savedProductNestedCategoryBox, 'automotiveDiscoverRaw', ttl);

  // Vehicle-service (v3) catalog levels backing the buyer discover strips:
  // level 0 = types, level 1 = brands under a type. One entry per [key] —
  // `vehicleLevel0`, `vehicleLevel1_<parentId|all>` — because each is a
  // separate endpoint read the buyer switches between constantly.
  Future<void> saveVehicleCategoriesRaw(String key, List<dynamic> raw) async {
    await _putRawList(_savedVehicleCategoryBox, key, raw);
    await _stamp(_savedVehicleCategoryBox, key);
  }

  List<dynamic>? getVehicleCategoriesRaw(String key) =>
      _getRawList(_savedVehicleCategoryBox, key);

  bool isVehicleCategoriesFresh(String key,
          {Duration ttl = categoryCacheTtl}) =>
      _isFresh(_savedVehicleCategoryBox, key, ttl);

  bool isPostSaved(String id) {
    if (!Hive.isBoxOpen(_savedPosts)) return false;
    final box = Hive.box(_savedPosts);
    final String key = '${userId}_$id';
    return box.containsKey(key);
  }

  Future<bool> savePostJson(Post post) async {
    log('post----> ${post.toJson()}');
    final box = Hive.box(_savedPosts);
    final String key = '${userId}_${post.id}';
    await box.put(key, post.toJson());
    return true;
  }

  List<Post> getAllSavedPosts() {
    final box = Hive.box(_savedPosts);
    final List<Post> posts = [];

    for (final dynamic key in box.keys) {
      if (key is String && key.startsWith('$userId\_')) {
        final dynamic value = box.get(key);

        try {
          if (value is Map) {
            // Safely convert Hive's stored map into a clean JSON Map
            final postMap = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
            posts.add(Post.fromJson(postMap));
          } else {
            print('Hive -> Unexpected value type for key "$key": ${value.runtimeType}');
          }
        } catch (e, st) {
          print('Hive -> Failed to parse Post for key "$key"');
          print('Error: $e');
          print('StackTrace: $st');
          print('Raw value: $value\n');
        }
      }
    }

    return posts;
  }

  Post? getPostById(String postId) {
    final box = Hive.box(_savedPosts);
    final String key = '${userId}_$postId';
    final dynamic value = box.get(key);
    if (value is Map) {
      try {
        return Post.fromJson(jsonDecode(jsonEncode(value)) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deletePostById(String postId) async {
    final box = Hive.box(_savedPosts);
    final String key = '${userId}_$postId';
    await box.delete(key);
  }

  bool isVideoSaved(String id) {
    if (!Hive.isBoxOpen(_savedVideos)) return false;
    final box = Hive.box(_savedVideos);
    final String key = '${userId}_$id';
    return box.containsKey(key);
  }

  Future<bool> saveVideoJson(ShortFeedItem shortFeedItem) async {
    final box = Hive.box(_savedVideos);
    final String key = '${userId}_${shortFeedItem.videoId ?? shortFeedItem.video?.id ?? ''}';
    await box.put(key, shortFeedItem.toJson());
    return true;
  }

  List<ShortFeedItem> getAllSavedVideos() {
    final box = Hive.box(_savedVideos);
    final List<ShortFeedItem> videos = [];
    for (final dynamic key in box.keys) {
      if (key is String && key.startsWith('$userId\_')) {
        final dynamic value = box.get(key);

          try {
            if (value is Map) {
              final postMap = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
              videos.add(ShortFeedItem.fromJson(postMap));
            }else{
              print('Hive -> Unexpected value type for key "$key": ${value.runtimeType}');
            }
          } catch (_) {}
      }
    }
    return videos;
  }

  ShortFeedItem? getVideoById(String videoId) {
    final box = Hive.box(_savedVideos);
    final String key = '${userId}_$videoId';
    final dynamic value = box.get(key);
    if (value is Map) {
      try {
        return ShortFeedItem.fromJson(jsonDecode(jsonEncode(value)) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> deleteVideoById(String videoId) async {
    final box = Hive.box(_savedVideos);
    final String key = '${userId}_$videoId';
    await box.delete(key);
  }

  // /// Conversation regarding Database
  // final box = Hive.box<GetHiveChatConversation>('conversations');
  //
  // Future<void> saveConversation(String userId, GetHiveChatConversation convo) async {
  //   await box.put('${userId}_${convo.conversationId}', convo);
  // }
  //
  // List<GetHiveChatConversation> getUserConversations(String userId) {
  //   return box.values
  //       .where((convo) =>
  //       (box.keyAt(box.values.toList().indexOf(convo)) as String)
  //           .startsWith('${userId}_'))
  //       .toList();
  // }
  //
  // Future<void> deleteConversation(String userId, String convoId) async {
  //   await box.delete('${userId}_$convoId');
  // }


  /// All Stores
  ///
  /// Generic location-aware list cache. Persists a JSON list under [key] in
  /// [boxName] together with the location ([lat]/[lng]) and time it was
  /// fetched, so a later read can decide whether the data is too old or the
  /// user has moved too far to reuse it (stale-while-revalidate).
  ///
  /// One entry per [key] — callers key by dataset identity (e.g.
  /// `stores|<user>|<type>|<category>`) so grocery / food / product / service
  /// caches never clobber each other (the old `user_<id>`-only key did).
  Future<bool> saveGeoList({
    required String boxName,
    required String key,
    required List<Map<String, dynamic>> jsonList,
    required double lat,
    required double lng,
  }) async {
    try {
      final box = Hive.box(boxName);
      await box.put(key, {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'lat': lat,
        'lng': lng,
        'items': jsonList,
      });
      print('Saved ${jsonList.length} geo-cache items for key: $key');
      return true;
    } catch (e) {
      print('Error saving geo-cache list ($key): $e');
      return false;
    }
  }

  /// Reads the raw geo-cache entry for [key] in [boxName], or null when absent
  /// / malformed (including legacy bare-list entries). The caller maps
  /// [GeoCacheEntry.items] into its model type and applies TTL + distance
  /// rules against [GeoCacheEntry.savedAt] / `lat` / `lng`.
  GeoCacheEntry? getGeoList({required String boxName, required String key}) {
    try {
      final box = Hive.box(boxName);
      final data = box.get(key);
      if (data is! Map) return null;
      final items = data['items'];
      if (items is! List) return null;
      return GeoCacheEntry(
        items: items,
        lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
        savedAt: DateTime.fromMillisecondsSinceEpoch(
            (data['savedAt'] as num?)?.toInt() ?? 0),
      );
    } catch (e) {
      print('Error loading geo-cache list ($key): $e');
      return null;
    }
  }

  /// Box name for the near-by store / service geo-cache, exposed so callers
  /// can pass it to [saveGeoList] / [getGeoList].
  static String get nearByStoreBox => _savedAllNearByStore;

  // ── Store product / category counts ──────────────────────────────────────
  //
  // One row per store id, written as it arrives and read on the next cold
  // start. See [_savedStoreCountsBox] for why these are not in the geo cache
  // with the stores.

  /// Merges [counts] — `storeId → row JSON` — into the counts cache.
  ///
  /// Merge rather than replace: a page of stores answers for its own ids only,
  /// so overwriting the box would drop the counts for every store the user has
  /// already scrolled past.
  Future<void> saveStoreCounts(Map<String, Map<String, dynamic>> counts) async {
    if (counts.isEmpty) return;
    try {
      final box = Hive.box(_savedStoreCountsBox);
      await box.putAll({
        for (final entry in counts.entries)
          entry.key: {
            'savedAt': DateTime.now().millisecondsSinceEpoch,
            'row': entry.value,
          },
      });
    } catch (e) {
      print('Error saving store counts: $e');
    }
  }

  /// Cached counts for [storeIds], as `storeId → row JSON`.
  ///
  /// Rows older than [maxAge] are skipped: a stale count is worse than none,
  /// because a store card showing "0 products" reads as a fact rather than as
  /// a number that hasn't loaded. Ids with no usable row are simply absent —
  /// the caller fetches those.
  Map<String, Map<String, dynamic>> getStoreCounts(
    Iterable<String> storeIds, {
    Duration maxAge = const Duration(hours: 6),
  }) {
    final out = <String, Map<String, dynamic>>{};
    try {
      final box = Hive.box(_savedStoreCountsBox);
      final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
      for (final id in storeIds) {
        final data = box.get(id);
        if (data is! Map) continue;
        final savedAt = (data['savedAt'] as num?)?.toInt() ?? 0;
        if (savedAt < cutoff) continue;
        final row = data['row'];
        if (row is Map) out[id] = Map<String, dynamic>.from(row);
      }
    } catch (e) {
      print('Error loading store counts: $e');
    }
    return out;
  }

  /// All Stores Products
  Future<bool> saveAllStoreProduct(
      List<GetProductData> allStoresProductsData,
      String userId,
      ) async {
    try {
      final box = Hive.box(_savedAllNearByStoreProduct);
      final String key = 'user_$userId';

      final List<Map<String, dynamic>> jsonList =
      allStoresProductsData.map((item) => item.toJson()).toList();

      await box.put(key, jsonList);

      print('Saved ${jsonList.length} stores feed items for user: $userId');
      return true;
    } catch (e) {
      print('Error saving stores feed: $e');
      return false;
    }
  }

  Future<List<GetProductData>?> getAllStoreProduct(String userId) async {
    try {
      final box = Hive.box(_savedAllNearByStoreProduct);
      final String key = 'user_$userId';

      final data = box.get(key);

      if (data == null) {
        print('No cached stores feed found for user: $userId');
        return null;
      }

      if (data is! List) {
        print('Invalid data type in Hive: ${data.runtimeType}');
        return null;
      }

      final List<GetProductData> storesProductsList = data
          .map((json) => GetProductData.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      print('Loaded ${storesProductsList.length} stores feed items for user: $userId');
      return storesProductsList;
    } catch (e) {
      print('Error loading stores feed: $e');
      return null;
    }
  }

  /// All Stores Services
  Future<bool> saveAllStoreServices(
      List<GetServiceModel> allStoresServicesData,
      String userId,
      ) async {
    try {
      final box = Hive.box(_savedAllNearByStoreService);
      final String key = 'user_$userId';

      final List<Map<String, dynamic>> jsonList =
      allStoresServicesData.map((item) => item.toJson()).toList();

      await box.put(key, jsonList);

      print('Saved ${jsonList.length} stores feed items for user: $userId');
      return true;
    } catch (e) {
      print('Error saving stores feed: $e');
      return false;
    }
  }

  Future<List<GetServiceModel>?> getAllStoreServices(String userId) async {
    try {
      final box = Hive.box(_savedAllNearByStoreService);
      final String key = 'user_$userId';

      final data = box.get(key);

      if (data == null) {
        print('No cached stores feed found for user: $userId');
        return null;
      }

      if (data is! List) {
        print('Invalid data type in Hive: ${data.runtimeType}');
        return null;
      }

      final List<GetServiceModel> storesServicesList = data
          .map((json) => GetServiceModel.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      print('Loaded ${storesServicesList.length} stores feed items for user: $userId');
      return storesServicesList;
    } catch (e) {
      print('Error loading stores feed: $e');
      return null;
    }
  }

  /// All Stores Food Services
  Future<bool> saveAllStoreFoodServices(
        List<GetFoodDetailsModel> allStoresFoodServicesData,
        String userId,
        ) async {
      try {
        final box = Hive.box(_savedAllNearByStoresFoodServices);
        final String key = 'user_$userId';

        final List<Map<String, dynamic>> jsonList =
        allStoresFoodServicesData.map((item) => item.toJson()).toList();

        await box.put(key, jsonList);

        print('Saved ${jsonList.length} stores feed items for user: $userId');
        return true;
      } catch (e) {
        print('Error saving stores feed: $e');
        return false;
      }
    }

  List<GetFoodDetailsModel>? getAllStoreFoodServices(String userId) {
      try {
        final box = Hive.box(_savedAllNearByStoresFoodServices);
        final String key = 'user_$userId';

        final data = box.get(key);

        if (data == null) {
          print('No cached stores feed found for user: $userId');
          return null;
        }

        if (data is! List) {
          print('Invalid data type in Hive: ${data.runtimeType}');
          return null;
        }

        final List<GetFoodDetailsModel> storesFoodServicesList = data
            .map((json) => GetFoodDetailsModel.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
            .toList();

        print('Loaded ${storesFoodServicesList.length} stores feed items for user: $userId');
        return storesFoodServicesList;
      } catch (e) {
        print('Error loading stores feed: $e');
        return null;
      }
    }


  // ── Account-agnostic master lists ────────────────────────────────────────
  // The onboarding business categories and profession types are the SAME for
  // every user — they are the platform's catalog, not anybody's data. They are
  // also the two lists the app cannot draw its onboarding screens without.

  /// Raw snapshot of the master lists, to be handed back after a logout wipe.
  ///
  /// Logout deletes Hive wholesale ([LogoutHelper.clearAllLocalData]) because
  /// almost everything in it belongs to the account that is leaving. These two
  /// boxes don't: throwing them away only cost the next user two API calls and
  /// a shimmer on the first screen they see, and cost anyone who signs out
  /// without a connection the ability to sign in at all — the account-type
  /// screen has nothing to list.
  ///
  /// Deliberately RAW (the same `List<Map>` that went in): nothing is parsed,
  /// so a model that has changed shape since it was cached cannot make this
  /// throw in the middle of a logout, and restoring is a straight write-back.
  ///
  /// Returns an empty map when the boxes aren't open or hold nothing, which
  /// restores as a no-op.
  static Map<String, dynamic> readSharedCatalogSnapshot() {
    final snapshot = <String, dynamic>{};
    void take(String boxName, String key) {
      try {
        if (!Hive.isBoxOpen(boxName)) return;
        final value = Hive.box(boxName).get(key);
        if (value != null) snapshot['$boxName|$key'] = value;
      } catch (_) {}
    }

    take(_savedBusinessCategoryBox, 'category');
    take(_savedProfessionTypeBox, 'profession');
    return snapshot;
  }

  /// Writes a [readSharedCatalogSnapshot] back. Call AFTER the boxes have been
  /// reopened; anything that fails is simply left to the next network fetch.
  static Future<void> restoreSharedCatalogSnapshot(
      Map<String, dynamic> snapshot) async {
    if (snapshot.isEmpty) return;
    for (final entry in snapshot.entries) {
      try {
        final parts = entry.key.split('|');
        if (parts.length != 2) continue;
        final box = Hive.isBoxOpen(parts[0])
            ? Hive.box(parts[0])
            : await Hive.openBox(parts[0]);
        await box.put(parts[1], entry.value);
      } catch (_) {}
    }
  }

  /// Save list of categories
  Future<void> saveCategoryList(List<CategoryData> categories) async {
    final box = Hive.box(_savedBusinessCategoryBox);

    final String key = 'category';

    final List<Map<String, dynamic>> jsonList = categories.map((item) => item.toJson()).toList();

    await box.put(key, jsonList);
  }

  /// Get all saved categories
  List<CategoryData>? getAllCategories() {
    try {

      final box = Hive.box(_savedBusinessCategoryBox);
      final String key = 'category';
      final data = box.get(key);

      if (data == null) {
        print('No cached category found');
        return null;
      }

      if (data is! List) {
        print('Invalid data type in Hive: ${data.runtimeType}');
        return null;
      }

      final List<CategoryData> businessCategoryList = data
          .map((json) => CategoryData.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      print('Loaded ${businessCategoryList.length} business categories');

      return businessCategoryList;

    }catch (e) {
      print('Error loading business categories: $e');
      return null;
    }
  }

  /// Save the master list of profession types. Save BEFORE the controller
  /// runs `updateIndividualCategoriesFromApi(...)` so each item's
  /// `individualProfileType` enum is still null at serialize time â€” the
  /// enum is rebuilt in memory from `profileType` on every load and is
  /// not part of the API payload.
  Future<void> saveProfessionList(List<ProfessionTypeData> professions) async {
    final box = Hive.box(_savedProfessionTypeBox);
    final String key = 'profession';
    final List<Map<String, dynamic>> jsonList =
        professions.map((item) => item.toJson()).toList();
    await box.put(key, jsonList);
  }

  /// Get the cached master list of profession types. Returns null when no
  /// cache exists yet (first launch after install) or on a parse error,
  /// in which case callers should fall back to the network.
  List<ProfessionTypeData>? getAllProfessions() {
    try {
      final box = Hive.box(_savedProfessionTypeBox);
      final String key = 'profession';
      final data = box.get(key);

      if (data == null) {
        print('No cached profession list found');
        return null;
      }

      if (data is! List) {
        print('Invalid data type in Hive: ${data.runtimeType}');
        return null;
      }

      final List<ProfessionTypeData> professions = data
          .map((json) => ProfessionTypeData.fromJson(
              jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      print('Loaded ${professions.length} profession types');
      return professions;
    } catch (e) {
      print('Error loading profession list: $e');
      return null;
    }
  }

  /// Save all admin videos
  Future<void> saveAllAdminVideos(List<AdminVideoData> videos) async {
    final box = Hive.box(_savedAdminVideosBox);

    final String key = 'videoData';

    final List<Map<String, dynamic>> jsonList = videos.map((item) => item.toJson()).toList();

    await box.put(key, jsonList);
  }

  /// Get all admin videos
  List<AdminVideoData>? getAllSavedAdminVideos() {
    try {

      final box = Hive.box(_savedAdminVideosBox);
      final String key = 'videoData';
      final data = box.get(key);

      if (data == null) {
        print('No cached video data found');
        return null;
      }

      if (data is! List) {
        print('Invalid data type in Hive: ${data.runtimeType}');
        return null;
      }

      final List<AdminVideoData> videos = data
          .map((json) => AdminVideoData.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      print('Loaded ${videos.length} videos Data');

      return videos;

    }catch (e) {
      print('Error loading videos data: $e');
      return null;
    }
  }

  /// Save all nested categories (Grocery)
  Future<void> saveGroceryNestedCategories(String groceryCategoryKey, List<GroceryNestedCategoryModel> nestedCategories) async {
    final box = Hive.box(_savedGroceryNestedCategoryBox);

    final List<Map<String, dynamic>> jsonList = nestedCategories.map((item) => item.toJson()).toList();

    await box.put(groceryCategoryKey, jsonList);
  }

  /// Get all nested categories (Grocery)
  List<GroceryNestedCategoryModel>? getGroceryNestedCategories(String groceryCategoryKey) {
    try {

      final box = Hive.box(_savedGroceryNestedCategoryBox);
      final data = box.get(groceryCategoryKey);

      if (data == null) {
        print('No cached nested categories data found');
        return null;
      }

      if (data is! List) {
        print('Invalid data type in Hive: ${data.runtimeType}');
        return null;
      }

      final List<GroceryNestedCategoryModel> nestedCategories = data
          .map((json) => GroceryNestedCategoryModel.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      print('Loaded ${nestedCategories.length} Nested Category Data');

      return nestedCategories;

    }catch (e) {
      print('Error loading videos data: $e');
      return null;
    }
  }

  /// Save all nested categories (Medical)
  Future<void> saveMedicalNestedCategories(List<MedicalNestedCategoryModel> nestedCategories) async {
    try {
      final box = Hive.isBoxOpen(_savedMedicalNestedCategoryBox)
          ? Hive.box(_savedMedicalNestedCategoryBox)
          : await Hive.openBox(_savedMedicalNestedCategoryBox);
      const String key = 'medicalData';

      final List<Map<String, dynamic>> jsonList = nestedCategories.map((item) => item.toJson()).toList();

      await box.put(key, jsonList);
    } catch (e) {
      print('Error saving medical nested categories: $e');
    }
  }

  /// Save all nested categories (Product)
  Future<void> saveProductNestedCategories(List<ProductNestedCategoryResponse> nestedCategories) async {
    try {
      final box = Hive.isBoxOpen(_savedProductNestedCategoryBox)
          ? Hive.box(_savedProductNestedCategoryBox)
          : await Hive.openBox(_savedProductNestedCategoryBox);
      final String key = 'productData';

      final List<Map<String, dynamic>> jsonList = nestedCategories.map((item) => item.toJson()).toList();

      await box.put(key, jsonList);
    } catch (e) {
      print('Error saving product nested categories: $e');
    }
  }

  /// Get all nested categories (Product)
  List<ProductNestedCategoryResponse>? getProductNestedCategories() {
    try {
      if (!Hive.isBoxOpen(_savedProductNestedCategoryBox)) return null;
      final box = Hive.box(_savedProductNestedCategoryBox);
      const String key = 'productData';
      final data = box.get(key);

      if (data == null) return null;
      if (data is! List) return null;

      final List<ProductNestedCategoryResponse> nestedCategories = data
          .map((json) => ProductNestedCategoryResponse.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      return nestedCategories;
    } catch (e) {
      print('Error loading product nested categories: $e');
      return null;
    }
  }

  /// Get all nested categories (Medical)
  List<MedicalNestedCategoryModel>? getMedicalNestedCategories() {
    try {
      if (!Hive.isBoxOpen(_savedMedicalNestedCategoryBox)) return null;
      final box = Hive.box(_savedMedicalNestedCategoryBox);
      const String key = 'medicalData';
      final data = box.get(key);

      if (data == null) {
        print('No cached nested categories data found');
        return null;
      }

      if (data is! List) {
        print('Invalid data type in Hive: ${data.runtimeType}');
        return null;
      }

      final List<MedicalNestedCategoryModel> nestedCategories = data
          .map((json) => MedicalNestedCategoryModel.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      print('Loaded ${nestedCategories.length} Nested Category Data');

      return nestedCategories;

    }catch (e) {
      print('Error loading medical data: $e');
      return null;
    }
  }

}