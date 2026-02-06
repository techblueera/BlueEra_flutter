import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../auth/controller/chat_view_controller.dart';

class ChatCustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
   final bool? isFromFile;
   final bool? isFromComment;
   final File? filePath;

  ChatCustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.isFromFile = false,
    this.filePath,
    this.isFromComment,
  });

  @override
  State<ChatCustomVideoPlayer> createState() => _ChatCustomVideoPlayerState();
}

class _ChatCustomVideoPlayerState extends State<ChatCustomVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  final chatViewController = Get.find<ChatViewController>();
  bool _hasError = false;
  @override
  void initState() {
    super.initState();

    late Future<void> initFuture;

    if (!widget.videoUrl.contains('http')) {
      _controller = VideoPlayerController.file(File(widget.videoUrl));
    } else if (widget.isFromFile == true && widget.filePath != null) {
      _controller = VideoPlayerController.file(widget.filePath!);
    } else {
      _controller = VideoPlayerController.network(widget.videoUrl);
    }

    initFuture = _controller.initialize();

    initFuture.then((_) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _hasError = false;
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _initialized = true; // stop loader
        _hasError = true;
      });
    });
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      child: Align(
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: (_hasError||_controller.value.hasError) ? _videoErrorWidget():
          ((widget.isFromFile == true)?true:_initialized)
              ? Stack(
            children: [
              (widget.isFromComment??false)?Positioned(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ):Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  child: Center(
                    child: (widget.isFromFile == true)
                        ? Column(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(),
                        ),
                        const SizedBox(height: 14,),
                        Obx(() {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 4,vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: AppColors.greyA5..withValues(alpha: 0.4)
                            ),
                            child: CustomText(
                                "${chatViewController.VideoUploadProgress}%",color: Colors.white,fontSize: 12,fontWeight: FontWeight.bold,),
                          );
                        })
                      ],
                    )
                        : Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: AppColors.greyA5..withValues(alpha: 0.4)
                      ),
                      child: !_controller.value.isPlaying
                          ? Icon(Icons.play_circle_fill,
                          color: Colors.white, size: 40)
                          : Icon(Icons.pause_circle,
                          color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
            ],
          )
              : Container(
            color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Stack(
                  children: [

                    Positioned(
                        bottom: 74,
                        left: 0,
                        right: 0,
                        child: Icon(Icons.play_arrow,size: 18,)),
                    Center(child: CircularProgressIndicator())
                  ],
                ),
              ),
        ),
      ),
    );
  }
  Widget _videoErrorWidget() {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.play_disabled,
            color: AppColors.grayText,
            size: 40,
          ),
          SizedBox(height: 6),
          CustomText(
            "Video unavailable",
              color: AppColors.grayText,
              fontSize: 15,
              fontWeight: FontWeight.w700,

          ),
        ],
      ),
    );
  }
}