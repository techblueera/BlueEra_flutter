import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../auth/controller/chat_view_controller.dart';

class MultiImagePreviewPage extends StatefulWidget {
  final List<File> mediaFiles;
  final Function(List<File> file,String? commands) onSend;

  const MultiImagePreviewPage({
    super.key,
    required this.mediaFiles,
    required this.onSend,
  });

  @override
  State<MultiImagePreviewPage> createState() => _MultiImagePreviewPageState();
}

class _MultiImagePreviewPageState extends State<MultiImagePreviewPage> {
  late PageController _pageController;
  final TextEditingController commentController=TextEditingController();
  final List<VideoPlayerController?> _videoControllers = [];
  List<File> _mediaFiles = [];
  bool setPlay = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _mediaFiles = [...widget.mediaFiles];

    _initializeMediaControllers(widget.mediaFiles);
  }

  Future<void> _initializeMediaControllers(List<File> files) async {
    for (var file in files) {
      if (_isVideo(file)) {
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        _videoControllers.add(controller);
      } else {
        _videoControllers.add(null);
      }
    }
    setState(() {});
  }


  bool _isVideo(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'mkv', 'avi'].contains(ext);
  }
  final chatViewController = Get.find<ChatViewController>();


  @override
  void dispose() {
    for (var vc in _videoControllers) {
      vc?.dispose();
    }
    commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _togglePlayPause(int index) {
    final controller = _videoControllers[index];
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        setPlay = false;
        controller.pause();
      } else {
        setPlay = true;
        controller.play();
      }
    });
  }

  Future<void> pickMoreMedia(bool isVideo) async {
    final picker = ImagePicker();
    List<File> files = [];
    if (isVideo) {
      final XFile? pickedVideo = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedVideo != null) {
        files.add(File(pickedVideo.path));
      }
    } else {
      final List<XFile>? pickedImages = await picker.pickMultiImage();
      if (pickedImages != null && pickedImages.isNotEmpty) {
        files.addAll(pickedImages.map((xfile) => File(xfile.path)));
      }
    }


    if (files.isNotEmpty) {

      for (var file in files) {
        if (_isVideo(file)) {
          final controller = VideoPlayerController.file(file);
          await controller.initialize();
          _videoControllers.add(controller);
        } else {
          _videoControllers.add(null);
        }
      }

      setState(() {
        _mediaFiles.addAll(files);
      });
    }
  }
  bool isVideo(String url) {
    return url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.avi') ||
        url.toLowerCase().endsWith('.webm') ||
        url.toLowerCase().endsWith('.mkv');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            (_mediaFiles.length==1&&_isVideo(_mediaFiles.first)&&_videoControllers.length==0)?Center(child: CircularProgressIndicator()):PageView.builder(
              controller: _pageController,
              itemCount: _mediaFiles.length,
              itemBuilder: (_, index) {
                final file = _mediaFiles[index];

                final videoController = (_videoControllers.isNotEmpty)?_videoControllers[index]:null;

                return _isVideo(file)
                    ? videoController != null && videoController.value.isInitialized
                    ? GestureDetector(
                  onTap: () => _togglePlayPause(index),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: AspectRatio(
                          aspectRatio: videoController.value.aspectRatio,
                          child: VideoPlayer(videoController),
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: AppColors.greyA5.withOpacity(0.4)
                        ),
                        child: !videoController.value.isPlaying
                            ? Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 40)
                            : Icon(Icons.pause_circle,
                            color: Colors.white, size: 40),
                      )
                    ],
                  ),
                )
                    : Center(child: CircularProgressIndicator())
                    : Image.file(file, fit: BoxFit.contain, width: double.infinity, height: double.infinity);
              },
            ),


            // Top-right action buttons
            Positioned(
              top: 40,
              right: 16,
              child: Row(
                children: [
                  _iconAction(Icons.auto_awesome), // Filter
                  SizedBox(width: 12),
                  _iconAction(Icons.crop), // Crop
                  SizedBox(width: 12),
                  _iconAction(Icons.edit), // Draw
                ],
              ),
            ),

            // Close button top-left
            Positioned(
              top: 40,
              left: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),

            // Bottom input and send
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(controller: commentController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            onPressed: (){
                              pickMoreMedia(isVideo(widget.mediaFiles.first.path));
                            },
                            icon: SvgPicture.asset(
                              AppIconAssets.chat_input_add_media,
                              width: 26,
                              height: 26,
                            ),
                          ),
                          hintText: "Add a note or caption...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    InkWell(

                      onTap: (){
                        widget.onSend(_mediaFiles,(commentController.text.isEmpty)?null:commentController.text);
                      },
                      child: Container(
                        margin: EdgeInsets.only(left: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset(
                          AppIconAssets.send_message_chat,
                          height: 21,
                          width: 21,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black54,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
