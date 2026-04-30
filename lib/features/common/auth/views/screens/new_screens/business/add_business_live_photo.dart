import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBusinessLivePhoto extends StatefulWidget {
  const AddBusinessLivePhoto({super.key});

  @override
  State<AddBusinessLivePhoto> createState() => _AddBusinessLivePhotoState();
}

class _AddBusinessLivePhotoState extends State<AddBusinessLivePhoto> {
  List<String?> localPhotos = [null, null, null];
  static const double _height = 240.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          isLeading: true,
          title: AppStrings.businessDetailsTitle
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size15,
        ),
        child: CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      AppStrings.uploadYourLivePhoto,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      AppStrings.minimumThreeImages,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.paddingL),

                /// Store Live Image — grid layout like StoreLivePhotoWidget
                GetBuilder<ViewBusinessDetailsController>(
                  id: 'livePhotos',
                  builder: (controller) {
                    final List<String> photos =
                        localPhotos.whereType<String>().toList();
                    final count = photos.length;

                    if (count == 0) {
                      // No photos — show 3 empty add slots
                      return _buildEmptyGrid(controller);
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildLayout(photos, controller),
                    );
                  },
                ),

                SizedBox(height: SizeConfig.size16),

                GetBuilder<ViewBusinessDetailsController>(
                  id: 'livePhotos',
                  builder: (controller) {
                    final apiPhotos = controller.businessProfileDetails.value?.data?.livePhotos ?? [];
                    final int localCount = localPhotos.where((p) => p != null).length;
                    final int count = apiPhotos.length > localCount ? apiPhotos.length : localCount;
                    final bool hasPhoto = count > 0;

                    /// ---------- BUTTON ACTION ----------
                    void handleTap() async {
                      final bottomBarController = Get.find<BottomBarController>();

                      if (!hasPhoto) {
                        // Skip (no photos uploaded)
                        Get.until((route) =>
                          route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
                        bottomBarController.currentIndex.value = 2;
                        return;
                      }

                      if (count < 3) {
                        showCommonDialog(
                          context: context,
                          header: AppStrings.storeLivePhoto.tr,
                          text: AppStrings.upload3StorePictures.tr,
                          confirmCallback: () async {
                            Get.back();
                            final imgStr = await SelectProfilePictureDialog.pickFromCamera(
                              context,
                              cropAspectRatio: CropAspectRatio(width: 3, height: 4),
                            );
                            if (imgStr != null) {
                              await controller.saveBusinessImages(imgStr, controller);
                              controller.update(['livePhotos']);
                            }
                          },
                          cancelCallback: () => Get.back(),
                          confirmText: AppStrings.ok,
                          cancelText: AppStrings.cancel,
                        );
                        return;
                      }

                      // Continue (photos are 3)
                      Get.until((route) =>
                        route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
                      bottomBarController.currentIndex.value = 2;
                    }

                    /// ---------- BUTTON UI ----------
                    final bool isContinue = hasPhoto;
                    final bool isDisabled = hasPhoto && count < 3;

                    final Color borderColor = !isContinue
                        ? AppColors.secondaryTextColor
                        : isDisabled
                        ? AppColors.grey9B
                        : AppColors.primaryColor;

                    final Color bgColor = !isContinue
                        ? Colors.transparent
                        : isDisabled
                        ? AppColors.grey9B
                        : AppColors.primaryColor;

                    final Color textColor = !isContinue
                        ? AppColors.secondaryTextColor
                        : AppColors.white;

                    final String text = !isContinue ? AppStrings.skip : AppStrings.continueText;

                    return Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.0),
                        onTap: handleTap,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size20,
                            vertical: SizeConfig.size6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(10.0),
                            color: bgColor,
                          ),
                          child: CustomText(
                            text,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  },
                )

              ],
            )
        ),
      ),
    );
  }

  /// Empty state — show a single full-width add button
  Widget _buildEmptyGrid(ViewBusinessDetailsController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _buildAddSlot(
        height: _height,
        width: double.infinity,
        controller: controller,
      ),
    );
  }

  /// Grid layout matching StoreLivePhotoWidget
  Widget _buildLayout(
      List<String> photos, ViewBusinessDetailsController controller) {
    final count = photos.length;

    if (count == 1) {
      // 1 photo left + add button right
      return Row(
        children: [
          Expanded(
            child: _buildImage(
              index: 0,
              imagePath: photos[0],
              height: _height,
              allPhotos: photos,
              controller: controller,
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: _buildAddSlot(
              height: _height,
              controller: controller,
            ),
          ),
        ],
      );
    }

    if (count == 2) {
      // 1 large left + 1 photo top-right + add button bottom-right
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white, width: 1),
                ),
              ),
              child: _buildImage(
                index: 0,
                imagePath: photos[0],
                height: _height,
                allPhotos: photos,
                controller: controller,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildImage(
                  index: 1,
                  imagePath: photos[1],
                  height: _height / 2 - 0.5,
                  allPhotos: photos,
                  controller: controller,
                ),
                const SizedBox(height: 1),
                _buildAddSlot(
                  height: _height / 2 - 0.5,
                  controller: controller,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 3 photos — full 2x2-ish grid, no add button
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white, width: 1),
              ),
            ),
            child: _buildImage(
              index: 0,
              imagePath: photos[0],
              height: _height,
              allPhotos: photos,
              controller: controller,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _buildImage(
                index: 1,
                imagePath: photos[1],
                height: _height / 2 - 0.5,
                allPhotos: photos,
                controller: controller,
              ),
              const SizedBox(height: 1),
              _buildImage(
                index: 2,
                imagePath: photos[2],
                height: _height / 2 - 0.5,
                allPhotos: photos,
                controller: controller,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage({
    required int index,
    required String imagePath,
    required double height,
    double? width,
    required List<String> allPhotos,
    required ViewBusinessDetailsController controller,
  }) {
    return GestureDetector(
      onTap: () {
        navigatePushTo(
          context,
          ImageViewScreen(
            appBarTitle: AppStrings.imageViewer,
            subTitle: '',
            imageUrls: allPhotos,
            initialIndex: index,
          ),
        );
      },
      child: Stack(
        children: [
          Image.file(
            File(imagePath),
            height: height,
            width: width ?? SizeConfig.screenWidth,
            fit: BoxFit.cover,
          ),

          // Delete button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () async {
                localPhotos[index] = null;
                // Compact: shift nulls so photos stay contiguous
                final compacted = localPhotos.where((p) => p != null).toList();
                localPhotos = List.generate(
                    3, (i) => i < compacted.length ? compacted[i] : null);
                Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
                await controller.deleteLiveStoreImage(data);
                controller.businessProfileDetails.value?.data?.livePhotos
                    ?.removeAt(index);
                controller.update(['livePhotos']);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSlot({
    required double height,
    double? width,
    required ViewBusinessDetailsController controller,
  }) {
    return GestureDetector(
      onTap: () async {
        final imgStr = await SelectProfilePictureDialog.pickFromCamera(
          context,
          cropAspectRatio: CropAspectRatio(width: 3, height: 4),
        );
        if (imgStr != null) {
          // Find first null slot
          final emptyIndex = localPhotos.indexOf(null);
          if (emptyIndex != -1) {
            localPhotos[emptyIndex] = imgStr;
          }
          await controller.saveBusinessImages(imgStr, controller);
          controller.update(['livePhotos']);
        }
      },
      child: Container(
        height: height,
        width: width ?? double.infinity,
        color: AppColors.greyE5.withValues(alpha: 0.4),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LocalAssets(
                imagePath: AppIconAssets.profile_camera_pic,
                height: 30,
                width: 30,
                imgColor: AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 4),
              CustomText(
                AppStrings.addLiveStorePhoto,
                textAlign: TextAlign.center,
                fontSize: SizeConfig.extraSmall,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
