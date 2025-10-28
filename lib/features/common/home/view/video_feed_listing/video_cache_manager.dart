// controllers/video_cache_manager.dart
import 'package:video_player/video_player.dart';

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
