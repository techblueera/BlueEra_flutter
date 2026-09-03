import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_service_photo_controller.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_service_gallery/other_service_category_details_screen.dart';
import 'package:BlueEra/features/me/automotive_service/view/other_service_gallery/upload_other_service_photos_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OtherServicePhotosPhotoScreen extends StatelessWidget {
  final controller = Get.put(AutomotiveServicePhotoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.otherServicePhotos.tr,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20,right: 20,bottom: 30,top: 10),
          child: PositiveCustomBtn(
              onTap: () => _startUpload(context),
              title: AppStrings.otherUploadServicePhoto.tr),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value)
          return Center(child: CircularProgressIndicator());

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.propertyPhotosList.length,
          itemBuilder: (context, index) {
            var item = controller.propertyPhotosList[index];
            List images = item.imageUrls ?? [];
            String firstImage = images.isNotEmpty ? images[0] : "";

            return InkWell(
              onTap: () {
                Get.to(() => OtherServiceCategoryDetailsScreen(
                  categoryData: item,
                ));
              },
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Thumbnail with Image Count Overlay
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              firstImage,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                      color: Colors.grey,
                                      width: 100,
                                      height: 100,
                                      child: Icon(Icons.image)),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CustomText(
                                "+${images.length} ${AppStrings.hotelImagesSuffix.tr}",
                                textAlign: TextAlign.center,

                                    color: Colors.white, fontSize: 10),

                            ),
                          )
                        ],
                      ),
                      SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(item.title??"",
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                              ],
                            ),
                            SizedBox(height: 4),
                            CustomText("${AppStrings.hotelLastUpdate.tr} ${formatIsoDate(item.updatedAt??"")}",

                                    color: Colors.grey, fontSize: 12),

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
  /// Photos first, category second.
  ///
  /// Tapping upload opens the multi-select picker straight away — up to
  /// [AutomotiveServicePhotoController.maxImages] in one pass — and only once
  /// something has actually been picked does the next screen open to name the
  /// category. Backing out of the picker leaves the merchant where they were
  /// instead of on an empty form they now have to abandon too.
  ///
  /// It used to run the other way round: the button opened a form whose first
  /// field was the category, so the merchant had to name a group before
  /// seeing a single photo, and could name one and then pick nothing.
  Future<void> _startUpload(BuildContext context) async {
    // Start from empty: this controller outlives the upload screen, so
    // whatever a cancelled attempt left behind must not leak into this one.
    controller.resetUploadForm();

    final paths = await PhotoPickerService.pickMultiplePhotos(
      context,
      AppStrings.otherUploadServicePhoto.tr,
      maxImages: controller.maxImages,
    );
    if (paths == null || paths.isEmpty) return;

    controller.addImages(paths);
    Get.to(() => const UploadOtherServicePhotosScreen());
  }

  static String formatIsoDate(String isoString) {
    if (isoString.isEmpty) return "";
    DateTime dateTime = DateTime.parse(isoString);
    return DateFormat('dd MMM, yyyy').format(dateTime);
  }
}
