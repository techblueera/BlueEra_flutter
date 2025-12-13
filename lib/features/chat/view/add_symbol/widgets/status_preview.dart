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
          color:  AppColors.backgroundBlur,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              controller.textPostController.text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      // IMAGE/VIDEO NOT SELECTED
      if (controller.selectedFile.value == null) {
        return GestureDetector(
          onTap: () {
            _pickFromGallery(type == PostType.video,controller);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.backgroundBlur,
            child: const Center(
              child: Icon(Icons.add_a_photo, color: Colors.black, size: 80),
            ),
          ),
        );
      }

      // IMAGE SELECTED
      return InkWell(
        onTap: ()async{

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
