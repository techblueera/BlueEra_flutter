import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String? videoUrl;
  final File? videoFile;

  const VideoPlayerWidget({
    super.key,
    this.videoUrl,
    this.videoFile,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _showOverlay = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Do NOT initialize here — wait until visible on screen
  }

  void _initializeController() {
    if (_isInitialized) return;
    _isInitialized = true;

    VideoPlayerController controller;
    if (widget.videoFile != null) {
      controller = VideoPlayerController.file(widget.videoFile!);
    } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
        videoPlayerOptions: isHlsUrl(widget.videoUrl!)
            ? VideoPlayerOptions(mixWithOthers: true)
            : null,
      );
    } else {
      return;
    }

    _controller = controller;
    controller.initialize().then((_) {
      if (mounted) {
        controller.setLooping(true);
        controller.play();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null) return;
    setState(() {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
      } else {
        ctrl.play();
      }
      _showOverlay = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _showOverlay = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final isReady = ctrl != null && ctrl.value.isInitialized;

    return VisibilityDetector(
      key: Key('video_player_${widget.videoUrl ?? widget.videoFile?.path ?? hashCode}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          _initializeController();
        }
      },
      child: isReady
          ? GestureDetector(
              onTap: _togglePlayPause,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(ctrl),
                    if (_showOverlay || !ctrl.value.isPlaying)
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: AppColors.blackCC,
                          ),
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            ctrl.value.isPlaying
                                ? Icons.pause_outlined
                                : Icons.play_arrow_outlined,
                            size: SizeConfig.size40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
