import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_listing_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_details_res_model.dart';

class CampusPhotoGallery extends StatelessWidget {
  final List<CampusLife> campusLife;
  final bool isEdit;

  const CampusPhotoGallery(
      {super.key, required this.campusLife, this.isEdit = false});

  @override
  Widget build(BuildContext context) {
    final List<String> allImages = [];
    for (var item in campusLife) {
      for (Images img in item.images ?? []) {
        if (img.url != null) allImages.add(img.url!);
      }
    }

    return Card(
      margin: const EdgeInsets.all(10),
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
                ServiceHomeTitleWidget(title: AppStrings.photo),
                if (isEdit)
                  IconButton(
                    onPressed: () => Get.to(CampusLifeListingScreen()),
                    icon: Icon(
                      allImages.isEmpty
                          ? Icons.add_circle_outline
                          : Icons.edit_outlined,
                      size: 20,
                    ),
                  ),
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
                    border:
                        Border.all(color: Colors.grey.shade300, width: 1.5),
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
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;

    void openViewer(int index) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: images,
            initialIndex: index,
          ),
        );

    Widget imgTile(int index, {bool showOverlay = false}) {
      return GestureDetector(
        onTap: () => openViewer(index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                display[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
              if (showOverlay && extra > 0)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: Text(
                    '+$extra',
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
    const double gap = 4;

    // 1 image — full width
    if (display.length == 1) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: imgTile(0),
      );
    }

    // 2 images — side by side
    if (display.length == 2) {
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

    // 3 images — 1 large left, 2 stacked right
    if (display.length == 3) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: imgTile(0)),
            const SizedBox(width: gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: imgTile(1)),
                  const SizedBox(height: gap),
                  Expanded(child: imgTile(2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ images — 2×2 grid (with +N overlay on last cell)
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: imgTile(0)),
                const SizedBox(width: gap),
                Expanded(child: imgTile(1)),
              ],
            ),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: imgTile(2)),
                const SizedBox(width: gap),
                Expanded(child: imgTile(3, showOverlay: extra > 0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
