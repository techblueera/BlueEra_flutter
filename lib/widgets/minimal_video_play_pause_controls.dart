import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MinimalVideoPlayPauseControls extends StatefulWidget {
  const MinimalVideoPlayPauseControls({super.key});

  @override
  State<MinimalVideoPlayPauseControls> createState() => _MinimalVideoPlayPauseControlsState();
}

class _MinimalVideoPlayPauseControlsState extends State<MinimalVideoPlayPauseControls> {
  late ChewieController _chewieController;
  late VideoPlayerController _videoController;
  bool showIcon = true;
  bool isEnded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chewieController = ChewieController.of(context);
    _videoController = _chewieController.videoPlayerController;

    // initially check
    if(_videoController.value.isPlaying){
      _videoStarted();
    }

    _videoController.addListener(_videoStateListener);
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoStateListener);
    super.dispose();
  }

  void _videoStateListener() {
    // Check if video has finished playing
    if (_videoController.value.position >= _videoController.value.duration) {
      setState(() {
        showIcon = true;
        isEnded = true;  // Show replay icon
      });
    }
  }

  // void _videoStateListener() {
  //   final isEnded = _videoController.value.position >= _videoController.value.duration;
  //   final isPlaying = _videoController.value.isPlaying;
  //
  //   if (isEnded) {
  //     if (!showIcon) {
  //       setState(() => showIcon = true);
  //     }
  //     return;
  //   }
  //
  //   if (isPlaying) {
  //     if (!_isCooldown && !showIcon) {
  //       setState(() => showIcon = true);
  //       _isCooldown = true;
  //
  //       Future.delayed(const Duration(seconds: 1), () {
  //         if (mounted && _videoController.value.isPlaying) {
  //           setState(() => showIcon = false);
  //         }
  //         _isCooldown = false;
  //       });
  //     }
  //   } else if (!isPlaying && !showIcon) {
  //     setState(() => showIcon = true);
  //   }
  // }

  Future<void> _handleTap() async {
    if (isEnded) {
      await _chewieController.seekTo(Duration.zero);
      _chewieController.play();
      setState(() {
        isEnded = false;
        showIcon = true;
      });
      Future.delayed(Duration(seconds: 1), (){
        setState(() {
          showIcon = false;
        });
      });
    } else if (_chewieController.isPlaying) {
      _chewieController.pause();
      setState(() => showIcon = true);
    } else {
      _chewieController.play();
      _videoStarted();
    }
  }

  void _videoStarted(){
    setState(() {
      showIcon = true;
    });
    Future.delayed(Duration(seconds: 1), (){
      setState(() {
        showIcon = false;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final isBuffering = _videoController.value.isBuffering;
    // final duration = _videoController.value.duration;
    // final position = _videoController.value.position;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: Stack(
        children: [
          // Loading spinner
          if (isBuffering)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Play/pause/replay icon
          if (showIcon && !isBuffering)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ClipOval(
                    child: Container(
                      height: 45,
                      width: 45,
                      color: Colors.white.withAlpha(100),
                      child: Icon(
                        isEnded
                            ? Icons.replay
                            : _chewieController.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Fullscreen button (top-right)
          Positioned(
            top: SizeConfig.size12,
            right: SizeConfig.size20,
            child: GestureDetector(
              onTap: () => _chewieController.toggleFullScreen(),
              child: LocalAssets(
                imagePath: AppIconAssets.fullScreenRotateIcon,
              ),
            ),
          ),

          if (!_chewieController.isPlaying)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(left: SizeConfig.size20, bottom: SizeConfig.size20, right: SizeConfig.size20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LocalAssets(imagePath: AppIconAssets.blockIcon),
                    Container(
                      height: SizeConfig.size30,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: SizeConfig.size6, horizontal: SizeConfig.size8),
                      decoration: BoxDecoration(
                          color: AppColors.blackCC,
                          borderRadius: BorderRadius.circular(8.0)
                      ),
                      child: CustomText(
                        "02:26",
                        color: AppColors.white,
                        fontSize: SizeConfig.extraSmall,
                      ),
                    )
                  ],
                ),
              ),
            ),

          // Video progress bar & duration
          // Positioned(
          //   bottom: 8,
          //   left: 12,
          //   right: 12,
          //   child: Column(
          //     children: [
          //       SliderTheme(
          //         data: SliderThemeData(
          //           thumbColor: Colors.white,
          //           activeTrackColor: Colors.white,
          //           inactiveTrackColor: Colors.white54,
          //           trackHeight: 2.0,
          //           overlayColor: Colors.white24,
          //           thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          //         ),
          //         child: Slider(
          //           value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
          //           min: 0.0,
          //           max: duration.inMilliseconds.toDouble(),
          //           onChanged: (value) {
          //             _videoController.seekTo(Duration(milliseconds: value.toInt()));
          //           },
          //         ),
          //       ),
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           Text(
          //             formatDuration(position),
          //             style: const TextStyle(color: Colors.white, fontSize: 12),
          //           ),
          //           Text(
          //             formatDuration(duration),
          //             style: const TextStyle(color: Colors.white, fontSize: 12),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),

        ],
      ),
    );
  }

}
