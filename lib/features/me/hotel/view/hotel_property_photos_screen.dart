import 'package:BlueEra/core/api/model/hotel_property_photo_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/hotel/controller/property_photo_controller.dart';
import 'package:BlueEra/features/me/hotel/view/category_details_screen.dart';
import 'package:BlueEra/features/me/hotel/view/upload_property_photos_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Lists every property-photo album the hotel has. Each row opens
/// [CategoryDetailsScreen] for that album; the bottom CTA opens
/// [UploadPropertyPhotosScreen] to add a new one.
class PropertyPhotoScreen extends StatelessWidget {
  PropertyPhotoScreen({super.key});

  final controller = Get.put(PropertyPhotoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.hotelPropertyPhotos.tr),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
          child: PositiveCustomBtn(
            onTap: () => _startUpload(context),
            title: AppStrings.hotelUploadPropertyPhoto.tr,
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
          itemBuilder: (context, index) =>
              _buildAlbumCard(controller.propertyPhotosList[index]),
        );
      }),
    );
  }

  /// Photos first, album second.
  ///
  /// Tapping upload opens the multi-select picker straight away — up to
  /// [PropertyPhotoController.maxImages] in one pass — and only once something
  /// has actually been picked does the next screen open to name the album.
  /// Backing out of the picker leaves the hotel where they were instead of on
  /// an empty form they now have to abandon too.
  ///
  /// It used to run the other way round: the button opened a form whose first
  /// field was the album category, so a group had to be named before a single
  /// photo was visible, and one could be named with nothing then picked.
  Future<void> _startUpload(BuildContext context) async {
    // Start from empty: this controller outlives the upload screen, so
    // whatever a cancelled attempt left behind must not leak into this one.
    controller.clearSelection();

    final paths = await PhotoPickerService.pickMultiplePhotos(
      context,
      AppStrings.hotelUploadPropertyPhoto.tr,
      maxImages: controller.maxImages,
    );
    if (paths == null || paths.isEmpty) return;

    controller.addImages(paths);
    Get.to(() => const UploadPropertyPhotosScreen());
  }

  Widget _buildAlbumCard(HotelPropertyPhotoData item) {
    final images = item.imageReferences ?? const <String>[];
    final firstImage = images.isNotEmpty ? images.first : '';

    return InkWell(
      onTap: () => Get.to(() => CategoryDetailsScreen(categoryData: item)),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildThumbnail(firstImage, images.length),
              const SizedBox(width: 16),
              Expanded(child: _buildAlbumDetails(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String url, int imageCount) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 100,
            height: 100,
            child: url.isEmpty
                ? Container(color: Colors.grey, child: const Icon(Icons.image))
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey,
                      child: const Icon(Icons.image),
                    ),
                  ),
          ),
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
              '$imageCount ${AppStrings.hotelImagesSuffix.tr}',
              textAlign: TextAlign.center,
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumDetails(HotelPropertyPhotoData item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          item.category ?? '',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 4),
        CustomText(
          '${AppStrings.hotelLastUpdate.tr} ${_formatIsoDate(item.updatedAt ?? '')}',
          color: Colors.grey,
          fontSize: 12,
        ),
      ],
    );
  }
}

/// `2024-05-13T10:00:00Z` → `13 May, 2024`. Tolerant of empty input.
String _formatIsoDate(String isoString) {
  if (isoString.isEmpty) return '';
  return DateFormat('dd MMM, yyyy').format(DateTime.parse(isoString));
}
