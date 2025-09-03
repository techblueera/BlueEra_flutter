import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/reelsModule/controller/preview_created_reels_controller.dart';
import 'package:BlueEra/features/common/reelsModule/widget/loading_ui.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PreviewCreatedReelsView extends GetView<PreviewCreatedReelsController> {
  PreviewCreatedReelsView({
    super.key,
    required this.videoType,
  });

  final String? videoType;


  @override
  Widget build(BuildContext context) {
    Timer(
      Duration(milliseconds: 300),
      () {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: AppColors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      },
    );
    return Scaffold(
      body: GetBuilder<PreviewCreatedReelsController>(
        id: "onChangeLoading",
        builder: (controller) => SizedBox(
          height: Get.height,
          width: Get.width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: controller.onClickVideo,
                child: Container(
                  color: AppColors.black,
                  height: Get.height,
                  width: Get.width,
                  child: controller.isVideoLoading
                      ? LoadingUi()
                      : SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.videoPlayerController?.value
                                      .size.width ??
                                  0,
                              height: controller.videoPlayerController?.value
                                      .size.height ??
                                  0,
                              child: Chewie(
                                  controller: controller.chewieController!),
                            ),
                          ),
                        ),
                ),
              ),
              GetBuilder<PreviewCreatedReelsController>(
                id: "onShowPlayPauseIcon",
                builder: (controller) => controller.isShowPlayPauseIcon
                    ? Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: controller.onClickPlayPause,
                          child: GetBuilder<PreviewCreatedReelsController>(
                            id: "onChangePlayPauseIcon",
                            builder: (controller) => Container(
                              height: 70,
                              width: 70,
                              padding: EdgeInsets.only(
                                  left: controller.isPlaying ? 0 : 2),
                              decoration: BoxDecoration(
                                  color: AppColors.black.withOpacity(0.2),
                                  shape: BoxShape.circle),
                              child: Center(
                                child: controller.isPlaying
                                    ? Icon(Icons.pause_circle)
                                    : Icon(Icons.play_circle),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const Offstage(),
              ),
              Positioned(
                top: 0,
                child: Container(
                  height: 150,
                  width: Get.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.black.withOpacity(0.7),
                        AppColors.transparent
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  height: 150,
                  width: Get.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.transparent,
                        AppColors.black.withOpacity(0.7)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                left: 15,
                child: Row(
                  children: [
                    InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Icon(Icons.arrow_back_ios_new_outlined)),
                    SizedBox(
                      width: 15,
                    ),
                    CustomText(
                      "Name",
                    ),
                  ],
                ),
              ),
              /*Positioned(
                top: 35,
                right: 15,
                child: GestureDetector(
                  onTap: () {
                    controller.onStopVideo();
                    // Get.offAndToNamed(AppRoutes.trimVideoPage, arguments: {
                    //   "videoPath": controller.videoUrl,
                    //   "songId": controller.songId,
                    // });
                  },
                  child: Container(
                    height: 45,
                    width: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColor.primaryLinearGradient,
                    ),
                    child: LocalAssets(imagePath: AppIconAssets.trimmedIcon),
                  ),
                ),
              ),*/
              Positioned(
                bottom: 40,
                child: SizedBox(
                  width: Get.width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Get.width / 5),
                    child: PositiveCustomBtn(
                      title: "Next",
                      onTap: () {
                        // Get.to(
                          // CreateReelScreen(
                          //   videoPath: controller.videoUrl,
                          //   videoThumbNail:
                          //   controller.videoThumbnail,
                          //   videoUploadType: videoType,
                          // ),
                          // arguments: {"video": videoUrl, "image": videoThumbnail, "time": videoTime, "songId": songId},
                        // );
                      },
                    ),
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
