import 'package:BlueEra/core/constants/app_strings.dart';
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
      appBar: CommonBackAppBar(title: AppStrings.medicalGallery),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
          child: PositiveCustomBtn(
            onTap: () => Get.to(() => MedicalGalleryUploadScreen()),
            title: AppStrings.uploadPhotos,
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
              AppStrings.noGalleryPhotosYet,
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
