import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../listing_form_screen_controller.dart';

class Step2Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step2Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Media
        _buildMediaUploadSection(controller),
        SizedBox(height: SizeConfig.size16),
        // Short Description
        _buildDescriptionSection(controller),
        SizedBox(height: SizeConfig.size16),
        // Non-returnable Toggle
        _buildNonReturnableSection(controller),
        SizedBox(height: SizeConfig.size16),
        // Warranty
        CommonTextField(
          title: "Product Warranty",
          hintText: "Eg. 1 Years",
          textEditController: controller.warrantyController,
        ),
        SizedBox(height: SizeConfig.size16),
        // Guidelines
        CommonTextField(
          title: "User Guideline",
          hintText: "Lorem ipsum dolor sit amit, adisping...",
          maxLine: 3,
        ),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  Widget _buildMediaUploadSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video section
        CustomText(
          'Upload product Video',
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                key: const ValueKey('video'),
                onTap: () {
                  final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
                  if (hasVideo) {
                    Get.snackbar(
                      'Limit reached',
                      'You can upload only one video. Remove the existing one to replace.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    controller.pickVideo();
                  }
                },
                onLongPress: () {
                  final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
                  if (hasVideo) {
                    controller.videoLocalPath.value = null;
                  }
                },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.fillColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.greyE5, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Obx(() {
                    final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasVideo)
                          Container(
                            color: Colors.black12,
                            child: Center(
                              child: Icon(Icons.videocam, color: AppColors.primaryColor.withOpacity(0.9)),
                            ),
                          )
                        else
                          Center(
                            child: Icon(
                              Icons.videocam,
                              color: AppColors.secondaryTextColor.withOpacity(0.3),
                            ),
                          ),
                        if (hasVideo)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => controller.videoLocalPath.value = null,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam, size: 12, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        // Images section
        CustomText(
          'Upload product Images',
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        SizedBox(
          height: 80,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 4, // up to 4 images
            itemBuilder: (context, index) {
              final imgIdx = index;
              return GestureDetector(
                key: ValueKey('img_$imgIdx'),
                onTap: () {
                  if (controller.imageLocalPaths.length >= 4) {
                    Get.snackbar(
                      'Limit reached',
                      'You can upload up to 4 images only.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    controller.pickImages();
                  }
                },
                onLongPress: () {
                  final hasImage = imgIdx < controller.imageLocalPaths.length;
                  if (hasImage) {
                    controller.removeImageAt(imgIdx);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.fillColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.greyE5, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Obx(() {
                    final hasImage = imgIdx < controller.imageLocalPaths.length;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          Image.file(
                            File(controller.imageLocalPaths[imgIdx]),
                            fit: BoxFit.cover,
                          )
                        else
                          Center(
                            child: Icon(
                              Icons.photo,
                              color: AppColors.secondaryTextColor.withOpacity(0.3),
                            ),
                          ),
                        if (hasImage)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => controller.removeImageAt(imgIdx),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo, size: 12, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Short Description',
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: controller.shortDescriptionController,
          hintText: "Lorem ipsum dolor sit amet conseceter adisping...",
          maxLine: 3,
        )
      ],
    );
  }

  Widget _buildNonReturnableSection(ManualListingScreenController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          'This is a non-returnable product',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
        Obx(() => CustomSwitch(
              containerHeight: 25,
              containerWidth: 50,
              value: controller.isNonReturnable.value,
              onChanged: (value) => controller.toggleNonReturnable(),
            )),
      ],
    );
  }
}
