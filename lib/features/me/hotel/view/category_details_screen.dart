import 'package:BlueEra/core/api/model/hotel_property_photo_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hotel/controller/property_photo_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Grid view of every image inside a single property-photos album, with
/// per-image delete. The grid reads off the controller's live list so a
/// delete reflects immediately without a manual reload.
class CategoryDetailsScreen extends StatelessWidget {
  final HotelPropertyPhotoData categoryData;

  const CategoryDetailsScreen({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PropertyPhotoController>();

    return Scaffold(
      appBar: CommonBackAppBar(title: categoryData.category),
      body: Obx(() {
        // Resolve against the controller's live list so the grid reflects
        // deletes; fall back to the snapshot passed in for the initial render.
        final current = controller.propertyPhotosList.firstWhere(
          (item) => item.id == categoryData.id,
          orElse: () => categoryData,
        );
        final images = current.imageReferences ?? const <String>[];

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
    required PropertyPhotoController controller,
    required List<String> images,
    required int index,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: () => navigatePushTo(
            context,
            ImageViewScreen(
              subTitle: categoryData.category,
              appBarTitle: AppStrings.imageViewer,
              imageUrls: images,
              initialIndex: index,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: images[index],
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
    required PropertyPhotoController controller,
    required String imageUrl,
  }) {
    return showCommonDialog(
      context: context,
      text: AppStrings.hotelConfirmDeleteImage.tr,
      confirmText: AppStrings.yes,
      cancelText: AppStrings.no,
      confirmCallback: () async {
        Get.back();
        await controller.deleteHotelRoomController(
          categoryType: categoryData.category ?? '',
          imgUrl: imageUrl,
        );
      },
      cancelCallback: Get.back,
    );
  }
}
