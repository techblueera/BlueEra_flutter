
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class NetworkVideoPreviewScreen extends StatefulWidget {
  final String videoUrl;

  const NetworkVideoPreviewScreen({super.key, required this.videoUrl});

  @override
  State<NetworkVideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<NetworkVideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {}); // refresh after video loads
        _controller.play();
        _isPlaying = true;
      });
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
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? GestureDetector(
          onTap: _togglePlayPause,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              if (!_isPlaying)
                const Icon(Icons.play_circle_fill,
                    color: Colors.white, size: 80),
            ],
          ),
        )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
