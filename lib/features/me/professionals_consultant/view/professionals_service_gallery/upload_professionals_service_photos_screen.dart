import 'dart:io';

import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_service_photo_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadProfessionalsServicePhotosScreen extends StatefulWidget {
  @override
  State<UploadProfessionalsServicePhotosScreen> createState() => _UploadProfessionalsServicePhotosScreenState();
}

class _UploadProfessionalsServicePhotosScreenState extends State<UploadProfessionalsServicePhotosScreen> {
  final controller = Get.find<ProfessionalsServicePhotoPhotoController>();
@override
  void initState() {
    // TODO: implement initState
  controller.selectedImages.clear();
  super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Upload Images",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            CustomText("Upload Images (Min 1, Max 6)",
                fontWeight: FontWeight.bold),
            SizedBox(height: 10),

            // Image Grid
            Obx(() => GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: controller.selectedImages.length < 6
                      ? controller.selectedImages.length + 1
                      : 6,
                  itemBuilder: (context, index) {
                    // Upload Tile
                    if (index == controller.selectedImages.length &&
                        index < 6) {
                      return GestureDetector(
                        onTap: () async {
                          final path = await CommonImageUploadTile.pickImage(
                              context: context);
                          if (path != null) controller.addImage(path);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Icon(Icons.add_a_photo, color: Colors.grey),
                        ),
                      );
                    }

                    // Image Preview with Delete Option
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(controller.selectedImages[index]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => controller.removeImage(index),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )),

            SizedBox(height: 40),
            Obx(() {
              return CustomBtn(
                title: "Submit",
                isValidate:
                    controller.selectedImages.isNotEmpty,
                onTap:
                        controller.selectedImages.isNotEmpty
                    ? () {
                       if (controller.selectedImages.isEmpty) {

                          commonSnackBar(
                              message: "Error Please upload at least 1 image");
                        } else {
                          controller.buildRequestBody();
                          // Call your API upload logic here
                        }
                      }
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}
