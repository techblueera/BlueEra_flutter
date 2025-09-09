import 'package:hive/hive.dart';

/// A generic, model-free cache service over Hive.
/// - Stores raw Map/List JSON with a timestamp
/// - Supports expiry and simple get/set/clear helpers
/// - No Hive adapters required
class GenericCacheService {
  static const String _metadataBoxName = 'generic_cache_metadata';

  static final GenericCacheService _instance = GenericCacheService._internal();
  factory GenericCacheService() => _instance;
  GenericCacheService._internal();

  /// Call once during app init (after Hive.initFlutter())
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_metadataBoxName)) {
      await Hive.openBox(_metadataBoxName);
    }
  }

  /// Ensure a cache box exists and is open
  Future<Box> _ensureBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// Put any JSON-serializable data (Map/List/primitive) with timestamp
  Future<void> putJson({
    required String boxName,
    required String key,
    required Object? json,
  }) async {
    final box = await _ensureBox(boxName);
    final payload = <String, Object?>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': json,
    };
    await box.put(key, payload);
  }

  /// Get JSON payload if present and not expired. Returns null if missing/expired/invalid.
  Future<T?> getJson<T>({
    required String boxName,
    required String key,
    Duration? expiry,
  }) async {
    final box = await _ensureBox(boxName);
    final cached = box.get(key);
    if (cached == null || cached is! Map) return null;

    final timestamp = cached['timestamp'];
    final data = cached['data'];

    if (timestamp is! int) return null;
    if (expiry != null && _isExpired(timestamp, expiry)) {
      await box.delete(key);
      return null;
    }

    try {
      return data as T?;
    } catch (_) {
      return null;
    }
  }

  /// Convenience: put a List of JSON maps (e.g., List<Map<String, dynamic>>)
  Future<void> putJsonList({
    required String boxName,
    required String key,
    required List<Object?> list,
  }) async {
    await putJson(boxName: boxName, key: key, json: list);
  }

  /// Convenience: get a List from cache
  Future<List<T>?> getJsonList<T>({
    required String boxName,
    required String key,
    Duration? expiry,
  }) async {
    final result = await getJson<Object?> (
      boxName: boxName,
      key: key,
      expiry: expiry,
    );
    if (result is List) {
      try {
        return result.cast<T>();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Remove a single key from a box
  Future<void> remove({required String boxName, required String key}) async {
    final box = await _ensureBox(boxName);
    await box.delete(key);
  }

  /// Clear all keys from a specific box
  Future<void> clearBox(String boxName) async {
    final box = await _ensureBox(boxName);
    await box.clear();
  }

  /// Check if a key exists in a box (and not expired if [expiry] provided)
  Future<bool> exists({
    required String boxName,
    required String key,
    Duration? expiry,
  }) async {
    final box = await _ensureBox(boxName);
    if (!box.containsKey(key)) return false;
    if (expiry == null) return true;

    final cached = box.get(key);
    if (cached is! Map) return false;
    final timestamp = cached['timestamp'];
    if (timestamp is! int) return false;
    return !_isExpired(timestamp, expiry);
  }

  bool _isExpired(int timestampMs, Duration expiry) {
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return DateTime.now().difference(cachedAt) > expiry;
  }
}



