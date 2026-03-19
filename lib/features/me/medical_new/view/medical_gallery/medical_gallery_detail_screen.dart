import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_gallery_controller.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalGalleryDetailScreen extends StatelessWidget {
  final OtherServiceGalleryData categoryData;
  final controller = Get.find<MedicalGalleryController>();

  MedicalGalleryDetailScreen({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: categoryData.title),
      body: Obx(() {
        // Find live data from controller to reflect deletions
        var currentCategory = controller.galleryList.firstWhere(
          (item) => item.id == categoryData.id,
          orElse: () => categoryData,
        );
        List<String> images = currentCategory.imageUrls ?? [];

        if (images.isEmpty) {
          return const Center(child: Text('No images'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                InkWell(
                  onTap: () => navigatePushTo(
                    context,
                    ImageViewScreen(
                      subTitle: categoryData.title,
                      appBarTitle: AppStrings.imageViewer,
                      imageUrls: images,
                      initialIndex: index,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
                // Delete button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await showCommonDialog(
                        context: context,
                        text: AppStrings.deleteConfirmation,
                        confirmCallback: () async {
                          Get.back();
                          await controller.deleteGalleryImage(
                            galleryId: categoryData.id ?? '',
                            imageUrl: images[index],
                          );
                        },
                        cancelCallback: () => Navigator.of(context).pop(),
                        confirmText: AppStrings.yes,
                        cancelText: AppStrings.no,
                      );
                    },
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.red.withValues(alpha: 0.8),
                      child: const Icon(Icons.delete, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
