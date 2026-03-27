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
  bool _isInitializing = false;
  bool _userTappedPlay = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeAndPlay() async {
    if (_isInitializing || _controller != null) return;
    _isInitializing = true;

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
      _isInitializing = false;
      return;
    }

    _controller = controller;
    if (mounted) setState(() {});

    await controller.initialize();

    if (!mounted) {
      controller.dispose();
      return;
    }

    _isInitializing = false;
    controller.setLooping(true);
    controller.play();
    setState(() {});
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitializing = false;
    _userTappedPlay = false;
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
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
      key: Key('vp_${widget.videoUrl ?? widget.videoFile?.path ?? hashCode}'),
      onVisibilityChanged: (info) {
        // Dispose controller when completely scrolled out of view
        if (info.visibleFraction == 0 && _controller != null) {
          setState(() => _disposeController());
        }
      },
      child: GestureDetector(
        onTap: () {
          if (!_userTappedPlay) {
            setState(() => _userTappedPlay = true);
            _initializeAndPlay();
          } else {
            _togglePlayPause();
          }
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video or black background
              if (isReady)
                VideoPlayer(ctrl)
              else
                Container(color: Colors.black),

              // Overlay: spinner while initializing, play/pause icon otherwise
              if (_isInitializing)
                const CircularProgressIndicator(color: Colors.white)
              else if (!isReady || _showOverlay || !ctrl!.value.isPlaying)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: AppColors.blackCC,
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      isReady && ctrl!.value.isPlaying
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
      ),
    );
  }
}
