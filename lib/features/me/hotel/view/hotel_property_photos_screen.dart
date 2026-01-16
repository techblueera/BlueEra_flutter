import 'package:BlueEra/features/me/hotel/controller/property_photo_controller.dart';
import 'package:BlueEra/features/me/hotel/view/category_details_screen.dart';
import 'package:BlueEra/features/me/hotel/view/upload_property_photos_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PropertyPhotoScreen extends StatelessWidget {
  final controller = Get.put(PropertyPhotoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Property Photos",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20,right: 20,bottom: 30,top: 10),
          child: PositiveCustomBtn(
              onTap: () {
                Get.to(UploadPropertyPhotosScreen());
              },
              title: "Upload Property Photo"),
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
            List images = item.imageReferences ?? [];
            String firstImage = images.isNotEmpty ? images[0] : "";

            return InkWell(
              onTap: () {
                Get.to(CategoryDetailsScreen(
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
                              child: Text(
                                "+${images.length} Images",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
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
                                CustomText(item.category??"",
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                Icon(Icons.more_vert, color: Colors.grey),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text("Last Update:",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            Text("20 April, 2025",
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
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
}
