import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_listing_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_details_res_model.dart';

class CampusPhotoGallery extends StatelessWidget {
  final List<CampusLife> campusLife;
  final List<String>? galleryPhotos;
  final bool isEdit;

  const CampusPhotoGallery({
    super.key,
    required this.campusLife,
    this.galleryPhotos,
    this.isEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> allImages = [];

    // 1. Collect photos from the top-level gallery field
    if (galleryPhotos != null) {
      for (var url in galleryPhotos!) {
        if (url.trim().isNotEmpty) allImages.add(url);
      }
    }

    // 2. Collect photos from all campus life categories
    for (var item in campusLife) {
      for (Images img in item.images ?? []) {
        final url = img.url?.trim() ?? '';
        if (url.isNotEmpty) allImages.add(url);
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "Gallery",
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                ),
                if (isEdit)
                  _AddPhotoPill(
                      onTap: () => Get.to(CampusLifeListingScreen())),
              ],
            ),
            const SizedBox(height: 12),
            if (allImages.isEmpty)
              GestureDetector(
                onTap: isEdit ? () => Get.to(CampusLifeListingScreen()) : null,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          color: Colors.grey[400], size: 48),
                      const SizedBox(height: 8),
                      CustomText(
                        AppStrings.noDataFound.tr,
                        color: AppColors.secondaryTextColor,
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Get.to(CampusLifeListingScreen()),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Add"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: BorderSide(color: AppColors.primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              _buildGalleryLayout(context, allImages),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryLayout(BuildContext context, List<String> images) {
    void openViewer(int index) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: images,
            initialIndex: index,
          ),
        );

    Widget imgTile(int index, {int overlayCount = 0}) {
      return GestureDetector(
        onTap: () => openViewer(index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
              if (overlayCount > 0)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: Text(
                    '+$overlayCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    const double height = 220;
    const double gap = 6;

    // 1 image — full width
    if (images.length == 1) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: imgTile(0),
      );
    }

    // 2 images — side by side
    if (images.length == 2) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: imgTile(0)),
            const SizedBox(width: gap),
            Expanded(child: imgTile(1)),
          ],
        ),
      );
    }

    // 3+ images — 1 large left, 2 stacked right (with +N overlay on last)
    final extra = images.length > 3 ? images.length - 3 : 0;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(flex: 3, child: imgTile(0)),
          const SizedBox(width: gap),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: imgTile(1)),
                const SizedBox(height: gap),
                Expanded(child: imgTile(2, overlayCount: extra)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              "Add Photo",
              fontSize: 13,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
