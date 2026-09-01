import 'dart:convert';

import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:hive/hive.dart';

class HomeCacheService {
  static const String _postsCacheBox = 'home_posts_cache';
  static const String _videosCacheBox = 'home_videos_cache';
  static const String _shortsCacheBox = 'home_shorts_cache';
  static const String _lastFetchTimeKey = 'home_last_fetch_time';
  static const Duration _cacheExpiryDuration = Duration(days: 1);

  String get postsCacheBox => _postsCacheBox;

  static final HomeCacheService _instance = HomeCacheService._internal();
  factory HomeCacheService() => _instance;
  HomeCacheService._internal();

  /// Initialize Hive boxes
  static Future<void> init() async {
    await Hive.openBox(_postsCacheBox);
    await Hive.openBox(_videosCacheBox);
    await Hive.openBox(_shortsCacheBox);
    await Hive.openBox('cache_metadata');
  }

  /// Cache posts data
  Future<void> cachePosts(List<Post> posts) async =>
      _write(_postsCacheBox, 'posts', posts.map((p) => p.toJson()));

  /// Cache videos data
  Future<void> cacheVideos(List<ShortFeedItem> videos) async =>
      _write(_videosCacheBox, 'videos', videos.map((v) => v.toJson()));

  /// Cache shorts data
  Future<void> cacheShorts(List<ShortFeedItem> shorts) async =>
      _write(_shortsCacheBox, 'shorts', shorts.map((s) => s.toJson()));

