import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class IntroductionVideoWidget extends StatefulWidget {
  const IntroductionVideoWidget({Key? key}) : super(key: key);

  @override
  State<IntroductionVideoWidget> createState() => _IntroductionVideoWidgetState();
}

class _IntroductionVideoWidgetState extends State<IntroductionVideoWidget> {
  final introVideoController = Get.put(IntroductionVideoController());
  Timer? _hideControlsTimer;
  final RxBool _showControls = true.obs;

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _showControls.value = true;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      _showControls.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(SizeConfig.size16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            CustomText(
              'Upload Introduction Video',
              fontSize: SizeConfig.large,
            ),
            SizedBox(height: SizeConfig.size12),

            // Show different UI based on whether video is uploaded or not
            introVideoController.hasUploadedVideo.value
                ? _buildVideoPreview()
                : _buildUploadArea(),

            SizedBox(height: SizeConfig.size16),

            // Show upload button if no video is uploaded, otherwise show edit button
            introVideoController.hasUploadedVideo.value
                ? Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                          isValidate: true,
                          onTap: () async {
                            // Allow user to select a new video
                            await _pickVideo();
                          },
                          title: "Change",
                          bgColor: AppColors.white,
                          borderColor: AppColors.primaryColor,
                          textColor: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  )
                : PositiveCustomBtn(
                    onTap: () async {
                      if (introVideoController.selectedVideo.value != null) {
                        await introVideoController.uploadIntroVideo(videoLink: '');
                      } else {
                        commonSnackBar(message: "Please select a video first");
                      }
                    },
                    title: introVideoController.isUploading.value ? "Uploading..." : "Upload",
                  )
          ],
        ),
      );
    });
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickVideo,
      child: DottedBorder(
        color: const Color(0xffD2D2D2),
        strokeWidth: 1.5,
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        dashPattern: const [6, 4],
        child: Container(
          width: double.infinity,
          height: SizeConfig.size140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 40,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 8),
                CustomText(
                  introVideoController.selectedVideo.value != null
                      ? introVideoController.selectedVideo.value!.path.split('/').last
                      : 'Upload your Introduction Video',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return GestureDetector(
      onTap: () {
        _resetHideControlsTimer();
        if (introVideoController.videoPlayerController.value != null) {
          introVideoController.toggleVideoPlayback();
        }
      },
      child: Container(
        width: double.infinity,
        height: SizeConfig.size200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black,
        ),
        child: introVideoController.videoPlayerController.value != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: introVideoController.videoPlayerController.value!.value.aspectRatio,
                      child: VideoPlayer(introVideoController.videoPlayerController.value!),
                    ),
                  ),
                  // Show play/pause controls that hide after clicking
                  Obx(() => _showControls.value
                      ? Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            introVideoController.isPlaying.value
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    introVideoController.resetVideo();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      File pickedFile = File(result.files.single.path!);
      introVideoController.setSelectedVideo(pickedFile);
    } else {
      commonSnackBar(message: "No video selected");
    }
  }
}
