import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_photo_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_gallery_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalCategoryDetailsScreen extends StatelessWidget {
  final HospitalGalleryData categoryData;
  final HospitalPhotoController controller = Get.find();

  HospitalCategoryDetailsScreen({required this.categoryData});

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
        List<String> images = currentCategory.images ?? [];

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
                          text: AppStrings.hospitalViewDeleteImageConfirm.tr,
                          confirmCallback: () async {
                            Get.back();
                            await controller.deleteHotelRoomController(
                                categoryId: categoryData.id ?? "",
                                imgUrl: images[index]);
                          },
                          cancelCallback: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          confirmText: AppStrings.yes,
                          cancelText: AppStrings.no);
                    },
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.red.withOpacity(0.8),
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
