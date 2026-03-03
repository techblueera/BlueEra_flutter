import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_listing_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_details_res_model.dart';

class CampusPhotoGallery extends StatelessWidget {
  final List<CampusLife> campusLife;

  const CampusPhotoGallery({super.key, required this.campusLife});

  @override
  Widget build(BuildContext context) {
    // 1. Extract and flatten all image URLs from all categories
    List<String> allImages = [];
    for (var item in campusLife) {
      if (item.images != null) {
        for (Images img in item.images ?? []) {
          if (img.url != null) {
            allImages.add(img.url ?? "");
          }
        }
      }
    }

    // 2. Limit to max 6 images
    final displayImages = allImages.take(6).toList();

    if (displayImages.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ServiceHomeTitleWidget(
                  title: AppStrings.photo,
                ),
                if (displayImages.length > 6)
                  InkWell(
                    onTap: () {
                      Get.to(CampusLifeListingScreen());
                    },
                    child:  CustomText(AppStrings.viewAll,
                        color: AppColors.primaryColor,),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Grid Display (image_0d01ab.jpg style)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 images per row
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1, // Square images
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: (){
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: "",
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: allImages,
                        initialIndex: index,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      displayImages[index],
                      fit: BoxFit.cover,
                      // Error handling for broken URLs
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                      // Loading placeholder
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
