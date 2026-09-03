import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_service_photo_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Second half of the automotive-service gallery upload: the photos are
/// already picked (see `OtherServicePhotosPhotoScreen._startUpload`), and this
/// screen is where they get a category.
///
/// **Photos first, category second.** This screen used to open with an empty
/// category dropdown and an empty photo grid, so the merchant had to name a
/// group before seeing a single picture. Now they choose pictures, then say
/// what the pictures are — and the grid arrives populated, with an add tile
/// for topping the selection up to
/// [OtherServicePhotoPhotoController.maxImages].
///
/// **The category is theirs.** It was a dropdown over fifteen hard-coded
/// HOTEL sections ("Lobby & Reception", "Swimming Pool", "Spa & Wellness", …)
/// that arrived with the hotel gallery this screen was copied from, and which
/// have nothing to say about a garage or a service centre. The gallery API
/// stores a free `title` per group and there is no server-side catalog of
/// sections, so the options are the categories this merchant has already
/// created, plus an **Other** option that opens a field for a new name.
class UploadOtherServicePhotosScreen extends StatefulWidget {
  const UploadOtherServicePhotosScreen({super.key});

  @override
  State<UploadOtherServicePhotosScreen> createState() =>
      _UploadOtherServicePhotosScreenState();
}

class _UploadOtherServicePhotosScreenState
    extends State<UploadOtherServicePhotosScreen> {
  final controller = Get.find<OtherServicePhotoPhotoController>();
  late final TextEditingController _categoryField;

  @override
  void initState() {
    super.initState();
    _categoryField =
        TextEditingController(text: controller.selectedCategory.value);
    // A merchant with no categories yet has nothing to choose BETWEEN, so the
    // "Other" branch is the only one there is — start on it rather than
    // showing a lone option they have to tap first.
    if (controller.existingCategories.isEmpty) {
      controller.chooseCustomCategory();
    }
  }

  @override
  void dispose() {
    _categoryField.dispose();
    super.dispose();
  }

  /// Tops the selection up, never past the cap. The picker is told how much
  /// room is left so the merchant can't pick eight and have five silently
  /// dropped.
  Future<void> _addMorePhotos() async {
    final room = controller.remainingImageSlots;
    if (room <= 0) {
      commonSnackBar(message: AppStrings.hotelLimitReached6Images.tr);
      return;
    }
    final paths = await PhotoPickerService.pickMultiplePhotos(
      context,
      AppStrings.otherUploadServicePhoto.tr,
      maxImages: room,
    );
    if (paths != null) controller.addImages(paths);
  }

  /// Switches to "Other" and puts the caret in the field, so naming a new
  /// category is one tap rather than tap-then-tap-the-field.
  void _chooseOther() {
    controller.chooseCustomCategory();
    _categoryField.clear();
  }

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
            // ── Step 1: the photos ──────────────────────────────────────
            Obx(() => CustomText(
                  '${AppStrings.hotelUploadImagesMaxSix.tr}  '
                  '(${controller.selectedImages.length}/${controller.maxImages})',
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(height: 10),
            Obx(() {
              final images = controller.selectedImages;
              final hasRoom = images.length < controller.maxImages;
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                // The add tile only exists while there is room for another
                // photo, so a full selection shows six photos and nothing else.
                itemCount: images.length + (hasRoom ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == images.length) return _buildAddTile();
                  return _buildImagePreview(images[index], index);
                },
              );
            }),

            SizedBox(height: 24),

            // ── Step 2: the category ────────────────────────────────────
            CustomText(AppStrings.otherGalleryCategoryLabel.tr,
                color: AppColors.mainTextColor, fontWeight: FontWeight.bold),
            SizedBox(height: 10),
            Obx(() {
              final categories = controller.existingCategories;
              final isCustom = controller.isCustomCategory.value;
              final selected = controller.selectedCategory.value.trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in categories)
                        _categoryChip(
                          category,
                          isSelected: !isCustom &&
                              category.toLowerCase() == selected.toLowerCase(),
                          onTap: () {
                            controller.selectExistingCategory(category);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      // Always last, always present — the way a merchant adds
                      // a category the list doesn't have yet.
                      _categoryChip(
                        AppStrings.otherGalleryOtherCategory.tr,
                        isSelected: isCustom,
                        onTap: _chooseOther,
                        icon: Icons.add,
                      ),
                    ],
                  ),
                  // The name field belongs to the "Other" branch only —
                  // showing it alongside a chosen existing category would give
                  // two controls claiming the same value.
                  if (isCustom) ...[
                    SizedBox(height: 12),
                    TextField(
                      controller: _categoryField,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onChanged: controller.onCategoryChanged,
                      decoration: InputDecoration(
                        hintText: AppStrings.otherGalleryCategoryHint.tr,
                        hintStyle:
                            TextStyle(color: AppColors.grey9B, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.greyE5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.greyE5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: AppColors.primaryColor, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),

            SizedBox(height: 40),
            Obx(() {
              // `canSubmitUpload` trims the category, so a name of nothing but
              // spaces no longer enables the button (and can't be saved as a
              // blank-looking category).
              final canSubmit = controller.canSubmitUpload;
              return CustomBtn(
                title: AppStrings.submit.tr,
                isValidate: canSubmit,
                onTap: canSubmit
                    ? () {
                        if (controller.selectedCategory.value.trim().isEmpty) {
                          commonSnackBar(
                              message: AppStrings.hotelErrorSelectCategory.tr);
                        } else if (controller.selectedImages.isEmpty) {
                          commonSnackBar(
                              message: AppStrings.hotelErrorUploadOneImage.tr);
                        } else {
                          controller.buildRequestBody();
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

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _addMorePhotos,
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

  Widget _buildImagePreview(String path, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
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
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// One category option. Selected state is a fill + border change rather than
  /// a check mark, so the row stays the same width as the merchant taps
  /// through it.
  Widget _categoryChip(
    String category, {
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final foreground =
        isSelected ? AppColors.primaryColor : AppColors.secondaryTextColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            CustomText(
              category,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: foreground,
            ),
          ],
        ),
      ),
    );
  }
}
