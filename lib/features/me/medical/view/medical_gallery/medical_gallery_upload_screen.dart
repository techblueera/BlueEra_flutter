import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/medical/controller/medical_gallery_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Second half of the medical gallery upload: the photos are already picked
/// (see `MedicalGalleryListScreen._startUpload`), and this screen is where they
/// get an album.
///
/// **Photos first, album second.** This screen used to open with an empty
/// dropdown and an empty photo grid, so a group had to be named before a
/// single picture was visible. Now the pictures are chosen first and named
/// second — the grid arrives populated, with an add tile for topping the
/// selection up to [MedicalGalleryController.maxImages].
///
/// **The album name is theirs.** It was a dropdown over six fixed entries,
/// each a `.tr` lookup — so the string stored as the album `title` was
/// whatever the device language rendered, and the same shelf became a
/// different album on a Hindi phone than on an English one. Names are now
/// entered by the pharmacy and stored verbatim: the options are the albums it
/// has already created, plus an **Other** option that opens a field for a new
/// name.
class MedicalGalleryUploadScreen extends StatefulWidget {
  const MedicalGalleryUploadScreen({super.key});

  @override
  State<MedicalGalleryUploadScreen> createState() =>
      _MedicalGalleryUploadScreenState();
}

class _MedicalGalleryUploadScreenState extends State<MedicalGalleryUploadScreen> {
  final controller = Get.find<MedicalGalleryController>();
  late final TextEditingController _categoryField;

  @override
  void initState() {
    super.initState();
    _categoryField =
        TextEditingController(text: controller.selectedCategory.value);
    // A pharmacy with no albums yet has nothing to choose BETWEEN, so the
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
  /// room is left so eight can't be picked and five silently dropped.
  Future<void> _addMorePhotos() async {
    final room = controller.remainingImageSlots;
    if (room <= 0) return;
    final paths = await PhotoPickerService.pickMultiplePhotos(
      context,
      AppStrings.uploadPhotos.tr,
      maxImages: room,
    );
    if (paths != null) controller.addImages(paths);
  }

  /// Switches to "Other" and clears the field, so naming a new album is one
  /// tap rather than tap-then-clear-the-old-name.
  void _chooseOther() {
    controller.chooseCustomCategory();
    _categoryField.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `.tr` on each of these: they are translation KEYS, and without it this
      // screen literally rendered "uploadImages" and "select_images_limit" to
      // the pharmacy.
      appBar: CommonBackAppBar(title: AppStrings.uploadImages.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step 1: the photos ──────────────────────────────────────
            Obx(() => CustomText(
                  '${AppStrings.selectImagesLimit.tr}  '
                  '(${controller.selectedImages.length}/${controller.maxImages})',
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 10),
            Obx(() {
              final images = controller.selectedImages;
              final hasRoom = images.length < controller.maxImages;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

            const SizedBox(height: 24),

            // ── Step 2: the album ───────────────────────────────────────
            CustomText(
              AppStrings.otherGalleryCategoryLabel.tr,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 10),
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
                      // Always last, always present — the way a new album that
                      // the list doesn't have yet gets added.
                      _categoryChip(
                        AppStrings.otherGalleryOtherCategory.tr,
                        isSelected: isCustom,
                        onTap: _chooseOther,
                        icon: Icons.add,
                      ),
                    ],
                  ),
                  // The name field belongs to the "Other" branch only — showing
                  // it alongside a chosen existing album would give two
                  // controls claiming the same value.
                  if (isCustom) ...[
                    const SizedBox(height: 12),
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

            const SizedBox(height: 40),

            // Submit button
            Obx(() {
              // `canSubmitUpload` trims the album name, so a name of nothing
              // but spaces no longer enables the button.
              final isUploading = controller.isUploading.value;
              final canSubmit = controller.canSubmitUpload && !isUploading;
              return CustomBtn(
                title: isUploading
                    ? AppStrings.uploadingLabel.tr
                    : AppStrings.submit.tr,
                isValidate: canSubmit,
                isLoading: isUploading,
                onTap: canSubmit ? controller.uploadAndCreateGallery : null,
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
        child: const Icon(Icons.add_a_photo, color: Colors.grey),
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

  /// One album option. Selected state is a fill + border change rather than a
  /// check mark, so the row stays the same width as options are tapped
  /// through.
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
