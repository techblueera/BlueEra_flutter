import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_photo_controller.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabServiceCategoryDetailsScreen extends StatelessWidget {
  final OtherServiceGalleryData categoryData;

  const LabServiceCategoryDetailsScreen({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LabServicePhotoPhotoController>();

    return Scaffold(
      appBar: CommonBackAppBar(title: categoryData.title),
      body: Obx(() {
        // Resolve the category against the controller's live list so the grid
        // reflects deletes; fall back to the snapshot passed in for the
        // initial render before the list is populated.
        final currentCategory = controller.propertyPhotosList.firstWhere(
          (item) => item.id == categoryData.id,
          orElse: () => categoryData,
        );
        final images = currentCategory.imageUrls ?? const <String>[];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) => _buildImageTile(
            context: context,
            controller: controller,
            images: images,
            index: index,
          ),
        );
      }),
    );
  }

  Widget _buildImageTile({
    required BuildContext context,
    required LabServicePhotoPhotoController controller,
    required List<String> images,
    required int index,
  }) {
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
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _confirmDelete(
              context: context,
              controller: controller,
              imageUrl: images[index],
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              child: const Icon(Icons.delete, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required LabServicePhotoPhotoController controller,
    required String imageUrl,
  }) {
    return showCommonDialog(
      context: context,
      text: AppStrings.deleteConfirmation,
      confirmText: AppStrings.yes,
      cancelText: AppStrings.no,
      confirmCallback: () async {
        Get.back();
        await controller.deleteOtherServiceController(
          imgId: categoryData.id ?? "",
          imgUrl: imageUrl,
        );
      },
      cancelCallback: Get.back,
    );
  }
}
