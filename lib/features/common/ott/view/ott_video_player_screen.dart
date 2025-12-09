import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/ott/controller/ott_video_player_controller.dart';
import 'package:BlueEra/features/common/ott/model/ott_channel_video_res_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class OttVideoPlayerScreen extends StatefulWidget {
  OttVideoPlayerScreen({super.key, required this.videoItems});

  final VideoItems videoItems;

  @override
  State<OttVideoPlayerScreen> createState() => _OttVideoPlayerScreenState();
}

class _OttVideoPlayerScreenState extends State<OttVideoPlayerScreen> {
  final controller = Get.put(OttVideoPlayerController());

  @override
  void initState() {
    super.initState();
    if (widget.videoItems.videoUrl?.isNotEmpty ?? false) {
      controller
          .initializePlayer(widget.videoItems.transcodedUrls?.master ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (controller.isFullScreen.value) {
          controller.toggleFullScreen();
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: (widget.videoItems.videoUrl?.isEmpty ?? false)
            ? SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: CustomText(
                          AppStrings.somethingWentWrong,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : GetBuilder<OttVideoPlayerController>(
                builder: (_) {
                  return Center(
                    child: controller.isInitialized.value
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. THE VIDEO LAYER
                              GestureDetector(
                                onTap: controller.toggleControls,
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: controller
                                        .videoController.value.aspectRatio,
                                    child:
                                        VideoPlayer(controller.videoController),
                                  ),
                                ),
                              ),

                              // 2. THE CONTROLS OVERLAY (Fade in/out)
                              Obx(() => AnimatedOpacity(
                                    opacity: controller.showControls.value
                                        ? 1.0
                                        : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: IgnorePointer(
                                      ignoring: !controller.showControls.value,
                                      child: Stack(
                                        children: [
                                          // A. Semi-transparent background for controls visibility
                                          Container(color: Colors.black38),

                                          // B. TOP ROW (Back + Settings)
                                          Positioned(
                                            top: 40,
                                            left: 20,
                                            right: 20,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.arrow_back_ios,
                                                      color: Colors.white),
                                                  onPressed: () => Get.back(),
                                                ),
                                                Expanded(
                                                    child: CustomText(
                                                  "${widget.videoItems.title}",
                                                  color: Colors.white,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                )),
                                                // Quality Settings
                                                // _buildQualitySettings(context),
                                              ],
                                            ),
                                          ),

                                          // C. CENTER ROW (Rewind - Play - Forward)
                                          Align(
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  iconSize: 40,
                                                  icon: const Icon(
                                                      Icons.replay_5,
                                                      color: Colors.white),
                                                  onPressed:
                                                      controller.backward5sec,
                                                ),
                                                const SizedBox(width: 20),
                                                IconButton(
                                                  iconSize: 60,
                                                  icon: Icon(
                                                    controller.isPlaying.value
                                                        ? Icons
                                                            .pause_circle_filled
                                                        : Icons
                                                            .play_circle_filled,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed:
                                                      controller.playPause,
                                                ),
                                                const SizedBox(width: 20),
                                                IconButton(
                                                  iconSize: 40,
                                                  icon: const Icon(
                                                      Icons.forward_5,
                                                      color: Colors.white),
                                                  onPressed:
                                                      controller.forward5sec,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // D. BOTTOM ROW (Time - Slider - Fullscreen)
                                          Positioned(
                                            bottom: 20,
                                            left: 20,
                                            right: 20,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    // Current Time
                                                    Text(
                                                      formatDuration(controller
                                                          .currentPosition
                                                          .value),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),

                                                    // Progress Bar
                                                    Expanded(
                                                      child: SliderTheme(
                                                        data: SliderTheme.of(
                                                                context)
                                                            .copyWith(
                                                          activeTrackColor:
                                                              AppColors
                                                                  .primaryColor,
                                                          // Match your image blue
                                                          inactiveTrackColor:
                                                              Colors.grey,
                                                          thumbColor: AppColors
                                                              .primaryColor,
                                                          trackHeight: 2.0,
                                                          thumbShape:
                                                              const RoundSliderThumbShape(
                                                                  enabledThumbRadius:
                                                                      6.0),
                                                        ),
                                                        child: Slider(
                                                          min: 0,
                                                          max: controller
                                                              .totalDuration
                                                              .value
                                                              .inSeconds
                                                              .toDouble(),
                                                          value: controller
                                                              .currentPosition
                                                              .value
                                                              .inSeconds
                                                              .toDouble(),
                                                          onChanged: (val) {
                                                            controller
                                                                .seekTo(val);
                                                          },
                                                        ),
                                                      ),
                                                    ),

                                                    // Total Duration
                                                    CustomText(
                                                        formatDuration(
                                                            controller
                                                                .totalDuration
                                                                .value),
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),

                                                    // Fullscreen Toggle
                                                    const SizedBox(width: 10),
                                                    IconButton(
                                                      icon: Icon(
                                                        controller.isFullScreen
                                                                .value
                                                            ? Icons
                                                                .fullscreen_exit
                                                            : Icons.fullscreen,
                                                        color: Colors.white,
                                                      ),
                                                      onPressed: controller
                                                          .toggleFullScreen,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
      ),
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }
}
