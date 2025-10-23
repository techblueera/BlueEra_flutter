import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/message_post_preview_screen_new.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class PhotoListingWidget extends StatelessWidget {
  const PhotoListingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: "Edit photo",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size15,
              right: SizeConfig.size15,
              bottom: SizeConfig.size15,
              top: SizeConfig.size5),
          child: PositiveCustomBtn(
              onTap: () {
                final msgController = Get.find<MessagePostController>();

                if (msgController.imagesList.length < 1) {
                  commonSnackBar(message: "At least 1 photo is required");
                  return;
                }
                Get.off(() =>
                    MessagePostPreviewScreenNew(
                      postVia: PostVia.profile,
                      isEdit: false,
                    ));
              },
              title: "Next"),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: PhotoUploadWidget(),
        ),
      ),
    );
  }
}

class PhotoUploadWidget extends StatefulWidget {
  PhotoUploadWidget({super.key, this.isFromRepost = false});

  final bool isFromRepost;

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final msgController = Get.find<MessagePostController>();

  final Map<String, File> _videoThumbnails = {}; // videoPath -> thumbnail file

  Future<void> _pickMedia() async {
    if (msgController.selectedFiles.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can select up to 4 files only.")),
      );
      return;
    }

    final remainingSlots = 4 - msgController.selectedFiles.length;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media, // allows both images and videos
      withData: false,
    );

    if (result == null) return;

    final files = result.paths.map((e) => File(e!)).toList();

    for (var file in files.take(remainingSlots)) {
      msgController.selectedFiles.add(file);
      if (_isVideo(file)) {
        _generateThumbnail(file);
      }
    }

    setState(() {});
  }

  Future<void> _generateThumbnail(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        // smaller size = faster
        // maxWidth: 300,
        quality: 75,
      );

      if (thumbnailPath != null) {
        setState(() {
          _videoThumbnails[videoFile.path] = File(thumbnailPath);
        });
      }
    } catch (e) {
      debugPrint("Thumbnail generation failed: $e");
    }
  }

  bool _isVideo(File file) {
    final ext = file.path
        .split('.')
        .last
        .toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
  }

  void _removeMedia(int index) {
    final removed = msgController.selectedFiles.removeAt(index);
    if (_isVideo(removed)) _videoThumbnails.remove(removed.path);
    setState(() {});
  }

  void _openVideoPreview(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPreviewScreen(file: file)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Obx(() {
        return SingleChildScrollView(
          child: Column(
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(widget.isFromRepost
                      ? "Upload Photo"
                      : "Upload Photo (at least 1 media required)")),
              SizedBox(height: SizeConfig.size10),
              // 🔹 Horizontal media preview
           /*   if (msgController.selectedFiles.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    itemCount: msgController.selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = msgController.selectedFiles[index];
                      final isVideo = _isVideo(file);
                      final thumb = _videoThumbnails[file.path];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: isVideo
                                  ? (thumb != null
                                  ? Image.file(
                                thumb,
                                width: 140,
                                height: 160,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                width: 140,
                                height: 160,
                                color: Colors.black12,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ))
                                  : Image.file(
                                file,
                                width: 140,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (isVideo)
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () => _openVideoPreview(file),
                                  child: const Center(
                                    child: Icon(Icons.play_circle_fill,
                                        color: Colors.white, size: 40),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: GestureDetector(
                                onTap: () => _removeMedia(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: SizeConfig.size10),
*/
              InkWell(
                onTap: () async {
                  // _pickMedia();
                  msgController.pickImageFrom(context);
                },
                child: Container(
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.size50 + 2,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    // White background
                    borderRadius: BorderRadius.circular(10.0),
                    // Rounded corners
                    border: Border.all(width: 1, color: AppColors.greyE5),
                    boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LocalAssets(imagePath: AppIconAssets.black_gallery),
                        SizedBox(width: SizeConfig.size8),
                        CustomText(
                          "Add Media (${msgController.imagesList.length}/4)",
                          // 'Upload Photos',
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.large,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

               SizedBox(height: SizeConfig.size15),
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(SizeConfig.size1),
                physics: NeverScrollableScrollPhysics(),
                itemCount: msgController.imagesList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            // width:300 ,
                            height: 300,
                            // height: Get.width * 0.5,
                            // // height: Get.width * 0.5,
                            // width: msgController
                            //             .imagesList[index].imgCropMode ==
                            //     AppConstants.Square
                            //     ? Get.width * 0.5
                            //     : double.parse(
                            //         msgController.imagesList[index].imgWidth ??
                            //             Get.width.toString()),
                            decoration: BoxDecoration(
                              // borderRadius: BorderRadius.circular(
                              //     msgController.imagesList[index].imgCropMode ==
                              //         AppConstants.Square
                              //         ? 0
                              //         : 12),
                              image: DecorationImage(
                                image: FileImage(File(msgController
                                        .imagesList[index].imageFile?.path ??
                                    "")),
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => msgController.removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                        // --- Crop button ---------------------------
                        // Positioned(
                        //   bottom: 6,
                        //   right: 6,
                        //   child: _photoPhotoPopUpMenu(index),
                        // ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}

class VideoPreviewScreen extends StatefulWidget {
  final File file;

  const VideoPreviewScreen({super.key, required this.file});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
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


class TwitterMediaPicker extends StatefulWidget {
  const TwitterMediaPicker({super.key});

  @override
  State<TwitterMediaPicker> createState() => _TwitterMediaPickerState();
}

class _TwitterMediaPickerState extends State<TwitterMediaPicker> {
  final List<File> _selectedFiles = [];
  final Map<String, File> _videoThumbnails = {}; // videoPath -> thumbnail file

  Future<void> _pickMedia() async {
    if (_selectedFiles.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can select up to 4 files only.")),
      );
      return;
    }

    final remainingSlots = 4 - _selectedFiles.length;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media, // allows both images and videos
      withData: false,
    );

    if (result == null) return;

    final files = result.paths.map((e) => File(e!)).toList();

    for (var file in files.take(remainingSlots)) {
      _selectedFiles.add(file);
      if (_isVideo(file)) {
        _generateThumbnail(file);
      }
    }

    setState(() {});
  }

  Future<void> _generateThumbnail(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        // smaller size = faster
        quality: 75,
      );

      if (thumbnailPath != null) {
        setState(() {
          _videoThumbnails[videoFile.path] = File(thumbnailPath);
        });
      }
    } catch (e) {
      debugPrint("Thumbnail generation failed: $e");
    }
  }

  bool _isVideo(File file) {
    final ext = file.path
        .split('.')
        .last
        .toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
  }

  void _removeMedia(int index) {
    final removed = _selectedFiles.removeAt(index);
    if (_isVideo(removed)) _videoThumbnails.remove(removed.path);
    setState(() {});
  }

  void _openVideoPreview(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPreviewScreen(file: file)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Twitter-style Media Picker")),
      body: Column(
        children: [
          Expanded(
            child: _selectedFiles.isEmpty
                ? const Center(child: Text("No media selected"))
                : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                final isVideo = _isVideo(file);
                final thumb = _videoThumbnails[file.path];

                return GestureDetector(
                  onTap: isVideo ? () => _openVideoPreview(file) : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 🖼️ Show image or video thumbnail
                      isVideo
                          ? (thumb != null
                          ? Image.file(thumb, fit: BoxFit.cover)
                          : Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ))
                          : Image.file(file, fit: BoxFit.cover),

                      // ▶️ Play icon overlay for videos
                      if (isVideo)
                        const Center(
                          child: Icon(Icons.play_circle_fill,
                              color: Colors.white, size: 40),
                        ),

                      // ❌ Remove icon
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => _removeMedia(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.add),
              label: Text("Add Media (${_selectedFiles.length}/4)"),
            ),
          ),
        ],
      ),
    );
  }
}
