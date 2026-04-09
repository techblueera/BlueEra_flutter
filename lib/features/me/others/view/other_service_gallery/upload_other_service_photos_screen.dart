import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/others/controller/other_service_photo_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadOtherServicePhotosScreen extends StatelessWidget {
  final controller = Get.find<OtherServicePhotoPhotoController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.hotelUploadImages.tr,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(AppStrings.hotelSelectCategoryLabel.tr, color: AppColors.mainTextColor),
            SizedBox(height: 10),
            // Dropdown using the String list
            Obx(() => CommonDropdownDialog<String>(
                  title: AppStrings.hotelSelectCategoryDialog.tr,
                  hintText: AppStrings.hotelHintRooms.tr,
                  items: controller.categories,
                  selectedValue: controller.selectedCategory.value.isEmpty
                      ? null
                      : controller.selectedCategory.value,
                  displayValue: (cat) => cat,
                  onChanged: (value) => controller.onCategoryChanged(value),
                )),

            SizedBox(height: 20),
            CustomText(AppStrings.hotelUploadImagesMaxSix.tr,
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
                title: AppStrings.submit.tr,
                isValidate: controller.selectedCategory.value.isNotEmpty &&
                    controller.selectedImages.isNotEmpty,
                onTap: controller.selectedCategory.value.isNotEmpty &&
                        controller.selectedImages.isNotEmpty
                    ? () {
                        if (controller.selectedCategory.isEmpty) {
                          commonSnackBar(
                              message: AppStrings.hotelErrorSelectCategory.tr);
                        } else if (controller.selectedImages.isEmpty) {
                          commonSnackBar(
                              message: AppStrings.hotelErrorUploadOneImage.tr);
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
