import 'dart:io';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/edit_photo_feed_widget.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;

class LocalMediaGrid extends StatelessWidget {
  final List<File> files;
  final bool isVideo;
  final Map<String, File?> videoThumbnails;
  final Function(int index)? onEditTap;
  final Function(int index)? onTapMedia;

  LocalMediaGrid({
    super.key,
    required this.files,
    required this.isVideo,
    required this.videoThumbnails,
    this.onEditTap,
    this.onTapMedia,
  });

  final msgPostController = Get.find<MessagePostController>();

  @override
  Widget build(BuildContext context) {
    final count = files.length;
    if (count == 0) return const SizedBox();

    /// --------------------------
    /// 1 IMAGE
    /// --------------------------
    if (count == 1) {
      final thumb = msgPostController.videoThumbnails[files.firstOrNull?.path];

      return isVideo
          ?
   buildVideoMediaStack(File(files.firstOrNull?.path??""), 0, thumb)

      /*ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (thumb != null
                  ? Image.file(thumb, fit: BoxFit.cover)
                  : Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    )),
            )*/
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: mediaPreview(
                  isVideo
                      ? File(videoThumbnails.values.first?.path ?? "")
                      : files[0],
                  0,
                  borderRadius: 12,
                  isSingle: true),
            );
    }

    /// --------------------------
    /// 2 IMAGES → LEFT + RIGHT
    /// --------------------------
    if (count == 2) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (_, index) {
          return ClipRRect(
            borderRadius: index == 0
                ? const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
            child: mediaPreview(files[index], index),
          );
        },
      );
    }

    /// --------------------------
    /// 3 IMAGES → 1 LARGE LEFT + 2 STACKED RIGHT
    /// --------------------------
    if (count == 3) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: mediaPreview(files[0], 0),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                      ),
                      child: mediaPreview(files[1], 1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                      child: mediaPreview(files[2], 2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    /// --------------------------
    /// 4 IMAGES → 2x2 GRID
    /// --------------------------
    if (count == 4) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (_, index) {
          return ClipRRect(
            borderRadius: index == 0
                ? const BorderRadius.only(topLeft: Radius.circular(12))
                : index == 1
                    ? const BorderRadius.only(topRight: Radius.circular(12))
                    : index == 2
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(12))
                        : const BorderRadius.only(
                            bottomRight: Radius.circular(12)),
            child: mediaPreview(files[index], index),
          );
        },
      );
    }

    /// --------------------------
    /// MORE THAN 4 → SHOW +X ON LAST CELL
    /// --------------------------
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (_, index) {
        final isLast = index == 3;
        final extraCount = files.length - 4;

        return Stack(
          children: [
            ClipRRect(
              borderRadius: index == 0
                  ? const BorderRadius.only(topLeft: Radius.circular(12))
                  : index == 1
                      ? const BorderRadius.only(topRight: Radius.circular(12))
                      : index == 2
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(12))
                          : const BorderRadius.only(
                              bottomRight: Radius.circular(12)),
              child: mediaPreview(files[index], index),
            ),

            /// +X Overlay
            if (isLast && extraCount > 0)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "+$extraCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> getImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return {
      "width": frame.image.width,
      "height": frame.image.height,
    };
  }

  /// ------------------------------
  /// COMMON PREVIEW FOR IMAGE/VIDEO
  /// ------------------------------
  Widget mediaPreview(File file, int index,
      {double borderRadius = 0, bool isSingle = false}) {
    final thumb = videoThumbnails[file.path];

    return FutureBuilder<Map<String, int>>(
      future: getImageSize(file), // get width & height
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 300,
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final width = snapshot.data!["width"]!;
        final height = snapshot.data!["height"]!;
        final bool isPortrait = height > width;

        /// --------------------------------
        /// SINGLE IMAGE (No constraints)
        /// --------------------------------
        if (isSingle) {
          double displayHeight;

          if (isPortrait) {
            displayHeight = 300; // portrait fixed height
          } else {
            displayHeight = (Get.width * (height / width)); // dynamic landscape
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(
              height: displayHeight,
              width: double.infinity,
              child: buildMediaStack(file, index, thumb),
            ),
          );
        }

        /// --------------------------------
        /// GRID MODE (Constrained)
        /// --------------------------------
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 400,
              minHeight: 150,
            ),
            child: buildMediaStack(file, index, thumb),
          ),
        );
      },
    );
  }

  Widget buildMediaStack(File file, int index, File? thumb) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InkWell(
          onTap: isVideo
              ? () => onTapMedia?.call(index)
              : () => Get.to(
                    ImageViewScreen(
                      subTitle: "",
                      appBarTitle: AppStrings.imageViewer.tr,
                      imageUrls: [file.path],
                      initialIndex: 0,
                    ),
                  ),
          child: isVideo
              ? (thumb != null
                  ? Image.file(thumb, fit: BoxFit.cover)
                  : Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    ))
              : Image.file(file, fit: BoxFit.cover),
        ),
        if (isVideo)
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
          ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: () => onEditTap?.call(index),
            child: LocalAssets(imagePath: AppIconAssets.round_black_edit),
          ),
        ),
      ],
    );
  }
  Widget buildVideoMediaStack(File file, int index, File? thumb) {
    return Stack(
      // fit: StackFit.expand,
      children: [
        InkWell(
          onTap:() => onTapMedia?.call(index),

          child:(thumb != null
                  ? Image.file(thumb, fit: BoxFit.cover)
                  : Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    ))
             ,
        ),
        if (isVideo)
          Positioned(
              bottom: 0,
              right: 0,
              left:0 ,top: 0,
              child: InkWell(

                  onTap:() => onTapMedia?.call(index),

                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40))),
        Positioned(
          bottom: 10,
          right: 10,

          child: GestureDetector(
            onTap: () => onEditTap?.call(index),
            child: LocalAssets(imagePath: AppIconAssets.round_black_edit),
          ),
        ),
      ],
    );
  }
}

class InstaSlider extends StatefulWidget {
  const InstaSlider({
    super.key,
  });

  @override
  State<InstaSlider> createState() => _InstaSliderState();
}

class _InstaSliderState extends State<InstaSlider> {
  final msgPostController = Get.find<MessagePostController>();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: msgPostController.imagesList.length == 1 ? 1 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: msgPostController.imagesList.length,
      itemBuilder: (context, index) {
        final file = msgPostController.imagesList[index];
        final isVideo = msgPostController.selectedType.value == MediaType.video;

        return GestureDetector(
          onTap: isVideo ? () => openVideoPreview(file) : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Obx(() {
                final thumb = msgPostController.videoThumbnails[file.path];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isVideo
                      ? (thumb != null
                          ? Image.file(thumb, fit: BoxFit.cover)
                          : Container(
                              color: Colors.black12,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ))
                      : Image.file(file, fit: BoxFit.cover),
                );
              }),
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 40),
                ),
              // --- Edit Button ---
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    Get.off(PhotoListingWidget());
                    // Handle edit action
                  },
                  child: LocalAssets(imagePath: AppIconAssets.round_black_edit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
