import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/controller/add_chat_symbol_controller.dart';


class StatusPreview extends StatelessWidget {
  const StatusPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddChatSymbolController>();

    return Obx(() {
      final type = controller.selectedPostType.value;

      // TEXT POST
      if (type == PostType.text) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: TextFormField(
              controller: controller.textPostController,
              maxLines: null,                 // unlimited lines
              expands: true,                  // fill available space
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: Colors.black,
              textInputAction: TextInputAction.done, // ✅ FINISH KEY
              style: const TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: "Type something...",
                hintStyle: TextStyle(
                  color: Colors.black45,
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,      // no underline
              ),
            ),
          ),
        );
      }

      // IMAGE/VIDEO NOT SELECTED
      if (controller.selectedFile.value == null) {
        return GestureDetector(
          onTap: () {
            _pickFromGallery(type == PostType.video, controller);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.backgroundBlur,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type == PostType.video
                        ? Icons.video_camera_back_outlined
                        : Icons.add_a_photo,
                    color: Colors.black,
                    size: 80,
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Main text
                  Text(
                    type == PostType.video ? "Select Video Symbol" : "Select Image Symbol",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 🔹 Helper text
                  Text(
                    type == PostType.video
                        ? "Tap here to choose a video"
                        : "Tap here to choose an image",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        ;
      }

      // IMAGE SELECTED
      return InkWell(
        onTap: ()async{
          _pickFromGallery(type == PostType.video,controller);
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color:  AppColors.backgroundBlur,
          child: type == PostType.video
              ? VideoPreview(file: controller.selectedFile.value!)
              : Image.file(
            controller.selectedFile.value!,
            fit: BoxFit.cover,
          ),
        ),
      );
    });
  }

  Future<void> _pickFromGallery(bool isVideo,AddChatSymbolController controller) async {
    final picker = ImagePicker();
    File? files;
    if (isVideo) {
      final XFile? pickedVideo = await picker.pickVideo(
          source: ImageSource.gallery);
      if (pickedVideo != null) {
        files=File(pickedVideo.path);
      }
    } else {
      final XFile? pickedImages = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImages != null ) {
        files= File(pickedImages.path);
      }
    }
    if (files!=null) {
      controller.selectedFile.value=files;
    }
  }


}
