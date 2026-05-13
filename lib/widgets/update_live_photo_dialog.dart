import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/api/apiService/api_keys.dart';

Future<void> showLivePhotoDialog({
  required BuildContext context,
}) async {
  final controller = Get.find<ViewBusinessDetailsController>();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: AppColors.white,
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                AppStrings.uploadYourLivePhoto,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size16),

              /// LayoutBuilder to adapt image size
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = SizeConfig.size10;
                  final containerWidth = (constraints.maxWidth - (spacing * 2)) / 3;

                  return GetBuilder<ViewBusinessDetailsController>(
                    id: 'livePhotos',
                    builder: (controller) {
                      final apiPhotos = controller.businessProfileDetails.value?.data?.livePhotos ?? [];

                      final totalCount = apiPhotos.length;
                      final emptySlots = (3 - totalCount).clamp(0, 3);

                      List<Widget> allPhotos = [];

                      // API Photos (Already uploaded)
                      for (int i = 0; i < apiPhotos.length; i++) {
                        allPhotos.add(_buildImageContainer(
                          context,
                          apiPhotos[i],
                          i,
                          controller,
                          containerWidth,
                          apiPhotos,
                        ));
                      }

                      // Empty slots for remaining photos
                      for (int i = 0; i < emptySlots; i++) {
                        allPhotos.add(_buildImageContainer(
                          context,
                          "",
                          apiPhotos.length + i,
                          controller,
                          containerWidth,
                          apiPhotos,
                        ));
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: allPhotos,
                      );
                    },
                  );
                },
              ),

              SizedBox(height: SizeConfig.size24),

              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                      title: AppStrings.cancel,
                      bgColor: AppColors.white,
                      borderColor: AppColors.primaryColor,
                      textColor: AppColors.primaryColor,
                      onTap: () => Get.back(),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: PositiveCustomBtn(
                      title: AppStrings.submit,
                      onTap: () {
                        final apiPhotos = controller.businessProfileDetails.value?.data?.livePhotos ?? [];

                        if (apiPhotos.length < 3) {
                          commonSnackBar(message: AppStrings.upload_live_photos_message);
                          return;
                        }

                        Get.back();
                        Get.toNamed(RouteHelper.getProductScreenRoute());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildImageContainer(
    BuildContext context,
    String? imagePath,
    int index,
    ViewBusinessDetailsController controller,
    double size,
    List<String> allPhotos,
    ) {
  final isEmpty = imagePath == null || imagePath.isEmpty;

  return Stack(
    children: [
      GestureDetector(
        onTap: () async {
          if (isEmpty) {
            // Pick and upload new image
            showCommonDialog(
              context: context,
              header: AppStrings.storeLivePhoto.tr,
              text: AppStrings.upload3StorePictures.tr,
              // text: 'Please upload all 3 live photos of your store.',
              confirmCallback: () async {
                Get.back();
                final imgStr = await SelectProfilePictureDialog.pickFromCamera(
                    context,
                    cropAspectRatio: CropAspectRatio(width: 3, height: 4)
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
          } else {
            // View full image
            navigatePushTo(
              context,
              ImageViewScreen(
                subTitle: '',
                appBarTitle: AppStrings.imageViewer,
                imageUrls: allPhotos,
                initialIndex: index,
              ),
            );
          }
        },
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(
              color: isEmpty ? AppColors.red : AppColors.greyE5,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isEmpty ? [] : [AppShadows.textFieldShadow],
            image: !isEmpty
                ? DecorationImage(
              image: NetworkImage(imagePath),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(imagePath: AppIconAssets.profile_camera_pic),
                SizedBox(height: 4),
                CustomText(
                  AppStrings.addLiveStorePhoto,
                  textAlign: TextAlign.center,
                  fontSize: SizeConfig.extraSmall,
                  decoration: TextDecoration.underline,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
          )
              : null,
        ),
      ),
      if (!isEmpty)
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () async {
              Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
              await controller.deleteLiveStoreImage(data);
              controller.businessProfileDetails.value?.data?.livePhotos?.removeAt(index);
              controller.update(['livePhotos']);
            },
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: Icon(Icons.close, size: 16, color: Colors.grey),
            ),
          ),
        ),
    ],
  );
}