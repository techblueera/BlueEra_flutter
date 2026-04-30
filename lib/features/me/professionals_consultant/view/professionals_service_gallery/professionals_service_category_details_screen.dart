import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_service_photo_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professonals_gallery_res_model.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalsServiceCategoryDetailsScreen extends StatelessWidget {
  final ProfessonalsGalleryData? categoryData;

  ProfessionalsServiceCategoryDetailsScreen({this.categoryData});
  final controller = Get.find<ProfessionalsServicePhotoPhotoController>();


  @override
  Widget build(BuildContext context) {
    return Material(
      child: Obx(() {
        return GridView.builder(
          shrinkWrap: true,
          // <--- ADD THIS: Tells Grid to take minimum height
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: controller.propertyPhotosList.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                InkWell(
                  onTap: () {
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: "",
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: controller.propertyPhotosList,
                        initialIndex: index,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      controller.propertyPhotosList[index],
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
                          text: 'Are you sure you want to delete this image?',
                          confirmCallback: () async {
                            await controller.deleteOtherServiceController(
                              // imgId: categoryData.id ?? "",
                              imgId: controller.propertyPhotosIdsList[index],
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
