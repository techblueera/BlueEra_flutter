import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_photo_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadHospitalPhotosScreen extends StatelessWidget {
  const UploadHospitalPhotosScreen({super.key});

  static const int _maxImages = 6;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HospitalPhotoController>();

    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.uploadPhotos),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              AppStrings.selectCategory,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(height: 10),
            Obx(
              () => CommonDropdownDialog<String>(
                title: AppStrings.selectCategory,
                hintText: AppStrings.hospitalViewEgRooms.tr,
                items: controller.categories,
                selectedValue: controller.selectedCategory.value.isEmpty
                    ? null
                    : controller.selectedCategory.value,
                displayValue: (cat) => cat,
                onChanged: controller.onCategoryChanged,
              ),
            ),
            const SizedBox(height: 20),
            CustomText(
              AppStrings.uploadLimitInfo,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 10),
            Obx(
              () => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: controller.selectedImages.length < _maxImages
                    ? controller.selectedImages.length + 1
                    : _maxImages,
                itemBuilder: (context, index) {
                  if (index == controller.selectedImages.length) {
                    return _buildUploadTile(context, controller);
                  }
                  return _buildImagePreview(controller, index);
                },
              ),
            ),
            const SizedBox(height: 40),
            Obx(() {
              final isProcessing = controller.isLoading.value;
              final canSubmit = controller.selectedCategory.isNotEmpty &&
                  controller.selectedImages.isNotEmpty &&
                  !isProcessing;
              return CustomBtn(
                title: isProcessing
                    ? AppStrings.uploadingLabel.tr
                    : AppStrings.submit.tr,
                isValidate: canSubmit,
                onTap: canSubmit ? controller.buildRequestBody : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile(
    BuildContext context,
    HospitalPhotoController controller,
  ) {
    return GestureDetector(
      onTap: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
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

  Widget _buildImagePreview(HospitalPhotoController controller, int index) {
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
  }
}
