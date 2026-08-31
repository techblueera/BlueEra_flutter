import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_photo_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/lab_service_category_details_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/upload_lab_service_photos_screen.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LabServicePhotosPhotoScreen extends StatelessWidget {
  const LabServicePhotosPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LabServicePhotoPhotoController>();

    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.labServicePhotos.tr),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 30,
            top: 10,
          ),
          child: PositiveCustomBtn(
            onTap: () => Get.to(() => const UploadLabServicePhotosScreen()),
            title: AppStrings.uploadLabServicePhoto.tr,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.propertyPhotosList.length,
          itemBuilder: (context, index) => _buildPhotoTile(
            controller.propertyPhotosList[index],
          ),
        );
      }),
    );
  }

  Widget _buildPhotoTile(OtherServiceGalleryData item) {
    final images = item.imageUrls ?? const <String>[];
    final firstImage = images.isNotEmpty ? images[0] : "";

    return InkWell(
      onTap: () =>
          Get.to(() => LabServiceCategoryDetailsScreen(categoryData: item)),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildThumbnail(firstImage, images.length),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      item.title ?? "",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      "${AppStrings.lastUpdate.tr}: ${_formatIsoDate(item.updatedAt ?? "")}",
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String firstImage, int imageCount) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: firstImage.isNotEmpty
              ? Image.network(
                  firstImage,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _thumbnailPlaceholder(),
                )
              : _thumbnailPlaceholder(),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: CustomText(
              "+$imageCount ${AppStrings.imagesCount.tr}",
              textAlign: TextAlign.center,
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _thumbnailPlaceholder() => Container(
        color: Colors.grey,
        width: 100,
        height: 100,
        child: const Icon(Icons.image),
      );

  static String _formatIsoDate(String isoString) {
    if (isoString.isEmpty) return "";
    final dateTime = DateTime.parse(isoString);
    return DateFormat('dd MMM, yyyy').format(dateTime);
  }
}
