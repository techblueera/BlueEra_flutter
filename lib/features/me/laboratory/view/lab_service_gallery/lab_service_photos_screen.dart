import 'package:BlueEra/features/me/laboratory/controller/lab_service_photo_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/lab_service_category_details_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/upload_lab_service_photos_screen.dart';
import 'package:BlueEra/features/me/others/controller/other_service_photo_controller.dart';
import 'package:BlueEra/features/me/others/view/other_service_gallery/other_service_category_details_screen.dart';
import 'package:BlueEra/features/me/others/view/other_service_gallery/upload_other_service_photos_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LabServicePhotosPhotoScreen extends StatelessWidget {
  final controller = Get.put(LabServicePhotoPhotoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Lab Service Photos",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20,right: 20,bottom: 30,top: 10),
          child: PositiveCustomBtn(
              onTap: () {
                Get.to(UploadLabServicePhotosScreen());
              },
              title: "Upload Lab Service Photo"),
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
                Get.to(LabServiceCategoryDetailsScreen(
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
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CustomText(
                                "+${images.length} Images",
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
                            CustomText("Last Update: ${formatIsoDate(item.updatedAt??"")}",

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
  static String formatIsoDate(String isoString) {
    if (isoString.isEmpty) return "";
    DateTime dateTime = DateTime.parse(isoString);
    return DateFormat('dd MMM, yyyy').format(dateTime);
  }
}
