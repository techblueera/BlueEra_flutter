import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/others/controller/other_service_photo_controller.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/features/me/others/view/other_service_gallery/upload_other_service_photos_screen.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherServiceCategoryDetailsScreen extends StatelessWidget {
  final OtherServiceGalleryData categoryData;
  final OtherServicePhotoPhotoController controller = Get.find();

  OtherServiceCategoryDetailsScreen({required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: categoryData.title,
      ),
      body: Obx(() {
        // Find the live data in the controller to ensure UI updates after delete
        var currentCategory = controller.propertyPhotosList.firstWhere(
          (item) => item.id == categoryData.id,
          orElse: () => categoryData,
        );
        List<String> images = currentCategory.imageUrls ?? [];

        // Deleting the last photo leaves the album itself in place — the
        // controller keeps empty albums so their category survives in the
        // upload form — so this screen stays open on a grid with nothing in
        // it. Say so, and offer the way to refill it, rather than going blank.
        if (images.isEmpty) {
          return EmptyStateWidget(
            message: AppStrings.noPhotosYet.tr,
            actionText: AppStrings.otherUploadServicePhoto.tr,
            actionCallback: () {
              controller.resetUploadForm();
              Get.to(() => const UploadOtherServicePhotosScreen());
            },
            actionHighlight: true,
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                InkWell(
                  onTap: (){

                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: categoryData.title,
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: images,
                        initialIndex: index,
                      ),
                    );

                  },
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
                // Delete Button Overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await showCommonDialog(
                          context: context,
                          text: AppStrings.hotelConfirmDeleteImage.tr,
                          confirmCallback: () async {
                            Get.back();
                            await controller.deleteOtherServiceController(
                                imgId: categoryData.id ?? "",
                                imgUrl:   images[index],
                             );
                          },
                          cancelCallback: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          confirmText: AppStrings.yes,
                          cancelText: AppStrings.no);
                    },
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.red.withValues(alpha: 0.8),
                      child: Icon(Icons.delete, color: Colors.white, size: 16),
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
