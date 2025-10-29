import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/feed_video_preview_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhotoUploadWidget extends StatefulWidget {
  PhotoUploadWidget({super.key, this.isFromRepost = false});

  final bool isFromRepost;

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final msgController = Get.find<MessagePostController>();

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
                      ? "Upload Photo or Video"
                      : "Upload Photo or Video (at least 1 media required)")),
              SizedBox(height: SizeConfig.size10),
              if (msgController.selectedType.value == null) ...[
                addPhotoWidget(),
                SizedBox(
                  height: 20,
                ),
                addVideoWidget()
              ],
              if (msgController.selectedType.value?.name ==
                  MediaType.image.name)
                addPhotoWidget(),
              if (msgController.selectedType.value?.name ==
                  MediaType.video.name)
                addVideoWidget(),
              SizedBox(height: SizeConfig.size10),
              msgController.imagesList.isNotEmpty
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            msgController.selectedType.value == MediaType.video
                                ? 1
                                : 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: msgController.imagesList.length,
                      itemBuilder: (context, index) {
                        final file = msgController.imagesList[index];
                        final isVideo =
                            msgController.selectedType.value == MediaType.video;

                        return GestureDetector(
                          onTap: isVideo ? () => openVideoPreview(file) : null,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Obx(() {
                                final thumb =
                                    msgController.videoThumbnails[file.path];

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: isVideo
                                      ? (thumb != null
                                          ? Image.file(thumb, fit: BoxFit.cover)
                                          : Container(
                                              color: Colors.black12,
                                              child: const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            ))
                                      : Image.file(file, fit: BoxFit.cover),
                                );
                              }),
                              if (isVideo)
                                const Center(
                                  child: Icon(Icons.play_circle_fill,
                                      color: Colors.white, size: 40),
                                ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () => msgController.removeMedia(index),
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
                    )
                  : SizedBox.shrink(),
            ],
          ),
        );
      }),
    );
  }

  Widget addPhotoWidget() {
    return InkWell(
      onTap: () async {
        if (msgController.imagesList.length < 4) {
          msgController.pickMedia();
        }
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
                "Add Photo ",
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.medium15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget addVideoWidget() {
    return InkWell(
      onTap: () async {
        msgController.pickVideoMedia();
      },
      child: Container(
        width: SizeConfig.screenWidth,
        height: SizeConfig.size50 + 2,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
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
                "Add Video ",
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.medium15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void openVideoPreview(File file) {
  Get.to(VideoPreviewScreen(file: file));
}
