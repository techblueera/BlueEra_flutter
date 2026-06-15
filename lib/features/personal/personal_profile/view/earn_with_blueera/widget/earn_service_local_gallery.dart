import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A horizontal gallery widget for earn-service profile screens.
///
/// Layout pattern (repeating every 3 images):
///   ┌──────────┬──────────┐
///   │          │  slot 2  │
///   │  slot 1  ├──────────┤
///   │          │  slot 3  │
///   └──────────┴──────────┘
///
/// Empty slots show a blurred placeholder. Filled slots show the image with a
/// remove (×) button. Tapping an empty slot triggers [onAddImage].
class EarnServiceLocalGallery extends StatelessWidget {
  final RxList<String> images;
  final VoidCallback onAddImage;

  /// Optional overrides. When null, the localized defaults
  /// ([AppStrings.youHaveNotPostPhotoGallery] / [AppStrings.uploadPhotoTitle])
  /// are used — resolved at build time so they react to locale.
  final String? emptyTitle;
  final String? addButtonLabel;

  const EarnServiceLocalGallery({
    super.key,
    required this.images,
    required this.onAddImage,
    this.emptyTitle,
    this.addButtonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.gallery.tr,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() {
          if (images.isEmpty) {
            return _buildEmptyState();
          }
          return _buildGalleryGrid();
        }),
      ],
    );
  }

  /// Full empty state — blurred background with upload button.
  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: onAddImage,
      child: Container(
        height: SizeConfig.size200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(AppImageAssets.homeMadeFoodBanner),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 40,
                  color: AppColors.white,
                ),
                SizedBox(height: 6),
                CustomText(
                  emptyTitle ?? AppStrings.youHaveNotPostPhotoGallery.tr,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                _buildUploadButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal scrollable gallery built from groups of 3.
  Widget _buildGalleryGrid() {
    final int totalImages = images.length;
    final int groupCount = (totalImages ~/ 3) + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        // Single group: take full width. Multiple groups: each takes 80% for peek effect.
        final bool singleGroup = groupCount == 1;
        final double groupWidth =
            singleGroup ? availableWidth : availableWidth * 0.80;

        return SizedBox(
          height: SizeConfig.size200,
          child: singleGroup
              ? _buildGroup(0, totalImages, availableWidth)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: groupCount,
                  separatorBuilder: (_, __) => SizedBox(width: 8),
                  itemBuilder: (_, groupIndex) {
                    final int baseIndex = groupIndex * 3;
                    return _buildGroup(baseIndex, totalImages, groupWidth);
                  },
                ),
        );
      },
    );
  }

  /// One group: left tall slot + right two stacked slots.
  Widget _buildGroup(int baseIndex, int totalImages, double groupWidth) {
    final double halfHeight = (SizeConfig.size200 - 8) / 2;

    return SizedBox(
      width: groupWidth,
      child: Row(
        children: [
          // Left — tall single slot
          Expanded(
            child: _buildSlot(baseIndex, totalImages, SizeConfig.size200),
          ),
          SizedBox(width: 8),
          // Right — two stacked slots
          Expanded(
            child: Column(
              children: [
                _buildSlot(baseIndex + 1, totalImages, halfHeight),
                SizedBox(height: 8),
                _buildSlot(baseIndex + 2, totalImages, halfHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single slot — either a filled image with remove button or a blurred
  /// placeholder that triggers [onAddImage].
  Widget _buildSlot(int index, int totalImages, double height) {
    final bool hasImage = index < totalImages;

    if (hasImage) {
      return _buildFilledSlot(index, height);
    }
    return _buildEmptySlot(height);
  }

  Widget _buildFilledSlot(int index, double height) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(images[index]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => images.removeAt(index),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(double height) {
    return GestureDetector(
      onTap: onAddImage,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage(AppImageAssets.homeMadeFoodBanner),
            fit: BoxFit.cover,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.white.withValues(alpha: 0.7),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        addButtonLabel ?? AppStrings.uploadPhotoTitle.tr,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }
}
