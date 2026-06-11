import 'dart:convert';
import 'dart:developer';
import 'package:BlueEra/core/api/model/admin_video_model_response.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
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

class HiveServices{
  static const String _savedPosts = 'savedPosts';
  static const String _savedVideos = 'savedVideos';
  static const String _savedAllNearByStoreFeed = 'savedAllNearByStoreFeed';
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

  /// Initialize Hive boxes
  static Future<void> init() async {
    await Hive.openBox(_savedPosts);
    await Hive.openBox(_savedVideos);
    await Hive.openBox(_savedAllNearByStoreFeed);
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
  }

  static List<String> get allBoxNames => [
    _savedPosts,
    _savedVideos,
    _savedAllNearByStoreFeed,
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

  Future<void> saveFoodSuperCategoriesRaw(List<dynamic> raw) =>
      _putRawList(_savedFoodNestedCategoryBox, 'foodSuper', raw);
  List<dynamic>? getFoodSuperCategoriesRaw() =>
      _getRawList(_savedFoodNestedCategoryBox, 'foodSuper');

  Future<void> saveGrocerySuperCategoriesRaw(List<dynamic> raw) =>
      _putRawList(_savedGroceryNestedCategoryBox, 'grocerySuper', raw);
  List<dynamic>? getGrocerySuperCategoriesRaw() =>
      _getRawList(_savedGroceryNestedCategoryBox, 'grocerySuper');

  Future<void> saveProductSuperCategoriesRaw(List<dynamic> raw) =>
      _putRawList(_savedProductNestedCategoryBox, 'productSuperRaw', raw);
  List<dynamic>? getProductSuperCategoriesRaw() =>
      _getRawList(_savedProductNestedCategoryBox, 'productSuperRaw');

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
  Future<bool> saveAllStore(
      List<GetAllStoreResModel> allStoresData,
      String userId,
      ) async {
    try {
      final box = Hive.box(_savedAllNearByStore);
      final String key = 'user_$userId'; // Better key naming

      // Convert all items to JSON list
      final List<Map<String, dynamic>> jsonList =
      allStoresData.map((item) => item.toJson()).toList();

      await box.put(key, jsonList);

      print('Saved ${jsonList.length} stores feed items for user: $userId');
      return true;
    } catch (e) {
      print('Error saving stores feed: $e');
      return false;
    }
  }

  Future<List<GetAllStoreResModel>?> getAllStore(String userId) async {
    try {
      final box = Hive.box(_savedAllNearByStore);
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

      final List<GetAllStoreResModel> storesList = data
          .map((json) => GetAllStoreResModel.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>))
          .toList();

      print('Loaded ${storesList.length} stores feed items for user: $userId');
      return storesList;
    } catch (e) {
      print('Error loading stores feed: $e');
      return null;
    }
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
    final box = Hive.box(_savedMedicalNestedCategoryBox);
    final String key = 'medicalData';

    final List<Map<String, dynamic>> jsonList = nestedCategories.map((item) => item.toJson()).toList();

    await box.put(key, jsonList);
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

      final box = Hive.box(_savedMedicalNestedCategoryBox);
      final String key = 'medicalData';
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