
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/edit_photo_feed_widget.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      gridDelegate:
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
        msgPostController.imagesList.length==1
            ? 1
            : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount:
      msgPostController.imagesList.length,
      itemBuilder: (context, index) {
        final file =
        msgPostController.imagesList[index];
        final isVideo =
            msgPostController.selectedType.value ==
                MediaType.video;

        return GestureDetector(
          onTap: isVideo
              ? () => openVideoPreview(file)
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Obx(() {
                final thumb = msgPostController
                    .videoThumbnails[file.path];

                return ClipRRect(
                  borderRadius:
                  BorderRadius.circular(8),
                  child: isVideo
                      ? (thumb != null
                      ? Image.file(thumb,
                      fit: BoxFit.cover)
                      : Container(
                    color: Colors.black12,
                    child: const Center(
                        child:
                        CircularProgressIndicator()),
                  ))
                      : Image.file(file,
                      fit: BoxFit.cover),
                );
              }),
              if (isVideo)
                const Center(
                  child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 40),
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
