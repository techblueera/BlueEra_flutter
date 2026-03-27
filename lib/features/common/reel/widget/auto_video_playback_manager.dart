import 'dart:async';
import 'package:BlueEra/core/services/screen_service.dart';
import 'package:BlueEra/features/common/feed/controller/video_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class SimplePriorityVideoManager extends GetxController {
  VideoPlayerController? _controller;
  final currentIndex = (-1).obs;
  final ValueNotifier<bool> isMuted = ValueNotifier<bool>(true);
  final Map<String, int> playCount = {};
  RxBool showReplayOverlay = false.obs;

  // Simple tracking
  final RxMap<String, double> visibleVideos = <String, double>{}.obs;
  final RxMap<String, String> videoUrls = <String, String>{}.obs;
  final RxBool isScrolling = false.obs;
  Timer? _scrollStopTimer;
  Timer? _playDelayTimer;
  String? _currentPriorityVideo;

  VideoPlayerController? get controller => _controller;


  void updateVideoVisibility(
      String videoId, String videoUrl, double visibilityFraction) {
    if (visibilityFraction >= 0.7) {
      visibleVideos[videoId] = visibilityFraction;
      videoUrls[videoId] = videoUrl;
    } else {
      visibleVideos.remove(videoId);
      videoUrls.remove(videoId);
    }

    if (!isScrolling.value) {
      _checkAndPlayTopVideo();
    }
    if (currentIndex.value != videoId.hashCode) {
      playCount[videoId] = 0; // reset video count
    }
    if (currentIndex.value != videoId.hashCode) {
      playCount[videoId] = 0; // reset video count
    }
  }

  void _checkAndPlayTopVideo() {
    if (visibleVideos.isEmpty) {
      _pauseCurrentVideo();
      return;
    }

    // Find video with highest visibility
    String? topVideoId;
    double maxVisibility = 0;

    visibleVideos.forEach((videoId, visibility) {
      if (visibility > maxVisibility) {
        maxVisibility = visibility;
        topVideoId = videoId;
      }
    });

    if (topVideoId != null && topVideoId != _currentPriorityVideo) {
      _currentPriorityVideo = topVideoId;
      _scheduleVideoPlay(topVideoId!);
    }
  }

  void _scheduleVideoPlay(String videoId) {
    _playDelayTimer?.cancel();
    _playDelayTimer = Timer(const Duration(milliseconds: 600), () {
      if (!isScrolling.value && _currentPriorityVideo == videoId) {
        playVideo(videoId);
        _scheduleVideoView(videoId);
        // Future.delayed(const Duration(seconds: 5), () {
        //   // videoView(videoId: videoController.videoFeedItem!.video!.id ?? '0');
        // });
      }
    });
  }

  void _scheduleVideoView(String videoId) {
    if (Get.isRegistered<VideoController>()) {
    } else {}
    // Future.delayed(const Duration(seconds: 5), () {
    //   videoController?.videoView(videoId: videoId);
    // });
  }

  // _scheduleVideoView();

  Future<void> playVideo(String videoId) async {
    final videoUrl = videoUrls[videoId];
    if (videoUrl == null) {
      print('Video URL not found for: $videoId');
      return;
    }

    print('Playing video: $videoId with URL: $videoUrl');

    try {
      // Dispose previous controller
      if (_controller != null) {
        await _controller!.pause();
        await _controller!.dispose();
        _controller = null;
      }

      // videoUrl.toLowerCase().endsWith('.m3u8');
      showReplayOverlay = false.obs;
      // Create new controller
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true, allowBackgroundPlayback: true),
        // videoPlayerOptions: isHls
        //     ? VideoPlayerOptions(
        //     mixWithOthers: true,
        //     allowBackgroundPlayback: true
        // )
        //     : null,
      );
      await _controller!.initialize();
      playCount[videoId] = 0;
      _controller?.addListener(() {
        final controller = _controller;
        if (controller == null) return;

        final position = controller.value.position;
        final duration = controller.value.duration;

        if (duration.inMilliseconds == 0) return;

        if (position >= duration) {
          final count = playCount[videoId] ?? 0;

          if (count < 1) {
            // Replay once
            playCount[videoId] = count + 1;
            controller.seekTo(Duration.zero);
            controller.play();
          } else {
            // Stop & show overlay
            controller.pause();
            showReplayOverlay.value = true;
          }
        }
      });

      /*  _controller?.addListener(() {

        final controller = _controller;
        if (controller == null) return;

        final position = controller.value.position;
        final duration = controller.value.duration;

        if (duration.inMilliseconds == 0) return; // avoid division crash

        if (position >= duration) {
          final count = playCount[videoId] ?? 0;

          if (count < 1) {
            // Play again (2 total plays → count 0,1)
            playCount[videoId] = count + 1;
            controller.seekTo(Duration.zero);
            controller.play();
          } else {
            controller.pause();
          }
        }
      });*/

      // Set properties
      // await _controller!.setLooping(true);
      await _controller!.setVolume(isMuted.value ? 0 : 1);

      // Play only if still the priority video
      if (_currentPriorityVideo == videoId && !isScrolling.value) {
        await _controller!.play();
        currentIndex.value = videoId.hashCode;
        print('Video started playing: $videoId');
        ScreenService.keepOn();
      }

      update();
    } catch (e) {
      print('Error playing video $videoId: $e');
      currentIndex.value = -1;
    }
  }

  Future<void> _pauseCurrentVideo() async {
    _controller?.pause();
    _currentPriorityVideo = null;
    ScreenService.keepOff();
  }

  /// Pause playback and release the video controller to free GPU/MediaCodec resources.
  /// Called when switching away from the Home tab.
  Future<void> pauseAndRelease() async {
    _playDelayTimer?.cancel();
    _currentPriorityVideo = null;
    visibleVideos.clear();
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }
    currentIndex.value = -1;
    ScreenService.keepOff();
    update();
  }

  void removeVideo(String videoId) {
    visibleVideos.remove(videoId);
    videoUrls.remove(videoId);

    if (_currentPriorityVideo == videoId) {
      _currentPriorityVideo = null;
      _checkAndPlayTopVideo();
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _controller?.setVolume(isMuted.value ? 0 : 1);
  }

  @override
  void onClose() {
    _controller?.pause();
    _controller?.dispose();
    _scrollStopTimer?.cancel();
    _playDelayTimer?.cancel();
    isMuted.dispose();
    ScreenService.keepOff();
    super.onClose();
  }
}