  /// Writes one cache entry as a **JSON string**.
  ///
  /// Not as a raw map, which is what this used to do: Hive reads a stored map
  /// back as `Map<dynamic, dynamic>`, and every model parser here takes
  /// `Map<String, dynamic>`. So the nested objects inside a cached post or reel
  /// failed their cast on the way out, the read threw, the catch swallowed it
  /// and the caller saw a plain cache MISS — every time. The cache was being
  /// written and never once served, which is why Feed and Bites still opened on
  /// a spinner despite being written cache-first.
  ///
  /// A JSON string round-trips exactly, at the cost of an encode/decode that is
  /// trivial next to a network round trip.
  ///
  /// Stores exactly what it is handed — there is no cap here any more. The
  /// amount cached is decided by the PAGE the caller fetched (Bites requests 20
  /// per page, the post feeds 20), so a second number in this file could only
  /// ever drift out of step with it and silently truncate a page. What gets
  /// restored is now precisely one fetch, which is also what makes it
  /// predictable: the user sees what they would have seen had the request
  /// already returned.
  Future<void> _write(
      String boxName, String key, Iterable<Map<String, dynamic>> items) async {
    try {
      final list = items.toList();
      if (list.isEmpty) return;
      await Hive.box(boxName).put(
        key,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': list,
        }),
      );
      await _updateLastFetchTime();
    } catch (e) {
      print('Error caching $key: $e');
    }
  }

  /// Get cached posts
  Future<List<Post>?> getCachedPosts() async =>
      _read(_postsCacheBox, 'posts', Post.fromJson);

  /// Get cached videos
  Future<List<ShortFeedItem>?> getCachedVideos() async =>
      _read(_videosCacheBox, 'videos', ShortFeedItem.fromJson);

  /// Get cached shorts
  Future<List<ShortFeedItem>?> getCachedShorts() async =>
      _read(_shortsCacheBox, 'shorts', ShortFeedItem.fromJson);

  /// Cached shorts read **without an await**, or null when the box isn't open
  /// yet, on a miss, on an expired entry or on a parse error.
  ///
  /// Hive's `box.get` is synchronous once the box is open, and [init] opens
  /// these boxes at boot — so a screen can hydrate inside `initState` and paint
  /// its very first frame with content. The awaited [getCachedShorts] only ever
  /// cost frames, and a shimmer that flashes for two frames on every cold open
  /// is exactly what makes a cache-first screen still look like it is loading.
  ///
  /// Unlike its awaited twin this never clears an expired entry — it cannot
  /// await the write. The next awaited read does that.
  List<ShortFeedItem>? getCachedShortsSync() =>
      _readSync(_shortsCacheBox, 'shorts', ShortFeedItem.fromJson);

  /// Cached posts read without an await. See [getCachedShortsSync].
  List<Post>? getCachedPostsSync() =>
      _readSync(_postsCacheBox, 'posts', Post.fromJson);

  /// The awaited read: same parse as [_readSync], plus it drops an entry that
  /// is expired or unreadable so the next open doesn't retry it.
  Future<List<T>?> _read<T>(
      String boxName, String key, T Function(Map<String, dynamic>) parse) async {
    final parsed = _readSync(boxName, key, parse);
    if (parsed != null) return parsed;
    try {
      if (Hive.isBoxOpen(boxName) && Hive.box(boxName).get(key) != null) {
        await clearCache(boxName);
      }
    } catch (_) {}
    return null;
  }

  List<T>? _readSync<T>(
      String boxName, String key, T Function(Map<String, dynamic>) parse) {
    try {
      if (!Hive.isBoxOpen(boxName)) return null;
      final raw = Hive.box(boxName).get(key);
      // Entries written in the old raw-map format are treated as a miss: they
      // come back dynamic-keyed and can't be parsed. The refetch they trigger
      // rewrites them in the JSON-string format, so this self-heals once.
      if (raw is! String) return null;
      final cacheData = jsonDecode(raw);
      if (cacheData is! Map) return null;
      if (_isCacheExpired(cacheData['timestamp'] as int)) return null;
      final data = cacheData['data'] as List<dynamic>;
      final parsed = data
          .map((e) => parse(Map<String, dynamic>.from(e as Map)))
          .toList();
      return parsed.isEmpty ? null : parsed;
    } catch (e) {
      return null;
    }
  }

  /// Check if cache is expired
  bool _isCacheExpired(int timestamp) {
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime) > _cacheExpiryDuration;
  }

  /// Update last fetch time
  Future<void> _updateLastFetchTime() async {
    final box = Hive.box('cache_metadata');
    await box.put(_lastFetchTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get last fetch time
  Future<DateTime?> getLastFetchTime() async {
    final box = Hive.box('cache_metadata');
    final timestamp = box.get(_lastFetchTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Clear specific cache
  Future<void> clearCache(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await Hive.box(_postsCacheBox).clear();
    await Hive.box(_videosCacheBox).clear();
    await Hive.box(_shortsCacheBox).clear();
    await Hive.box('cache_metadata').clear();
  }

  /// Check if any cache exists
  Future<bool> hasAnyCache() async {
    final postsBox = Hive.box(_postsCacheBox);
    final videosBox = Hive.box(_videosCacheBox);
    final shortsBox = Hive.box(_shortsCacheBox);
    
    return postsBox.isNotEmpty || videosBox.isNotEmpty || shortsBox.isNotEmpty;
  }

  /// Get cache info for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    final postsBox = Hive.box(_postsCacheBox);
    final videosBox = Hive.box(_videosCacheBox);
    final shortsBox = Hive.box(_shortsCacheBox);
    final lastFetchTime = await getLastFetchTime();
    
    return {
      'posts_cache_exists': postsBox.isNotEmpty,
      'videos_cache_exists': videosBox.isNotEmpty,
      'shorts_cache_exists': shortsBox.isNotEmpty,
      'last_fetch_time': lastFetchTime?.toIso8601String(),
      'cache_expiry_duration': _cacheExpiryDuration.inHours,
    };
  }

  /// Get cache size in bytes
  Future<Map<String, int>> getCacheSizes() async {
    final postsBox = Hive.box(_postsCacheBox);
    final videosBox = Hive.box(_videosCacheBox);
    final shortsBox = Hive.box(_shortsCacheBox);
    
    return {
      'posts_size': postsBox.length,
      'videos_size': videosBox.length,
      'shorts_size': shortsBox.length,
    };
  }

  /// Preload cache for better performance
  Future<void> preloadCache() async {
    try {
      // Preload all cache boxes
      await getCachedPosts();
      await getCachedVideos();
      await getCachedShorts();
      print('Cache preloaded successfully');
    } catch (e) {
      print('Error preloading cache: $e');
    }
  }
}
