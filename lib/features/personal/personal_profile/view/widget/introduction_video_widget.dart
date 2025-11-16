import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/introduction_video_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../widgets/local_assets.dart';

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
          borderRadius: BorderRadius.circular(10),
          // boxShadow: const [
          //   BoxShadow(
          //     color: Colors.black12,
          //     blurRadius: 6,
          //     offset: Offset(0, 2),
          //   ),
          // ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Row(
              children: [
                _buildCircleIcon(AppIconAssets.video_outline),
                SizedBox(width: SizeConfig.size6),


                CustomText(
                  AppStrings.uploadIntroductionVideo,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),

            // Show different UI based on whether video is uploaded or not
            introVideoController.hasUploadedVideo.value
                ? _buildVideoPreview()
                : Container(),
            //_buildUploadArea(),

            SizedBox(height: SizeConfig.size6),

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
                          title: AppStrings.change,
                          bgColor: AppColors.white,
                          borderColor: AppColors.primaryColor,
                          textColor: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  )

                : PositiveCustomBtn(
              isShadowAvailable: true,
              bgColor: AppColors.white,
              leadingIconColor:AppColors.grayText,
              isLeadingShow: true,
              textColor: AppColors.grayText,
              borderColor: AppColors.whiteE5,
              leadingIconPath:AppIconAssets.uploadIcon,
                    onTap: () async {
                      // if (introVideoController.selectedVideo.value != null) {
                      //
                      // } else {
                        await _pickVideo();
                        await introVideoController.uploadIntroVideo(videoLink: '');
                        // commonSnackBar(message: "Please select a video first");
                      // }
                    },
                    title: introVideoController.isUploading.value ? "${AppStrings.uploading}..." : AppStrings.uploadVideo,
                  )
          ],
        ),
      );
    });

  }
  Widget _buildCircleIcon(String iconImage) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primaryColor, width: 0.5),
      ),
      child: LocalAssets(
        width: SizeConfig.size22,
        height: SizeConfig.size22,
        imagePath: iconImage,
        imgColor: AppColors.primaryColor,
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
                            color: Colors.black.withValues(alpha: 0.5),
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

      commonSnackBar(message:AppStrings.noVideoSelected);
    }
  }
}
