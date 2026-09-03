import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/medical/controller/medical_gallery_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_gallery/medical_gallery_detail_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_gallery/medical_gallery_upload_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MedicalGalleryListScreen extends StatelessWidget {
  final controller = Get.put(MedicalGalleryController());

  MedicalGalleryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `.tr` — these are translation KEYS, and without it the screen showed
      // the raw "medicalGallery" / "noGalleryPhotosYet" identifiers.
      appBar: CommonBackAppBar(title: AppStrings.medicalGallery.tr),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
          child: PositiveCustomBtn(
            onTap: () => _startUpload(context),
            title: AppStrings.uploadPhotos.tr,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.galleryList.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.noGalleryPhotosYet.tr,
              color: Colors.grey,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.galleryList.length,
          itemBuilder: (context, index) {
            var item = controller.galleryList[index];
            List<String> images = item.imageUrls ?? [];
            String firstImage = images.isNotEmpty ? images[0] : '';

            return InkWell(
              onTap: () => Get.to(() => MedicalGalleryDetailScreen(categoryData: item)),
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Thumbnail with count overlay
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              firstImage,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                width: 100,
                                height: 100,
                                child: const Icon(Icons.image),
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
                                '+${images.length} ${AppStrings.imagesCount.tr}',
                                textAlign: TextAlign.center,
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              item.title ?? '',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              '${AppStrings.lastUpdateLabel.tr}: ${_formatDate(item.updatedAt ?? '')}',
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
          },
        );
      }),
    );
  }

  /// Photos first, album second.
  ///
  /// Tapping upload opens the multi-select picker straight away — up to
  /// [MedicalGalleryController.maxImages] in one pass — and only once
  /// something has actually been picked does the next screen open to name the
  /// album. Backing out of the picker leaves the pharmacy where they were
  /// instead of on an empty form they now have to abandon too.
  ///
  /// It used to run the other way round: the button opened a form whose first
  /// field was the album name, so a group had to be named before a single
  /// photo was visible, and one could be named with nothing then picked.
  Future<void> _startUpload(BuildContext context) async {
    // Start from empty: this controller outlives the upload screen, so
    // whatever a cancelled attempt left behind must not leak into this one.
    controller.resetUploadForm();

    final paths = await PhotoPickerService.pickMultiplePhotos(
      context,
      AppStrings.uploadPhotos.tr,
      maxImages: controller.maxImages,
    );
    if (paths == null || paths.isEmpty) return;

    controller.addImages(paths);
    Get.to(() => const MedicalGalleryUploadScreen());
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(isoString);
      return DateFormat('dd MMM, yyyy').format(dateTime);
    } catch (_) {
      return '';
    }
  }
}
