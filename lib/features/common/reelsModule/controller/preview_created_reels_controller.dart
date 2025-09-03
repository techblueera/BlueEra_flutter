import 'dart:io';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:chewie/chewie.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class PreviewCreatedReelsController extends GetxController {
  ChewieController? chewieController;
  VideoPlayerController? videoPlayerController;

  bool isPlaying = true;
  bool isVideoLoading = true;
  bool isShowPlayPauseIcon = false;

  // int videoTime = 0;
  String videoUrl = "";
  String videoThumbnail = "";
  String songId = "";

  @override
  void onInit() {
    final arguments = Get.arguments;
    logs("Selected Video => $arguments");
    videoUrl = arguments["video"];
    videoThumbnail = arguments["image"];
    // videoTime = arguments["time"];
    songId = arguments["songId"] ?? "";
    initializeVideoPlayer(videoUrl);

    logs("Selected Song Id => $songId");
    super.onInit();
  }

  Future<void> initializeVideoPlayer(String videoPath) async {
    try {
      videoPlayerController?.dispose();
      videoPlayerController = null;

      videoPlayerController = VideoPlayerController.file(File(videoPath));

      await videoPlayerController?.initialize();

      if (videoPlayerController != null &&
          (videoPlayerController?.value.isInitialized ?? false)) {
        chewieController = ChewieController(
          videoPlayerController: videoPlayerController!,
          looping: true,
          allowedScreenSleep: false,
          allowMuting: false,
          showControlsOnInitialize: false,
          showControls: false,
          autoPlay: true,
        );

        if (chewieController != null) {
          onChangeLoading(false);
        } else {
          onChangeLoading(true);
        }
      }
    } catch (e) {
      onDisposeVideoPlayer();
      logs("Reels Video Initialization Failed !!! => $e");
    }
  }

  void onStopVideo() {
    onChangePlayPauseIcon(false);
    videoPlayerController?.pause();
  }

  void onPlayVideo() {
    onChangePlayPauseIcon(true);
    videoPlayerController?.play();
  }

  void onClickVideo() async {
    if (isVideoLoading == false) {
      videoPlayerController!.value.isPlaying ? onStopVideo() : onPlayVideo();
      onShowPlayPauseIcon(true);
      await 2.seconds.delay();
      onShowPlayPauseIcon(false);
    }
  }

  void onClickPlayPause() async {
    videoPlayerController!.value.isPlaying ? onStopVideo() : onPlayVideo();
  }

  void onChangeLoading(bool value) {
    isVideoLoading = value;
    update(["onChangeLoading"]);
  }

  void onChangePlayPauseIcon(bool value) {
    isPlaying = value;
    update(["onChangePlayPauseIcon"]);
  }

  void onShowPlayPauseIcon(bool value) {
    isShowPlayPauseIcon = value;
    update(["onShowPlayPauseIcon"]);
  }

  void onDisposeVideoPlayer() {
    try {
      onStopVideo();
      videoPlayerController?.dispose();
      chewieController?.dispose();
      chewieController = null;
      videoPlayerController = null;
      onChangeLoading(true);
      logs("Video Dispose Success");
    } catch (e) {
      logs(">>>> On Dispose VideoPlayer Error => $e");
    }
  }

  @override
  void onClose() async {
    await 500.milliseconds.delay();
    onDisposeVideoPlayer();
    super.onClose();
  }

  void onClickNext({String}) {
    onStopVideo();

    // Get.to(
      // CreateShotsReelScreen(
      //   videoPath: videoUrl,
      //   videoThumbNail: videoThumbnail,
      //   videoUploadType: '',
      // ),
      // arguments: {"video": videoUrl, "image": videoThumbnail, "time": videoTime, "songId": songId},
    // ); 
  }
}
