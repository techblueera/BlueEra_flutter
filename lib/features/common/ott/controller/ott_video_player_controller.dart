import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class OttVideoPlayerController extends GetxController {
  late VideoPlayerController videoController;

  // Observables
  RxBool isPlaying = false.obs;
  RxBool isInitialized = false.obs;
  RxBool isBuffering = false.obs;
  RxBool isFullScreen = false.obs;

  // UI Control Visibility
  RxBool showControls = true.obs;
  Timer? _hideTimer;

  // Video Progress
  Rx<Duration> currentPosition = Duration.zero.obs;
  Rx<Duration> totalDuration = Duration.zero.obs;

  // Quality
  RxString selectedQuality = '720p'.obs;
  Map<String, String> videoQualityUrls = {
    '1080p': 'url_to_1080p',
    '720p': 'url_to_720p',
    '480p': 'url_to_480p',
  };


  void initializePlayer(String url) {
    videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      // httpHeaders: {
      //   'User-Agent': 'Flutter Video Player',
      // },
      // formatHint: VideoFormat.hls, // 👈 required for .m3u8 streams
    )..initialize().then((_) {
        isInitialized.value = true;
        totalDuration.value = videoController.value.duration;
        videoController.play();
        isPlaying.value = true;
        startHideTimer(); // Start timer immediately
        update();
      });

    videoController.addListener(() {
      currentPosition.value = videoController.value.position;
      isBuffering.value = videoController.value.isBuffering;
      logs(
          "videoController.value.duration=== ${videoController.value.duration}");
      logs(
          "videoController.value.position=== ${videoController.value.position}");
      logs("currentPosition.value=== ${currentPosition.value}");
      // Auto-show controls if video ends
      if (videoController.value.position >= videoController.value.duration) {
        showControls.value = true;
        isPlaying.value = false;
      }
    });
  }

  // --- CONTROLS VISIBILITY LOGIC ---
  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      showControls.value = false;
    });
  }

  void onUserInteraction() {
    // Reset the timer whenever the user touches a button
    showControls.value = true;
    startHideTimer();
  }

  // --- PLAYER ACTIONS ---
  void playPause() {
    onUserInteraction();
    if (videoController.value.isPlaying) {
      videoController.pause();
      isPlaying.value = false;
    } else {
      videoController.play();
      isPlaying.value = true;
    }
  }

  void forward5sec() {
    onUserInteraction();
    final newPos = videoController.value.position + const Duration(seconds: 5);
    videoController.seekTo(newPos);
  }

  void backward5sec() {
    onUserInteraction();
    final newPos = videoController.value.position - const Duration(seconds: 5);
    videoController.seekTo(newPos);
  }

  void seekTo(double value) {
    onUserInteraction();
    final position = Duration(seconds: value.toInt());
    videoController.seekTo(position);
  }

  void toggleFullScreen() {
    onUserInteraction();
    isFullScreen.value = !isFullScreen.value;
    if (isFullScreen.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void changeQuality(String quality) {
    // Logic to switch URL would go here
    selectedQuality.value = quality;
    // Reload video logic...
    onUserInteraction();
  }

  @override
  void onClose() {
    videoController.dispose();
    _hideTimer?.cancel();
    // Force portrait when exiting
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }
}

Future<List<HlsTrack>> parseHlsMasterPlaylist(String masterUrl) async {
  try {
    Dio dio = Dio();
    final response = await dio.get(masterUrl);
    if (response.statusCode != 200) return [];

    final lines = response.data.split('\n');
    List<HlsTrack> tracks = [];
    String? currentResolution;
    int? currentBandwidth;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      if (line.startsWith('#EXT-X-STREAM-INF')) {
        // Extract Resolution
        if (line.contains('RESOLUTION=')) {
          final resMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
          if (resMatch != null) {
            // generally use height (e.g., 720) as the label
            currentResolution = "${resMatch.group(2)}p";
          }
        }
        // Extract Bandwidth (optional, for sorting)
        if (line.contains('BANDWIDTH=')) {
          final bandMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
          if (bandMatch != null) {
            currentBandwidth = int.parse(bandMatch.group(1)!);
          }
        }
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        // This line is the URL (Variant Stream)
        if (currentResolution != null) {
          // Handle relative URLs
          String finalUrl = line;
          if (!line.startsWith('http')) {
            final baseUrl =
                masterUrl.substring(0, masterUrl.lastIndexOf('/') + 1);
            finalUrl = "$baseUrl$line";
          }

          tracks.add(HlsTrack(
              resolution: currentResolution,
              url: finalUrl,
              bandwidth: currentBandwidth ?? 0));

          // Reset for next track
          currentResolution = null;
          currentBandwidth = null;
        }
      }
    }

    // Sort by quality (optional: lowest to highest)
    tracks.sort((a, b) => a.bandwidth.compareTo(b.bandwidth));
    return tracks;
  } catch (e) {
    print("Error parsing HLS: $e");
    return [];
  }
}

class HlsTrack {
  final String resolution; // e.g., "720p"
  final String url;
  final int bandwidth;

  HlsTrack(
      {required this.resolution, required this.url, required this.bandwidth});
}
