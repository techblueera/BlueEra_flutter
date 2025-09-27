import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/widgets/intertitial_ad_service.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class SingleVideoPlayerController extends GetxController {
  // Video controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // Ad service
  final InterstitialAdService _interstitialService = InterstitialAdService();
  String? adUnitId;

  // Observable states
  final RxBool isVideoInitialized = false.obs;
  final RxBool isVideoPlaying = false.obs;
  final RxBool isVideoLoading = true.obs;
  final RxBool isVideoError = false.obs;
  final RxBool isVideoCompleted = false.obs;
  final RxString errorMessage = ' '.obs;


  // Observable to show/hide UI controls
  final RxBool showControls = true.obs;

  // Current video
  ShortFeedItem? _currentVideoItem;

  // Lifecycle flags
  bool _isClosed = false;
  bool _wasPlayingBeforeNav = false;

  // Getters
  InterstitialAdService get interstitialService => _interstitialService;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  ChewieController? get chewieController => _chewieController;
  ShortFeedItem? get currentVideoItem => _currentVideoItem;
  bool get hasController => _chewieController != null;

  Timer? _hideControlsTimer;

  /// Call this whenever you want to show controls
  void showControlsTemporarily() {
    // Show controls
    showControls.value = true;

    // Cancel previous timer
    _hideControlsTimer?.cancel();

    // Hide after 3 seconds
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      showControls.value = false;
    });
  }

  /// User taps video to toggle controls manually
  void toggleControls() {
    if (showControls.value) {
      // Hide immediately
      showControls.value = false;
      _hideControlsTimer?.cancel();
    } else {
      // Show temporarily with auto-hide
      showControlsTemporarily();
    }
  }

  @override
  void onClose() {
    _isClosed = true;
    _hideControlsTimer?.cancel();
    disposeVideo();
    _interstitialService.dispose();
    super.onClose();
  }

  /// Initialize a new video
  Future<void> initializeVideo(
      ShortFeedItem videoItem, {
        bool autoPlay = false,
        bool showAd = true,
        Function? onAdShow,
        Function? onAdClosed,
      }) async {
    if (_isClosed) return;

    try {
      isVideoLoading.value = true;
      isVideoError.value = false;
      isVideoCompleted.value = false;
      errorMessage.value = '';

     String? videoUrl;
      if(GetPlatform.isAndroid){
        videoUrl =
            videoItem.video?.transcodedUrls?.master ?? videoItem.video?.videoUrl;
      }else{
         videoUrl = videoItem.video?.videoUrl;
      }

      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('Video URL is empty or null');
      }

      log('Initializing video: $videoUrl');

      // Dispose old controllers
      await _videoPlayerController?.pause();
      _videoPlayerController?.removeListener(_videoPlayerListener);
      await _videoPlayerController?.dispose();
      _chewieController?.dispose();

      // Create new controllers
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        // videoPlayerOptions: VideoPlayerOptions(
        //   mixWithOthers: true,
        //   allowBackgroundPlayback: false,
        // ),
        // httpHeaders: isHlsUrl(videoUrl) ? {
        //   'Accept': '*/*',
        //   'User-Agent': 'Flutter Video Player',
        //   'Connection': 'keep-alive',
        // } : {},
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        errorBuilder: (context, err) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text('Error playing video', style: TextStyle(color: Colors.red)),
                Text(err, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        },
      );

      _currentVideoItem = videoItem;
      _videoPlayerController!.addListener(_videoPlayerListener);

      isVideoInitialized.value = true;
      isVideoLoading.value = false;

      // Handle ads or autoplay
      if (Platform.isAndroid && showAd) {
        await _handleInterstitialAd(
          onAdShow: onAdShow,
          onAdClosed: () {
            if (!_isClosed && _videoPlayerController != null) play();
            onAdClosed?.call();
          },
        );
      } else if (autoPlay) {
        play();
      }

      log('Video initialized successfully');
    } catch (e) {
      log('Error initializing video: $e');
      isVideoError.value = true;
      errorMessage.value = e.toString();
      isVideoLoading.value = false;
      isVideoInitialized.value = false;
    }
  }

  /// Fixed video player listener
  void _videoPlayerListener() {
    final ctrl = videoPlayerController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    final position = ctrl.value.position;
    final duration = ctrl.value.duration;

    // Skip if duration is not ready
    if (duration <= Duration.zero) return;

    isVideoPlaying.value = ctrl.value.isPlaying;

    // HLS end-of-stream tolerance
    final isHlsEndError = position >= duration - const Duration(seconds: 2);

    if (isHlsEndError) {
      isVideoCompleted.value = true;
      isVideoPlaying.value = false;
      isVideoError.value = false;
      errorMessage.value = '';
      return;
    }

    // Normal completion detection
    if (!ctrl.value.isPlaying && position >= duration - const Duration(milliseconds: 100)) {
      isVideoCompleted.value = true;
      isVideoPlaying.value = false;
      if (isVideoError.value && !ctrl.value.hasError) {
        isVideoError.value = false;
        errorMessage.value = '';
      }
    } else if (position < duration - const Duration(seconds: 2)) {
      isVideoCompleted.value = false;
    }

    // Actual errors (not HLS end error)
    if (ctrl.value.hasError && !isHlsEndError) {
      isVideoError.value = true;
      errorMessage.value = ctrl.value.errorDescription ?? 'Unknown video error';
    } else if (!ctrl.value.hasError) {
      isVideoError.value = false;
      errorMessage.value = '';
    }
  }

  /// Play video
  void play() {
    if (_isClosed || _videoPlayerController == null) return;
    if (_videoPlayerController!.value.isInitialized) {
      _videoPlayerController!.play();
      isVideoPlaying.value = true;
      log('Video play initiated');
    }
  }

  /// Pause video
  void pause() {
    if (_isClosed || _videoPlayerController == null) return;
    if (_videoPlayerController!.value.isInitialized) {
      _videoPlayerController!.pause();
      isVideoPlaying.value = false;
      log('Video paused');
    }
  }

  Future<void> replay() async {
    final ctrl = videoPlayerController;
    if (ctrl == null) return;

    // Reinitialize if controller has error or is uninitialized
    if (!ctrl.value.isInitialized || ctrl.value.hasError) {
      log('Controller error detected, reinitializing video...');
      if (_currentVideoItem != null) {
        await initializeVideo(_currentVideoItem!, autoPlay: true);
      }
      return;
    }

    // Hide overlay
    isVideoCompleted.value = false;

    // Seek to start & play
    await ctrl.seekTo(Duration.zero);
    await ctrl.play();
    isVideoPlaying.value = true;
    showControlsTemporarily();
  }

  // /// Replay video from beginning
  // Future<void> replay() async {
  //   if (videoPlayerController == null || !videoPlayerController!.value.isInitialized) {
  //     print('Replay aborted: videoController is null or not initialized');
  //     print('videoPlayerController: $videoPlayerController');
  //     print('isInitialized: ${videoPlayerController?.value.isInitialized}');
  //     return;
  //   }
  //
  //   // Hide replay overlay immediately
  //   isVideoCompleted.value = false;
  //
  //   // Reset position to start
  //   await videoPlayerController!.seekTo(Duration.zero);
  //
  //   // Play the video
  //   await videoPlayerController!.play();
  //
  //   // Update playing state
  //   isVideoPlaying.value = true;
  //
  //   // Show controls temporarily (optional)
  //   showControlsTemporarily();
  // }

  /// Dispose video and controllers
  void disposeVideo() async {
    try {
      final oldVideo = _videoPlayerController;
      final oldChewie = _chewieController;

      _videoPlayerController = null;
      _chewieController = null;
      _currentVideoItem = null;

      isVideoInitialized.value = false;
      isVideoPlaying.value = false;
      isVideoLoading.value = false;
      isVideoError.value = false;
      errorMessage.value = '';
      isVideoCompleted.value = false;

      if (oldVideo != null) {
        try {
          oldVideo.removeListener(_videoPlayerListener);
        } catch (_) {}
        await oldVideo.pause();
        await oldVideo.dispose();
      }
      oldChewie?.dispose();

      log('Video disposed successfully');
    } catch (e) {
      log('Error disposing video: $e');
    }
  }

  /// Interstitial ad
  Future<void> _handleInterstitialAd({Function? onAdShow, Function? onAdClosed}) async {
    adUnitId = getInterstitialAdUnitId();
    if (adUnitId != null && _interstitialService.shouldShowAdOnThisVisit()) {
      _interstitialService.loadInterstitialAd(
        adUnitId: adUnitId!,
        showWhenLoaded: true,
        onAdShow: () {
          pause();
          onAdShow?.call();
        },
        onAdClosed: () {
          onAdClosed?.call();
        },
      );
    }
  }

  /// Error widget
  Widget getVideoErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
              'Failed to load video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage.value.isNotEmpty
                ? errorMessage.value
                : 'Please check your internet connection',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_currentVideoItem != null) {
                log('Retrying video initialization');
                initializeVideo(_currentVideoItem!);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void pauseForNavigation() {
    _wasPlayingBeforeNav = isVideoPlaying.value;
    pause();
    log('Video paused for navigation - was playing: $_wasPlayingBeforeNav');
  }

  void resumeAfterNavigation() {
    if (_wasPlayingBeforeNav) {
      play();
      log('Video resumed after navigation');
    } else {
      log('Navigation resume skipped (was not playing)');
    }
  }
}