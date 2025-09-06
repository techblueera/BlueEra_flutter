import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:hive/hive.dart';

class HomeCacheService {
  static const String _postsCacheBox = 'home_posts_cache';
  static const String _videosCacheBox = 'home_videos_cache';
  static const String _shortsCacheBox = 'home_shorts_cache';
  static const String _lastFetchTimeKey = 'home_last_fetch_time';
  static const int _maxCacheItems = 20;
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
  Future<void> cachePosts(List<Post> posts) async {
    try {
      if (posts.isEmpty) return;
      
      final box = Hive.box(_postsCacheBox);
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': posts.take(_maxCacheItems).map((post) => post.toJson()).toList(),
      };
      
      await box.put('posts', cacheData);
      await _updateLastFetchTime();
      print('Posts cached successfully: ${posts.take(_maxCacheItems).length} items');
    } catch (e) {
      print('Error caching posts: $e');
    }
  }

  /// Cache videos data
  Future<void> cacheVideos(List<ShortFeedItem> videos) async {
    try {
      if (videos.isEmpty) return;
      
      final box = Hive.box(_videosCacheBox);
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': videos.take(_maxCacheItems).map((video) => video.toJson()).toList(),
      };
      
      await box.put('videos', cacheData);
      await _updateLastFetchTime();
      print('Videos cached successfully: ${videos.take(_maxCacheItems).length} items');
    } catch (e) {
      print('Error caching videos: $e');
    }
  }

  /// Cache shorts data
  Future<void> cacheShorts(List<ShortFeedItem> shorts) async {
    try {
      if (shorts.isEmpty) return;
      
      final box = Hive.box(_shortsCacheBox);
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': shorts.take(_maxCacheItems).map((short) => short.toJson()).toList(),
      };
      
      await box.put('shorts', cacheData);
      await _updateLastFetchTime();
      print('Shorts cached successfully: ${shorts.take(_maxCacheItems).length} items');
    } catch (e) {
      print('Error caching shorts: $e');
    }
  }

  /// Get cached posts
  Future<List<Post>?> getCachedPosts() async {
    try {
      final box = Hive.box(_postsCacheBox);
      final cacheData = box.get('posts');
      
      if (cacheData == null) return null;
      
      final timestamp = cacheData['timestamp'] as int;
      final data = cacheData['data'] as List<dynamic>;
      
      // Check if cache is expired
      if (_isCacheExpired(timestamp)) {
        await clearCache(_postsCacheBox);
        return null;
      }
      
      // Parse cached posts with better error handling
      try {
        return data.map((json) => Post.fromJson(json)).toList();
      } catch (parseError) {
        print('Error parsing cached posts: $parseError');
        await clearCache(_postsCacheBox);
        return null;
      }
    } catch (e) {
      print('Error getting cached posts: $e');
      await clearCache(_postsCacheBox);
      return null;
    }
  }

  /// Get cached videos
  Future<List<ShortFeedItem>?> getCachedVideos() async {
    try {
      final box = Hive.box(_videosCacheBox);
      final cacheData = box.get('videos');
      
      if (cacheData == null) return null;
      
      final timestamp = cacheData['timestamp'] as int;
      final data = cacheData['data'] as List<dynamic>;
      
      // Check if cache is expired
      if (_isCacheExpired(timestamp)) {
        await clearCache(_videosCacheBox);
        return null;
      }
      
      return data.map((json) => ShortFeedItem.fromJson(json)).toList();
    } catch (e) {
      await clearCache(_videosCacheBox);
      return null;
    }
  }

  /// Get cached shorts
  Future<List<ShortFeedItem>?> getCachedShorts() async {
    try {
      final box = Hive.box(_shortsCacheBox);
      final cacheData = box.get('shorts');
      
      if (cacheData == null) return null;
      
      final timestamp = cacheData['timestamp'] as int;
      final data = cacheData['data'] as List<dynamic>;
      
      // Check if cache is expired
      if (_isCacheExpired(timestamp)) {
        await clearCache(_shortsCacheBox);
        return null;
      }
      
      return data.map((json) => ShortFeedItem.fromJson(json)).toList();
    } catch (e) {
      await clearCache(_shortsCacheBox);
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
      'max_cache_items': _maxCacheItems,
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
