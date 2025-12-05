import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class OttVideoPlayerController extends GetxController {
  late VideoPlayerController videoController;

  var isPlaying = false.obs;
  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;
  var selectedQuality = ''.obs;

  // Available quality URLs from backend or static
  Map<String, String> videoQualityUrls = {
    "240p": "https://be-video-service-01.s3.ap-south-1.amazonaws.com/uploads%2F1764919735560-8426327a-bf1d-4c0d-9152-10e556ffd481.mp4",
    "360p": "https://ott-bucket-01.s3.ap-south-1.amazonaws.com/videos/Blueera_1.mp4",
    "720p": "https://be-video-service-01.s3.ap-south-1.amazonaws.com/uploads%2F1764919735560-8426327a-bf1d-4c0d-9152-10e556ffd481.mp4",
    "1080p": "https://be-video-service-01.s3.ap-south-1.amazonaws.com/uploads%2F1764919735560-8426327a-bf1d-4c0d-9152-10e556ffd481.mp4",
  };

  @override
  void onInit() {
    super.onInit();
    selectedQuality.value = "360p"; // Default quality
    initVideo(videoQualityUrls[selectedQuality.value]!);

    // Force always portrait mode
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void initVideo(String url) async {
    videoController = VideoPlayerController.networkUrl(Uri.parse(url));

    await videoController.initialize();
    totalDuration.value = videoController.value.duration;

    videoController.addListener(() {
      currentPosition.value = videoController.value.position;
      isPlaying.value = videoController.value.isPlaying;
    });

    videoController.play();
    update();
  }

  void playPause() {
    isPlaying.value ? videoController.pause() : videoController.play();
  }

  void forward5sec() {
    final newPosition = videoController.value.position + Duration(seconds: 5);
    videoController.seekTo(newPosition);
  }

  void backward5sec() {
    final newPosition = videoController.value.position - Duration(seconds: 5);
    videoController.seekTo(newPosition);
  }

  void changeQuality(String quality) {
    selectedQuality.value = quality;
    final current = videoController.value.position;

    initVideo(videoQualityUrls[quality]!);
    videoController.seekTo(current);
  }

  @override
  void onClose() {
    videoController.dispose();
    super.onClose();
  }
}
