import 'dart:async';
import 'package:BlueEra/core/services/screen_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class SimplePriorityVideoManager extends GetxController {
  VideoPlayerController? _controller;
  final currentIndex = (-1).obs;
  final ValueNotifier<bool> isMuted = ValueNotifier<bool>(true);
  final Map<String, int> playCount = {};
  RxBool showReplayOverlay = false.obs;

  final RxMap<String, double> visibleVideos = <String, double>{}.obs;
  final RxMap<String, String> videoUrls = <String, String>{}.obs;
  final RxBool isScrolling = false.obs;
  Timer? _scrollStopTimer;
  Timer? _playDelayTimer;
  Timer? _warmupTimer;
  String? _currentPriorityVideo;

  // Startup warmup guard: prevents ExoPlayer initialization during heavy
  // startup rendering/JIT work, which can block the Android main thread → ANR.
  bool _isWarmedUp = false;

  // Token = videoId of the most recent playVideo call.
  // After every await, if token changed → a newer video was requested → abort.
  String? _playToken;

  VideoPlayerController? get controller => _controller;

  @override
  void onInit() {
    // Allow video auto-play only after 4 seconds from first feed render.
    // This prevents ExoPlayer initialization from competing with startup
    // rendering, which blocks the Android main thread → ANR on slow devices.
    _warmupTimer = Timer(const Duration(seconds: 4), () {
      _isWarmedUp = true;
      _warmupTimer = null;
      // If a priority video was already identified during warmup, play it now.
      if (_currentPriorityVideo != null) {
        _scheduleVideoPlay(_currentPriorityVideo!);
      } else {
        _checkAndPlayTopVideo();
      }
    });
    super.onInit();
  }

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
      playCount[videoId] = 0;
    }
  }

  void _checkAndPlayTopVideo() {
    if (visibleVideos.isEmpty) {
      _pauseCurrentVideo();
      return;
    }

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
    if (!_isWarmedUp) return; // Defer until warmup completes
    _playDelayTimer?.cancel();
    _playDelayTimer = Timer(const Duration(milliseconds: 800), () {
      if (!isScrolling.value && _currentPriorityVideo == videoId) {
        playVideo(videoId);
      }
    });
  }

  Future<void> playVideo(String videoId) async {
    final videoUrl = videoUrls[videoId];
    if (videoUrl == null) return;

    // Set this call's token. Any older in-flight call will detect the mismatch
    // after its next await and self-abort without creating a controller.
    final token = videoId;
    _playToken = token;

    // Capture and clear the shared controller reference immediately so a
    // concurrent call that runs next won't try to dispose the same instance.
    final oldController = _controller;
    _controller = null;

    // Dispose the previous controller (local reference — safe to await)
    if (oldController != null) {
      await oldController.pause();
      await oldController.dispose();
    }

    // Token check: did a newer playVideo call come in while we were disposing?
    if (_playToken != token) return;

    showReplayOverlay.value = false;

    // Create and initialize new controller as a local variable (not yet shared)
    final newController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions:
          VideoPlayerOptions(mixWithOthers: true, allowBackgroundPlayback: true),
    );

    try {
      await newController.initialize().timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('VideoPlayer init timeout'),
      );
    } catch (e) {
      debugPrint('Error initializing video $videoId: $e');
      await newController.dispose();
      currentIndex.value = -1;
      return;
    }

    // Token check: did a newer call come in while we were initializing?
    if (_playToken != token) {
      // This controller is stale — dispose it and let the newer call handle UI
      await newController.dispose();
      return;
    }

    // Safe to make it the shared controller now
    _controller = newController;
    playCount[videoId] = 0;

    _controller!.addListener(() {
      final ctrl = _controller;
      if (ctrl == null) return;

      final position = ctrl.value.position;
      final duration = ctrl.value.duration;
      if (duration.inMilliseconds == 0) return;

      if (position >= duration) {
        final count = playCount[videoId] ?? 0;
        if (count < 1) {
          playCount[videoId] = count + 1;
          ctrl.seekTo(Duration.zero);
          ctrl.play();
        } else {
          ctrl.pause();
          showReplayOverlay.value = true;
        }
      }
    });

    await _controller!.setVolume(isMuted.value ? 0 : 1);
    await _controller!.play();
    currentIndex.value = videoId.hashCode;
    ScreenService.keepOn();
    update();
  }

  Future<void> _pauseCurrentVideo() async {
    _controller?.pause();
    _currentPriorityVideo = null;
    ScreenService.keepOff();
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
    _playToken = null;
    _controller?.pause();
    _controller?.dispose();
    _scrollStopTimer?.cancel();
    _playDelayTimer?.cancel();
    _warmupTimer?.cancel();
    isMuted.dispose();
    ScreenService.keepOff();
    super.onClose();
  }
}
