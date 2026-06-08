import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hotel/controller/property_photo_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Picks 1–6 photos and the album category to upload them under. The system
/// back gesture is blocked while the upload is in flight via [PopScope].
class UploadPropertyPhotosScreen extends StatelessWidget {
  UploadPropertyPhotosScreen({super.key});

  final controller = getOrPut(() => PropertyPhotoController());

  static const int _maxImages = 6;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      return PopScope(
        canPop: !isLoading,
        child: Scaffold(
          appBar: CommonBackAppBar(title: AppStrings.hotelUploadImages.tr),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.hotelSelectCategoryLabel.tr,
                      color: AppColors.mainTextColor,
                    ),
                    const SizedBox(height: 10),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 20),
                    CustomText(
                      AppStrings.hotelUploadImagesMaxSix.tr,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 10),
                    _buildImageGrid(context),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
              if (isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoryDropdown() {
    return Obx(() => CommonDropdownDialog<String>(
          title: AppStrings.hotelSelectCategoryDialog.tr,
          hintText: AppStrings.hotelHintRooms.tr,
          items: controller.categories,
          selectedValue: controller.selectedCategory.value.isEmpty
              ? null
              : controller.selectedCategory.value,
          displayValue: (cat) => controller.categoryLabel(cat),
          onChanged: controller.onCategoryChanged,
        ));
  }

  Widget _buildImageGrid(BuildContext context) {
    return Obx(() {
      final picked = controller.selectedImages.length;
      final itemCount = picked < _maxImages ? picked + 1 : _maxImages;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: itemCount,
        itemBuilder: (_, index) {
          final isUploadSlot = index == picked && index < _maxImages;
          if (isUploadSlot) return _buildUploadSlot(context);
          return _buildImagePreview(index);
        },
      );
    });
  }

  Widget _buildUploadSlot(BuildContext context) {
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

  Widget _buildImagePreview(int index) {
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

  Widget _buildSubmitButton() {
    return Obx(() {
      final canSubmit = controller.selectedCategory.value.isNotEmpty &&
          controller.selectedImages.isNotEmpty;
      return CustomBtn(
        title: AppStrings.submit.tr,
        isValidate: canSubmit,
        onTap: canSubmit ? controller.buildRequestBody : null,
      );
    });
  }
}
