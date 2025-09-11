
import 'dart:io';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/message_post/photo_upload_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
  int _currentPage = 0;
  final msgPostController = Get.find<MessagePostController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.width * 0.5,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PageView.builder(
        itemCount: msgPostController.imagesList.length,
        scrollDirection: Axis.horizontal, // swipe left/right
        controller: PageController(viewportFraction: 1.0), // full width page
        itemBuilder: (context, index) {
          MessagePostImageModel imageData = msgPostController.imagesList[index];

          return Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      imageData.imgCropMode == AppConstants.Square ? 0 : 12),
                  child: Container(
                    height: Get.width * 0.5,
                    // height: Get.width * 1.09,
                    width: imageData.imgCropMode ==
                        AppConstants.Square
                        ? Get.width * 0.5
                        : double.parse(
                        imageData.imgWidth ??
                            Get.width.toString()),
                    // width:
                    // double.tryParse(imageData.imgWidth ?? "") ?? Get.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      image: DecorationImage(
                        image: FileImage(File(imageData.imageFile?.path ?? "")),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
              ),

              if (msgPostController.imagesList.length > 1)
              // --- Page Indicator ---
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      "${_currentPage + 1}/${msgPostController.imagesList.length}",
                      color: Colors.white,
                    ),
                  ),
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
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child:
                    const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),

              /// --- Debug: Show image width ---
            ],
          );
        },
      ),
    );
  }
}
