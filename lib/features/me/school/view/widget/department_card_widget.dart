import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/about_us_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class DepartmentCard extends StatelessWidget {
  DepartmentCard({super.key});

  final aboutUsController = Get.find<AboutUsController>();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.whiteE5, // Set your desired border color here
          width: 1.5, // Set the thickness of the border
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 20,bottom: 20,left: 20,right: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.school, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: CustomText("Geography Department",
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  height: 20,
                  width: 20,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    // offset: const Offset(-6, 36),
                    color: AppColors.white,

                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onSelected: (value) async {
                      // onTapFunction(valueData: value, contextBuild: context);
                    },
                    icon: LocalAssets(imagePath: AppIconAssets.more_vertical),
                    itemBuilder: (context) => popupSchoolDepartmentMenuItems(),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Text Details
            _detailRow("HOD", "Shivam Dube"),
            _detailRow("Staff", "Shivam Dube"),
            CustomText(
                "Description: Lorem Ipsum Dolor Amet set Lorem Ipsum Dolor Amet set...",
                fontSize: SizeConfig.size16,
                color: AppColors.secondaryTextColor),

            const SizedBox(height: 10),

            // Reactive Image List
            Obx(() => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...aboutUsController.selectedImages
                        .asMap()
                        .entries
                        .map((entry) {
                      int idx = entry.key;
                      File file = entry.value;
                      return _buildImageThumbnail(
                          file, () => aboutUsController.removeImage(idx));
                    }),
                    // Camera Icon Placeholder (if under limit)
                    if (aboutUsController.selectedImages.length < 5)
                      _buildAddPlaceholder(aboutUsController),
                  ],
                )),

            // Bottom Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () =>
                      aboutUsController.pickImages(ImageSource.gallery),
                  child: const CustomText(
                    "Add Gallery",
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 20),
                InkWell(
                  onTap: () {},
                  child: const CustomText("Manage Staff",
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor),
                ),
                const SizedBox(width: 10),

              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CustomText("$label: $value",
          fontSize: SizeConfig.size16, color: AppColors.secondaryTextColor),
    );
  }

  Widget _buildImageThumbnail(File file, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPlaceholder(AboutUsController aboutUsController) {
    return GestureDetector(
      onTap: () => aboutUsController.pickImages(ImageSource.camera),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.grey),
      ),
    );
  }
}
