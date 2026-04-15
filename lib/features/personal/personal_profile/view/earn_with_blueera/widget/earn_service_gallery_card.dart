import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Earn-service profile gallery card.
///
/// - Empty state: full blurred banner with upload CTA.
/// - Populated state: groups of 3 (tall left + two stacked right), each image
///   opens [ImageViewScreen] on tap and has a ✕ remove button.
class EarnServiceGalleryCard extends StatelessWidget {
  final List<String>? gallery;
  final Future<void> Function() onAddImage;
  final Future<void> Function(int index) onRemoveImage;
  final String emptyTitle;
  final String addButtonLabel;

  const EarnServiceGalleryCard({
    super.key,
    this.gallery,
    required this.onAddImage,
    required this.onRemoveImage,
    this.emptyTitle = 'You Have Not Post Photo In Your\nGallery',
    this.addButtonLabel = 'Upload Photo',
  });

  @override
  Widget build(BuildContext context) {
    final images = gallery ?? const <String>[];
    final hasGallery = images.isNotEmpty;

    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Menu/${AppStrings.gallery.tr}',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              if (hasGallery)
                InkWell(
                  onTap: onAddImage,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add,
                            size: 14, color: AppColors.primaryColor),
                        const SizedBox(width: 4),
                        CustomText(
                          'Add',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          hasGallery ? _buildGalleryGrid(context, images) : _buildEmptyState(),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────
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
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 40,
                  color: AppColors.white,
                ),
                const SizedBox(height: 6),
                CustomText(
                  emptyTitle,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(
                    addButtonLabel,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Populated grid ──────────────────────────────────────────────
  Widget _buildGalleryGrid(BuildContext context, List<String> images) {
    final total = images.length;
    final groupCount = (total / 3).ceil();
    final tallHeight = SizeConfig.size280;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final availableWidth = constraints.maxWidth;
        final singleGroup = groupCount == 1;
        final groupWidth =
            singleGroup ? availableWidth : availableWidth * 0.85;

        return SizedBox(
          height: tallHeight,
          child: singleGroup
              ? _buildGroup(
                  context, images, baseIndex: 0, groupWidth: availableWidth,
                  tallHeight: tallHeight)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: groupCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, groupIndex) => _buildGroup(
                    context,
                    images,
                    baseIndex: groupIndex * 3,
                    groupWidth: groupWidth,
                    tallHeight: tallHeight,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildGroup(
    BuildContext context,
    List<String> images, {
    required int baseIndex,
    required double groupWidth,
    required double tallHeight,
  }) {
    final halfHeight = (tallHeight - 8) / 2;
    return SizedBox(
      width: groupWidth,
      child: Row(
        children: [
          Expanded(
            child: _buildSlot(context, images, baseIndex, tallHeight),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                _buildSlot(context, images, baseIndex + 1, halfHeight),
                const SizedBox(height: 8),
                _buildSlot(context, images, baseIndex + 2, halfHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(
      BuildContext context, List<String> images, int index, double height) {
    if (index < images.length) {
      return _buildFilledSlot(context, images, index, height);
    }
    return _buildEmptySlot(height);
  }

  Widget _buildFilledSlot(
      BuildContext context, List<String> images, int index, double height) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewScreen(
                    appBarTitle: AppStrings.imageViewer,
                    subTitle: AppStrings.imageViewer,
                    imageUrls: images,
                    initialIndex: index,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
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
}
