import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_box_shadow.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';
import '../../../../common/post/message_post/feed_video_preview_widget.dart';
import '../../../auth/controller/add_chat_symbol_controller.dart';

class SymbolUploadWidget extends StatefulWidget {
  SymbolUploadWidget({super.key, this.isFromRepost = false});

  final bool isFromRepost;

  @override
  State<SymbolUploadWidget> createState() => _SymbolUploadWidgetState();
}

class _SymbolUploadWidgetState extends State<SymbolUploadWidget> {
  final controller = Get.isRegistered<AddChatSymbolController>()
      ? Get.find<AddChatSymbolController>()
      : Get.put(AddChatSymbolController());

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Obx(() {
        return SingleChildScrollView(
          child: Column(
            children: [
              if(controller.itMediaPost())
              Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  widget.isFromRepost
                      ? AppStrings.uploadPhotoOrVideo.tr
                      : AppStrings.uploadPhotoOrVideoRequired.tr,
                ),
              ),
              if(controller.itMediaPost())
              SizedBox(height: SizeConfig.size10),

              if (controller.selectedPostType.value == null) ...[
                addOptionWidget(
                  title: AppStrings.addPhoto.tr,
                  iconPath: AppIconAssets.black_gallery,
                  onTap: () {
                    if (controller.imagesList.length < 4) {
                      controller.pickMedia();
                    }
                  },
                ),

                SizedBox(height: 20),

                addOptionWidget(
                  title: AppStrings.addVideo.tr,
                  iconPath: AppIconAssets.black_gallery,
                  onTap: () {
                    controller.pickVideoMedia();
                  },
                ),

                SizedBox(height: 20),

                addOptionWidget(
                  title: "Add Text",
                  iconPath: AppIconAssets.pen,
                  onTap: () {
                    controller.choosePostType(PostType.text);
                    // add text action
                  },
                ),

                SizedBox(height: 20),

                addOptionWidget(
                  title: "Add Link",
                  iconPath: AppIconAssets.link,
                  onTap: () {
                    controller.choosePostType(PostType.link);
                  },
                ),

              ],

              // if (controller.selectedPostType.value?.name == PostType)
              //   addOptionWidget(
              //     title: AppStrings.addPhoto.tr,
              //     iconPath: AppIconAssets.black_gallery,
              //     onTap: () {
              //       if (controller.imagesList.length < 4) {
              //         controller.pickMedia();
              //       }
              //     },
              //   ),
              //
              //
              // if (controller.selectedPostType.value?.name == PostType.video.name)
              //   addOptionWidget(
              //     title: AppStrings.addVideo.tr,
              //     iconPath: AppIconAssets.black_gallery,
              //     onTap: () {
              //       controller.pickVideoMedia();
              //     },
              //   ),

              SizedBox(height: SizeConfig.size10),

              controller.imagesList.isNotEmpty
                  ? GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                  controller.selectedPostType.value == PostType.video
                      ? 1
                      : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: controller.imagesList.length,
                itemBuilder: (context, index) {
                  final file = controller.imagesList[index];
                  final isVideo =
                      controller.selectedPostType.value == PostType.video;

                  return GestureDetector(
                    onTap: isVideo ? () => openVideoPreview(file) : null,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Obx(() {
                          final thumb =
                          controller.videoThumbnails[file.path];

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
                            onTap: () =>
                                controller.removeMedia(index),
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

  Widget addOptionWidget({
    required VoidCallback onTap,
    required String title,
    required String iconPath,
    Color iconColor = AppColors.black,
  }) {
    return InkWell(
      onTap: onTap,
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
              LocalAssets(
                imagePath: iconPath,
                imgColor: iconColor,
                height: 16,
                width: 16,
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                title,
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
