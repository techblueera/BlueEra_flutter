import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_gallery_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalGalleryUploadScreen extends StatelessWidget {
  final controller = Get.find<MedicalGalleryController>();

  MedicalGalleryUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.uploadImages),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category dropdown
            CustomText(AppStrings.selectCategory, color: AppColors.mainTextColor),
            const SizedBox(height: 10),
            Obx(() => CommonDropdownDialog<String>(
                  title: AppStrings.selectCategory,
                  hintText: AppStrings.interiorPhotosHint.tr,
                  items: controller.categories,
                  selectedValue: controller.selectedCategory.value.isEmpty
                      ? null
                      : controller.selectedCategory.value,
                  displayValue: (cat) => cat,
                  onChanged: (value) => controller.onCategoryChanged(value),
                )),

            const SizedBox(height: 20),
            CustomText(AppStrings.selectImagesLimit, fontWeight: FontWeight.bold),
            const SizedBox(height: 10),

            // Image grid (max 6)
            Obx(() => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: controller.selectedImages.length < 6
                      ? controller.selectedImages.length + 1
                      : 6,
                  itemBuilder: (context, index) {
                    // Add-image tile
                    if (index == controller.selectedImages.length && index < 6) {
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
                          child: const Icon(Icons.add_a_photo, color: Colors.grey),
                        ),
                      );
                    }

                    // Image preview with delete
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
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )),

            const SizedBox(height: 40),

            // Submit button
            Obx(() {
              final isValid = controller.selectedCategory.value.isNotEmpty &&
                  controller.selectedImages.isNotEmpty;
              return CustomBtn(
                title: controller.isUploading.value
                    ? AppStrings.uploadingLabel
                    : AppStrings.submit,
                isValidate: isValid && !controller.isUploading.value,
                isLoading: controller.isUploading.value,
                onTap: isValid && !controller.isUploading.value
                    ? () => controller.uploadAndCreateGallery()
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}
