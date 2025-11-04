// controllers/video_cache_manager.dart
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

// class VideoCacheManager {
//   static final VideoCacheManager _instance = VideoCacheManager._internal();
//   factory VideoCacheManager() => _instance;
//   VideoCacheManager._internal();
//
//   final Map<String, _CachedController> _cache = {};
//
//   Future<VideoPlayerController> getController(String url) async {
//     if (_cache.containsKey(url)) {
//       _cache[url]!.refCount++;
//       return _cache[url]!.controller;
//     }
//
//     final controller = VideoPlayerController.networkUrl(Uri.parse(url));
//     await controller.initialize();
//     controller.setLooping(true);
//     _cache[url] = _CachedController(controller);
//     return controller;
//   }
//
//   void releaseController(String url) {
//     final cached = _cache[url];
//     if (cached == null) return;
//     cached.refCount--;
//     if (cached.refCount <= 0) {
//       cached.controller.dispose();
//       _cache.remove(url);
//     }
//   }
// }
//
// class _CachedController {
//   final VideoPlayerController controller;
//   int refCount;
//   _CachedController(this.controller) : refCount = 1;
// }

/*

class VideoCacheManager {
  static final VideoCacheManager _instance = VideoCacheManager._internal();
  factory VideoCacheManager() => _instance;
  VideoCacheManager._internal();

  final Map<String, VideoPlayerController> _cache = {};

  Future<VideoPlayerController> getController(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    controller.setLooping(true);
    _cache[url] = controller;
    return controller;
  }

  void disposeController(String url) {
    _cache[url]?.dispose();
    _cache.remove(url);
  }

  void disposeAll() {
    for (final c in _cache.values) {
      c.dispose();
    }
    _cache.clear();
  }
}
*/


class VideoCacheManager {
  static final VideoCacheManager _instance = VideoCacheManager._internal();
  factory VideoCacheManager() => _instance;
  VideoCacheManager._internal();

  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, int> _refCounts = {}; // Track references

  Future<VideoPlayerController> getController(String url) async {
    // Increment reference count
    _refCounts[url] = (_refCounts[url] ?? 0) + 1;

    if (_controllers.containsKey(url)) {
      final controller = _controllers[url]!;

      // Reinitialize if controller was disposed or has error
      if (!controller.value.isInitialized || controller.value.hasError) {
        debugPrint("Reinitializing controller for: $url");
        await _initializeController(url, controller);
      }

      return controller;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true,
      ),
    );

    await _initializeController(url, controller);
    _controllers[url] = controller;
    return controller;
  }

  Future<void> _initializeController(String url, VideoPlayerController controller) async {
    try {
      await controller.initialize();
      controller.setLooping(true);
    } catch (e) {
      debugPrint("Error initializing video controller for $url: $e");
      _controllers.remove(url);
      rethrow;
    }
  }

  void releaseController(String url) {
    if (!_refCounts.containsKey(url)) return;

    _refCounts[url] = _refCounts[url]! - 1;

    // Only dispose when no more references
    if (_refCounts[url]! <= 0) {
      _refCounts.remove(url);
      if (_controllers.containsKey(url)) {
        _controllers[url]?.dispose();
        _controllers.remove(url);
        debugPrint("Disposed controller for: $url");
      }
    }
  }

  void disposeAll() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _refCounts.clear();
  }
}