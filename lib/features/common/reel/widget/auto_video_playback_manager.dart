import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class SimplePriorityVideoManager extends GetxController {
  VideoPlayerController? _controller;
  final currentIndex = (-1).obs;
  final ValueNotifier<bool> isMuted = ValueNotifier<bool>(true);

  // Simple tracking
  final RxMap<String, double> visibleVideos = <String, double>{}.obs;
  final RxMap<String, String> videoUrls = <String, String>{}.obs;
  final RxBool isScrolling = false.obs;
  Timer? _scrollStopTimer;
  Timer? _playDelayTimer;
  String? _currentPriorityVideo;

  VideoPlayerController? get controller => _controller;

  void onScrollStart() {
    isScrolling.value = true;
    _playDelayTimer?.cancel();

    // Pause current video during scroll
    if (_controller?.value.isPlaying == true) {
      _controller?.pause();
    }

    _scrollStopTimer?.cancel();
    _scrollStopTimer = Timer(const Duration(milliseconds: 500), () {
      isScrolling.value = false;
      _checkAndPlayTopVideo();
    });
  }

  void updateVideoVisibility(String videoId, String videoUrl, double visibilityFraction) {
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
        _playVideo(videoId);
      }
    });
  }

  Future<void> _playVideo(String videoId) async {
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

      // Create new controller
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();

      // Set properties
      await _controller!.setLooping(true);
      await _controller!.setVolume(isMuted.value ? 0 : 1);

      // Play only if still the priority video
      if (_currentPriorityVideo == videoId && !isScrolling.value) {
        await _controller!.play();
        currentIndex.value = videoId.hashCode;
        print('Video started playing: $videoId');
      }

      update();
    } catch (e) {
      print('Error playing video $videoId: $e');
      currentIndex.value = -1;
    }
  }

  void _pauseCurrentVideo() {
    _controller?.pause();
    _currentPriorityVideo = null;
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
    super.onClose();
  }
}