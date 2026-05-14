import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hotel/controller/room_detail_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:BlueEra/core/constants/app_colors.dart';

/// Step-2-of-2 of room creation: pick up to 4 images for each of the
/// three categories (exterior / washroom / amenity). Submit is gated on the
/// minimum-image rule from [RoomDetailController.isCreateHotel].
///
/// While [RoomDetailController.isLoading] is true the upload progress
/// shimmer covers the form and the system back swipe is intercepted by the
/// [PopScope] so the user can't abandon mid-upload.
class HotelImageUploadScreen extends StatelessWidget {
  final String roomType;
  final String roomName;

  HotelImageUploadScreen({
    super.key,
    required this.roomType,
    required this.roomName,
  });

  final controller = Get.find<RoomDetailController>();

  static const int _maxImagesPerSection = 4;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      return PopScope(
        canPop: !isLoading,
        child: Scaffold(
          appBar: CommonBackAppBar(title: AppStrings.hotelImagesAppBar.tr),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSection(
                      context,
                      AppStrings.hotelUploadExteriorImages.tr,
                      controller.exteriorImages,
                    ),
                    _buildSection(
                      context,
                      AppStrings.hotelUploadWashroomImages.tr,
                      controller.washroomImages,
                    ),
                    _buildSection(
                      context,
                      AppStrings.hotelUploadAmenitiesImagesOptional.tr,
                      controller.amenityImages,
                    ),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
                  ],
                ),
              ),
              if (isLoading) ShimmerListView(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSubmitButton() {
    final isReady = controller.isCreateHotel;
    return CustomBtn(
      onTap: isReady
          ? () {
              if (controller.validate()) {
                controller.submitHotelRoom(name: roomName, type: roomType);
              }
            }
          : null,
      title: AppStrings.submit.tr,
      isValidate: isReady,
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    RxList<XFile> imageList,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(title, fontWeight: FontWeight.w500),
              CustomText(
                AppStrings.hotelMin2Images.tr,
                color: AppColors.secondaryTextColor,
                fontSize: SizeConfig.size12,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Row(
                children: List.generate(_maxImagesPerSection, (index) {
                  return Expanded(
                    child: _buildImageSlot(context, imageList, index),
                  );
                }),
              )),
        ],
      ),
    );
  }

  Widget _buildImageSlot(
      BuildContext context, RxList<XFile> imageList, int index) {
    final hasImage = index < imageList.length;
    return GestureDetector(
      onTap: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
        if (path != null) imageList.add(XFile(path));
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: hasImage
            ? _buildImageThumbnail(imageList, index)
            : const Icon(Icons.image_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _buildImageThumbnail(RxList<XFile> imageList, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(imageList[index].path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 80,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () => controller.removeImage(index, imageList),
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
}
