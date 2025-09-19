import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
  late VideoPlayerController _controller;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (widget.videoFile != null) {
      _controller = VideoPlayerController.file(widget.videoFile!);
    } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {


      // Create new controller
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
        videoPlayerOptions: isHlsUrl(widget.videoUrl!)
            ? VideoPlayerOptions(mixWithOthers: true)
            : null,
      );
    }

    _controller
      ..initialize().then((_) => setState(() {}))
      ..setLooping(true)
      ..play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _showOverlay = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _showOverlay = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: _togglePlayPause,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  if (_showOverlay || !_controller.value.isPlaying)
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
                          _controller.value.isPlaying
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
        : const Center(child: CircularProgressIndicator());
  }
}
