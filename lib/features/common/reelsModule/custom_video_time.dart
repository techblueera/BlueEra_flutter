import 'dart:io';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:video_player/video_player.dart';

class CustomVideoTime {
  static VideoPlayerController? _videoPlayerController;

  static Future<int?> onGet(String videoPath) async {
    try {
      _videoPlayerController?.dispose();
      _videoPlayerController = null;

      _videoPlayerController = VideoPlayerController.file(File(videoPath));
      await _videoPlayerController?.initialize();
      if (_videoPlayerController!.value.isInitialized) {
        final videoTime = _videoPlayerController?.value.duration.inSeconds;
       logs("Get Video Time => $videoTime");
        return videoTime;
      } else {
        logs("Get Video Time Error => Video Not Initialize");
        return null;
      }
    } catch (e) {
      logs("Get Video Time Error => $e");
      return null;
    }
  }
}
