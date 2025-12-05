import 'package:BlueEra/features/common/ott/controller/ott_video_player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class OttVideoPlayerScreen extends StatelessWidget {
   OttVideoPlayerScreen({super.key});

  final controller = Get.put(OttVideoPlayerController());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        body: GetBuilder<OttVideoPlayerController>(
          builder: (_) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: controller.videoController.value.isInitialized
                  ? Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: controller.playPause,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio:
                        controller.videoController.value.aspectRatio,
                        child: VideoPlayer(controller.videoController),
                      ),
                    ),
                  ),

                  /// Play/Pause overlay – reactive
                  Obx(() => !controller.isPlaying.value
                      ? const Icon(Icons.play_arrow, size: 70, color: Colors.white)
                      : const SizedBox()),

                  /// Bottom controls
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        VideoProgressIndicator(
                          controller.videoController,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),

                        // Progress time, reactive
                        Obx(() => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatDuration(controller.currentPosition.value),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                formatDuration(controller.totalDuration.value),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )),

                        Obx(
                              () => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_5, color: Colors.white),
                                onPressed: controller.backward5sec,
                              ),
                              IconButton(
                                icon: Icon(
                                  controller.isPlaying.value
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: controller.playPause,
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_5, color: Colors.white),
                                onPressed: controller.forward5sec,
                              ),
                            ],
                          ),
                        ),

                        // Quality dropdown reactive
                        Obx(
                              () => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: controller.selectedQuality.value,
                              dropdownColor: Colors.black,
                              underline: Container(),
                              style: const TextStyle(color: Colors.white),
                              items: controller.videoQualityUrls.keys
                                  .map((quality) => DropdownMenuItem(
                                value: quality,
                                child: Text(quality,
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ))
                                  .toList(),
                              onChanged: (val) =>
                                  controller.changeQuality(val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          },
        )

    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return "$minutes:$seconds";
  }
}


