// controllers/video_cache_manager.dart
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoCacheManager {
  static final VideoCacheManager _instance = VideoCacheManager._internal();
  factory VideoCacheManager() => _instance;
  VideoCacheManager._internal();

  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, int> _refCounts = {};
  final Map<String, Future<VideoPlayerController>?> _initializing = {};

  /// Get cached or new controller
  Future<VideoPlayerController> getController(String url) async {
    // Increase reference count
    _refCounts[url] = (_refCounts[url] ?? 0) + 1;

    // Already created?
    if (_controllers.containsKey(url)) {
      final controller = _controllers[url]!;

      // Ensure healthy
      if (!controller.value.isInitialized || controller.value.hasError) {
        debugPrint("🔁 Reinitializing broken controller: $url");
        await _reinitialize(url);
      }

      return controller;
    }

    return _initialize(url);
  }

  Future<VideoPlayerController> _initialize(String url) async {
    if (_initializing[url] != null) {
      return _initializing[url]!;
    }

    final future = Future(() async {
      debugPrint("🎬 Initializing new controller: $url");

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions:  VideoPlayerOptions(
          allowBackgroundPlayback: true,
          mixWithOthers: true,
        ),
      );

      try {
        await controller.initialize();
      } catch (e) {
        debugPrint("❌ Initialization failed for $url → $e");
        controller.dispose();
        _initializing[url] = null;
        rethrow;
      }

      controller.setLooping(true);
      _controllers[url] = controller;
      _initializing[url] = null;

      return controller;
    });

    _initializing[url] = future;
    return future;
  }

  Future<void> _reinitialize(String url) async {
    if (!_controllers.containsKey(url)) return;

    final old = _controllers[url];
    old?.dispose();
    _controllers.remove(url);

    await _initialize(url);
  }

  /// Release controller only when no active references
  void releaseController(String url) {
    if (!_refCounts.containsKey(url)) return;

    _refCounts[url] = (_refCounts[url]! - 1).clamp(0, 9999);

    if (_refCounts[url] == 0) {
      debugPrint("🗑 Disposing unused controller: $url");
      _controllers[url]?.dispose();
      _controllers.remove(url);
      _refCounts.remove(url);
    }
  }

  /// Cleanup whole cache (e.g., when exiting page)
  void disposeAll() {
    debugPrint("🧹 Disposing ALL video controllers");

    for (var controller in _controllers.values) {
      controller.dispose();
    }

    _controllers.clear();
    _refCounts.clear();
    _initializing.clear();
  }
}


/*
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
}*/
