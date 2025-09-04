import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/widgets/intertitial_ad_service.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';


class SingleVideoPlayerController extends GetxController {
  // Video Player Controllers (current, active)
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // Ad Service
  final InterstitialAdService _interstitialService = InterstitialAdService();
  String? adUnitId;

  // Observable states
  final RxBool isVideoInitialized = false.obs;
  final RxBool isVideoPlaying = false.obs;
  final RxBool isVideoLoading = true.obs;
  final RxBool isVideoError = false.obs;
  final RxString errorMessage = ''.obs;

  // Current video item
  VideoFeedItem? _currentVideoItem;

  // Lifecycle flags
  bool _isClosed = false;
  bool _wasPlayingBeforeNav = false;

  // Getters
  InterstitialAdService get interstitialService => _interstitialService;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  ChewieController? get chewieController => _chewieController;
  VideoFeedItem? get currentVideoItem => _currentVideoItem;
  bool get hasController => _chewieController != null;

  @override
  void onClose() {
    log('onClose');
    _isClosed = true;
    disposeVideo();
    _interstitialService.dispose();
    super.onClose();
  }

  /// Initialize video with the given video item
  Future<void> initializeVideo(
      VideoFeedItem videoItem, {
        bool autoPlay = false,
        bool showAd = true,
        Function? onAdShow,
        Function? onAdClosed,
      }) async {
    if (_isClosed) return;

    try {
      isVideoLoading.value = true;
      isVideoError.value = false;
      errorMessage.value = '';

      final videoUrl = videoItem.video?.videoUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('Video URL is empty or null');
      }

      log('Initializing video: $videoUrl');

      // --- HOT SWAP: build new controllers first ---
      final newVideoCtrl = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await newVideoCtrl.initialize();

      final newChewie = ChewieController(
        videoPlayerController: newVideoCtrl,
        autoPlay: false, // start false so ad can show first
        looping: false,
        showControls: true,
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

      // Listener for play state on the NEW controller
      void listener() {
        if (_isClosed) return;
        final playing = newVideoCtrl.value.isPlaying;
        if (isVideoPlaying.value != playing) {
          isVideoPlaying.value = playing;
        }
        if (newVideoCtrl.value.hasError) {
          isVideoError.value = true;
          errorMessage.value = newVideoCtrl.value.errorDescription ?? 'Unknown video error';
        }
      }
      newVideoCtrl.addListener(listener);

      // --- Swap in the new controllers atomically ---
      final oldVideoCtrl = _videoPlayerController;
      final oldChewie = _chewieController;
      _videoPlayerController = newVideoCtrl;
      _chewieController = newChewie;
      _currentVideoItem = videoItem;

      // Update flags AFTER swap
      isVideoInitialized.value = true;
      isVideoLoading.value = false;

      // Now it's safe to dispose the OLD ones
      if (oldVideoCtrl != null) {
        try {
          oldVideoCtrl.removeListener(_videoPlayerListener); // may not be attached; safe
        } catch (_) {}
        await oldVideoCtrl.dispose();
      }
      if (oldChewie != null) {
         oldChewie.dispose();
      }

      // Keep our reference to the active listener for remove safety
      _attachListenerForActive(newVideoCtrl, listener);

      // Handle ads / autoplay
      if (Platform.isAndroid && showAd) {
        await _handleInterstitialAd(
          onAdShow: onAdShow,
          onAdClosed: () {
            // Only play if still alive and intended
            if (!_isClosed && _videoPlayerController == newVideoCtrl) {
              play();
            }
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

  /// Keep a reference so we can remove listener safely if re-swapped
  void _attachListenerForActive(VideoPlayerController ctrl, VoidCallback listener) {
    // Store the canonical listener on the instance so we can remove it in disposeVideo
    // We’ll reuse the existing remove in disposeVideo() by removing _videoPlayerListener as well.
    // For backward compatibility, still keep _videoPlayerListener working:
    ctrl.addListener(_videoPlayerListener);
  }

  /// Handle interstitial ad display (UNCHANGED)
  Future<void> _handleInterstitialAd({
    Function? onAdShow,
    Function? onAdClosed,
  }) async {
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

  /// Legacy listener kept for compatibility
  void _videoPlayerListener() {
    final ctrl = _videoPlayerController;
    if (ctrl == null) return;
    final wasPlaying = isVideoPlaying.value;
    final nowPlaying = ctrl.value.isPlaying;
    if (wasPlaying != nowPlaying) {
      isVideoPlaying.value = nowPlaying;
    }
    if (ctrl.value.hasError) {
      isVideoError.value = true;
      errorMessage.value = ctrl.value.errorDescription ?? 'Unknown video error';
    }
  }

  /// Play video (guarded)
  void play() {
    final ctrl = _videoPlayerController;
    if (_isClosed || ctrl == null) return;
    if (ctrl.value.isInitialized) {
      ctrl.play();
      isVideoPlaying.value = true;
    }
  }

  /// Pause video (guarded)
  void pause() {
    final ctrl = _videoPlayerController;
    if (_isClosed || ctrl == null) return;
    if (ctrl.value.isInitialized) {
      ctrl.pause();
      isVideoPlaying.value = false;
    }
  }

  /// Toggle play/pause
  void togglePlayPause() {
    final ctrl = _videoPlayerController;
    if (_isClosed || ctrl == null || !ctrl.value.isInitialized) return;
    ctrl.value.isPlaying ? pause() : play();
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    final ctrl = _videoPlayerController;
    if (_isClosed || ctrl == null || !ctrl.value.isInitialized) return;
    await ctrl.seekTo(position);
  }

  /// Current position
  Duration get currentPosition => _videoPlayerController?.value.position ?? Duration.zero;

  /// Total duration
  Duration get totalDuration => _videoPlayerController?.value.duration ?? Duration.zero;

  /// Set volume
  void setVolume(double volume) {
    final ctrl = _videoPlayerController;
    if (_isClosed || ctrl == null || !ctrl.value.isInitialized) return;
    ctrl.setVolume(volume.clamp(0.0, 1.0).toDouble());
  }

  /// Buffering
  bool get isBuffering => _videoPlayerController?.value.isBuffering ?? false;

  /// Aspect ratio
  double? get aspectRatio {
    final ctrl = _videoPlayerController;
    if (ctrl != null && ctrl.value.isInitialized) {
      return ctrl.value.aspectRatio;
    }
    return null;
  }

  /// Dispose current video (only when truly destroying)
  void disposeVideo() async {
    try {
      final oldVideo = _videoPlayerController;
      final oldChewie = _chewieController;

      _videoPlayerController = null;
      _chewieController = null;
      _currentVideoItem = null;

      isVideoInitialized.value = false;
      isVideoPlaying.value = false;
      isVideoLoading.value = false; // keep false: we’re not loading
      isVideoError.value = false;
      errorMessage.value = '';

      if (oldVideo != null) {
        try {
          oldVideo.removeListener(_videoPlayerListener);
        } catch (_) {}
        await oldVideo.pause();
        await oldVideo.dispose();
      }
      if (oldChewie != null) {
        oldChewie.dispose();
      }

      log('Video disposed successfully');
    } catch (e) {
      log('Error disposing video: $e');
    }
  }

  /// Switch to new video (delegates to initialize; uses hot-swap)
  Future<void> switchVideo(
      VideoFeedItem newVideoItem, {
        bool autoPlay = false,
        bool showAd = true,
      }) async {
    log('Switching to new video');
    await initializeVideo(
      newVideoItem,
      autoPlay: autoPlay,
      showAd: showAd,
    );
  }

  /// Pause current video and prepare for navigation
  void pauseForNavigation() {
    _wasPlayingBeforeNav = isVideoPlaying.value;
    pause();
    log('Video paused for navigation');
  }

  /// Resume video after navigation (only if it was playing before)
  void resumeAfterNavigation() {
    if (_wasPlayingBeforeNav) {
      play();
      log('Video resumed after navigation');
    } else {
      log('Navigation resume skipped (was not playing)');
    }
  }

  /// Loading widget
  Widget getVideoLoadingWidget() => const Center(child: CircularProgressIndicator());

  /// Error widget
  Widget getVideoErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            errorMessage.value.isNotEmpty ? errorMessage.value : 'Please check your internet connection',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_currentVideoItem != null) {
                initializeVideo(_currentVideoItem!);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Debug info
  void printDebugInfo() {
    log('=== Video Controller Debug Info ===');
    log('Video Initialized: ${isVideoInitialized.value}');
    log('Video Playing: ${isVideoPlaying.value}');
    log('Video Loading: ${isVideoLoading.value}');
    log('Video Error: ${isVideoError.value}');
    log('Current Video: ${_currentVideoItem?.video?.title ?? 'None'}');
    log('Video URL: ${_currentVideoItem?.video?.videoUrl ?? 'None'}');
    log('=====================================');
  }
}
