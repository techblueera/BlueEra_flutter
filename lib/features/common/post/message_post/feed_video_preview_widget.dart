import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File file;

  const VideoPreviewScreen({super.key, required this.file});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  late AnimationController _controlsAnim;
  late Animation<double> _controlsFade;

  @override
  void initState() {
    super.initState();
    _controlsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _controlsFade = CurvedAnimation(
      parent: _controlsAnim,
      curve: Curves.easeOut,
    );

    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
        _hideControlsDelayed();
      });

    _controller.addListener(_onVideoProgress);
  }

  void _onVideoProgress() {
    if (mounted) setState(() {});
  }

  void _hideControlsDelayed() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        _controlsAnim.reverse();
        _showControls = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoProgress);
    _controller.dispose();
    _controlsAnim.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
        _showControls = true;
        _controlsAnim.forward();
      } else {
        _controller.play();
        _isPlaying = true;
        _hideControlsDelayed();
      }
    });
  }

  void _onTapScreen() {
    if (_showControls) {
      _controlsAnim.reverse();
      _showControls = false;
    } else {
      _controlsAnim.forward();
      _showControls = true;
      if (_isPlaying) _hideControlsDelayed();
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video
            Center(
              child: _controller.value.isInitialized
                  ? GestureDetector(
                      onTap: _onTapScreen,
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF667EEA)),
                      ),
                    ),
            ),

            // Overlay controls
            if (_controller.value.isInitialized)
              FadeTransition(
                opacity: _controlsFade,
                child: GestureDetector(
                  onTap: _onTapScreen,
                  behavior: HitTestBehavior.translucent,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Top bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 18),
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Video Preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),

                      // Center play/pause
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  key: ValueKey(_isPlaying),
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom progress bar
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  padding: EdgeInsets.zero,
                                  colors: const VideoProgressColors(
                                    playedColor: Color(0xFF667EEA),
                                    bufferedColor: Color(0x55667EEA),
                                    backgroundColor: Color(0x33FFFFFF),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Time
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(
                                        _controller.value.position),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(
                                        _controller.value.duration),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
