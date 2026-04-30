import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_photos_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalHomeGalleryWidget extends StatelessWidget {
  final List<HospitalGallery>? photos;
  final bool isReadOnly;

  const HospitalHomeGalleryWidget(
      {super.key, this.photos, this.isReadOnly = true});

  @override
  Widget build(BuildContext context) {
    final List<String> allImages = photos
            ?.expand((photo) => photo.images ?? <String>[])
            .toList() ??
        [];

    if (allImages.isEmpty && isReadOnly) return const SizedBox.shrink();

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ServiceHomeTitleWidget(title: AppStrings.gallery),
              if (!isReadOnly)
                IconButton(
                  onPressed: () => Get.to(HospitalPhotosScreen()),
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
              onTap: () => Get.to(HospitalPhotosScreen()),
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
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.grey[400], size: 40),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.hospitalViewAddPhotos.tr,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildGalleryLayout(context, allImages),
        ],
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
