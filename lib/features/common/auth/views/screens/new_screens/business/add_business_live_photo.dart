import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBusinessLivePhoto extends StatefulWidget {
  const AddBusinessLivePhoto({super.key});

  @override
  State<AddBusinessLivePhoto> createState() => _AddBusinessLivePhotoState();
}

class _AddBusinessLivePhotoState extends State<AddBusinessLivePhoto> {
  List<String?> localPhotos = [null, null, null];

  final List<Map<String, String>> liveImageTitles = [
    {'label': AppStrings.roadsideOutsideView, 'image': AppImageAssets.roadsideViewImage},
    {'label': AppStrings.frontView, 'image': AppImageAssets.frontDeskImage},
    {'label': AppStrings.entireStoreOffice, 'image': AppImageAssets.officeImage},
  ];

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

                /// Store Live Image
                GetBuilder<ViewBusinessDetailsController>(
                  id: 'livePhotos',
                  builder: (controller) {

                    List<String?> photos = localPhotos; // always size = 3

                    return Column(
                      children: List.generate(3, (index) {
                        return Container(
                          margin: EdgeInsets.only(top: SizeConfig.paddingM),
                          padding: EdgeInsets.all(SizeConfig.paddingXSL),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: AppColors.white,
                            border: Border.all(color: AppColors.greyE5),
                            boxShadow: [AppShadows.textFieldShadow],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLiveImageIcons(index),
                              SizedBox(width: SizeConfig.size8),
                              _buildLiveImageLabel(index),
                              SizedBox(width: SizeConfig.size8),
                              _buildImageContainer(
                                context,
                                photos[index],
                                index,
                                controller,
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),

                // GetBuilder<ViewBusinessDetailsController>(
                //   id: 'livePhotos',
                //   builder: (controller) {
                //     final apiPhotos = controller.businessProfileDetails.value?.data?.livePhotos ?? [];
                //
                //     final totalCount = apiPhotos.length;
                //     final emptySlots = (3 - totalCount).clamp(0, 3);
                //
                //     List<Widget> allPhotos = [];
                //
                //     // API Photos (Already uploaded)
                //     for (int i = 0; i < apiPhotos.length; i++) {
                //       allPhotos.add(
                //           Container(
                //             margin: EdgeInsets.only(top: SizeConfig.paddingM),
                //             padding: EdgeInsets.all(SizeConfig.paddingXSL),
                //             decoration: BoxDecoration(
                //                 borderRadius: BorderRadius.circular(10.0),
                //                 color: AppColors.white,
                //                 border: Border.all(
                //                     color: AppColors.greyE5
                //                 ),
                //                 boxShadow: [AppShadows.textFieldShadow]
                //             ),
                //             child: Row(
                //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //                 children: [
                //                   _buildLiveImageIcons(i),
                //                   SizedBox(width: SizeConfig.size8),
                //                   _buildLiveImageLabel(i),
                //                   SizedBox(width: SizeConfig.size8),
                //                   _buildImageContainer(
                //                     context,
                //                     apiPhotos[i],
                //                     i,
                //                     controller,
                //                     apiPhotos,
                //                   ),
                //                 ]
                //             ),
                //           ));
                //     }
                //
                //     // Empty slots for remaining photos
                //     for (int i = 0; i < emptySlots; i++) {
                //       allPhotos.add(
                //           Container(
                //             margin: EdgeInsets.only(top: SizeConfig.paddingM),
                //             padding: EdgeInsets.all(SizeConfig.paddingXSL),
                //             decoration: BoxDecoration(
                //                 borderRadius: BorderRadius.circular(10.0),
                //                 color: AppColors.white,
                //                 border: Border.all(
                //                     color: AppColors.greyE5
                //                 ),
                //                 boxShadow: [AppShadows.textFieldShadow]
                //             ),
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //               children: [
                //                 _buildLiveImageIcons(i),
                //                 SizedBox(width: SizeConfig.size8),
                //                 _buildLiveImageLabel(i),
                //                 SizedBox(width: SizeConfig.size8),
                //                 _buildImageContainer(
                //                   context,
                //                   "",
                //                   apiPhotos.length + i,
                //                   controller,
                //                   apiPhotos,
                //                 ),
                //               ],
                //             ),
                //           ));
                //     }
                //
                //     return Column(
                //       mainAxisAlignment: MainAxisAlignment.start,
                //       children: allPhotos,
                //     );
                //   },
                // ),

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

  Widget _buildLiveImageIcons(int index){
    return  ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: LocalAssets(
          imagePath: liveImageTitles[index]['image']!,
          height: SizeConfig.size90,
          width: SizeConfig.size90,
      ),
    );
  }

  Widget _buildLiveImageLabel(int index){
    return Flexible(
      child: CustomText(
        liveImageTitles[index]['label']!,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildImageContainer(
      BuildContext context,
      String? imagePath,
      int index,
      ViewBusinessDetailsController controller,
      ) {
    final bool isEmpty = imagePath == null || imagePath.isEmpty;

    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            if (isEmpty) {
              final imgStr = await SelectProfilePictureDialog.pickFromCamera(
                context,
                cropAspectRatio: CropAspectRatio(width: 3, height: 4),
              );

              if (imgStr != null) {
                localPhotos[index] = imgStr;  // FIXED SLOT
                await controller.saveBusinessImages(imgStr, controller);
                controller.update(['livePhotos']);
              }
            } else {
              navigatePushTo(
                context,
                ImageViewScreen(
                  appBarTitle: AppStrings.imageViewer,
                  subTitle: '',
                  imageUrls: localPhotos.whereType<String>().toList(),
                  initialIndex: index,
                ),
              );
            }
          },
          child: isEmpty
              ? DottedBorder(
            borderType: BorderType.RRect,
            radius: Radius.circular(6),
            dashPattern: [6, 3],
            color: AppColors.greyLite,
            strokeWidth: 1.0,
            child: Container(
              height: SizeConfig.size90,
              width: SizeConfig.size90,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
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
                    SizedBox(height: 4),
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
          )
              : Container(
            height: SizeConfig.size90,
            width: SizeConfig.size90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: FileImage(File(imagePath)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        /// DELETE BUTTON (Keeps index empty & no shifting)
        if (!isEmpty)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () async {
                localPhotos[index] = null;
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
          )
      ],
    );
  }

  // Widget _buildImageContainer(
  //     BuildContext context,
  //     String? imagePath,
  //     int index,
  //     ViewBusinessDetailsController controller,
  //     List<String> allPhotos,
  //     ) {
  //   final isEmpty = imagePath == null || imagePath.isEmpty;
  //
  //   return Stack(
  //     children: [
  //       GestureDetector(
  //         onTap: () async {
  //           if (isEmpty) {
  //             // Pick and upload new image
  //             final imgStr = await SelectProfilePictureDialog.pickFromCamera(
  //                 context,
  //                 cropAspectRatio: CropAspectRatio(width: 3, height: 4)
  //             );
  //             if (imgStr != null) {
  //               await controller.saveBusinessImages(imgStr, controller);
  //               controller.update(['livePhotos']);
  //             }
  //           } else {
  //             // View full image
  //             navigatePushTo(
  //               context,
  //               ImageViewScreen(
  //                 subTitle: '',
  //                 appBarTitle: AppStrings.imageViewer,
  //                 imageUrls: allPhotos,
  //                 initialIndex: index,
  //               ),
  //             );
  //           }
  //         },
  //         child: isEmpty
  //             ? DottedBorder(
  //           borderType: BorderType.RRect,
  //           radius: Radius.circular(6),
  //           dashPattern: [6, 3],
  //           color: AppColors.greyLite,
  //           strokeWidth: 1.0,
  //           child: Container(
  //             height: SizeConfig.size90,
  //             width: SizeConfig.size90,
  //             decoration: BoxDecoration(
  //               color: AppColors.white,
  //               borderRadius: BorderRadius.circular(10),
  //               boxShadow: isEmpty ? [] : [AppShadows.textFieldShadow],
  //               image: !isEmpty
  //                   ? DecorationImage(
  //                 image: NetworkImage(imagePath),
  //                 fit: BoxFit.cover,
  //               )
  //                   : null,
  //             ),
  //             child: isEmpty
  //                 ? Center(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   LocalAssets(
  //                       imagePath: AppIconAssets.profile_camera_pic,
  //                       height: 30,
  //                       width: 30,
  //                       imgColor: AppColors.secondaryTextColor,
  //                   ),
  //                   SizedBox(height: 4),
  //                   CustomText(
  //                     AppStrings.addLiveStorePhoto,
  //                     textAlign: TextAlign.center,
  //                     fontSize: SizeConfig.extraSmall,
  //                     fontWeight: FontWeight.w400,
  //                     color: AppColors.secondaryTextColor,
  //                   ),
  //                 ],
  //               ),
  //             )
  //                 : null,
  //           ),
  //         )
  //             : Container(
  //           height: SizeConfig.size90,
  //           width: SizeConfig.size90,
  //           decoration: BoxDecoration(
  //             color: AppColors.white,
  //             border: Border.all(
  //               color: AppColors.greyE5,
  //             ),
  //             borderRadius: BorderRadius.circular(10),
  //             boxShadow: isEmpty ? [] : [AppShadows.textFieldShadow],
  //             image: !isEmpty
  //                 ? DecorationImage(
  //               image: NetworkImage(imagePath),
  //               fit: BoxFit.cover,
  //             )
  //                 : null,
  //           ),
  //           child: isEmpty
  //               ? Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 LocalAssets(
  //                   imagePath: AppIconAssets.profile_camera_pic,
  //                   height: 30,
  //                   width: 30,
  //                   imgColor: AppColors.secondaryTextColor,
  //                 ),
  //                 SizedBox(height: 4),
  //                 CustomText(
  //                   AppStrings.addLiveStorePhoto,
  //                   textAlign: TextAlign.center,
  //                   fontSize: SizeConfig.extraSmall,
  //                   fontWeight: FontWeight.w400,
  //                   color: AppColors.secondaryTextColor,
  //                 ),
  //               ],
  //             ),
  //           )
  //               : null,
  //         )
  //       ),
  //       if (!isEmpty)
  //         Positioned(
  //           top: 6,
  //           right: 6,
  //           child: GestureDetector(
  //             onTap: () async {
  //               Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
  //               await controller.deleteLiveStoreImage(data);
  //               controller.businessProfileDetails.value?.data?.livePhotos?.removeAt(index);
  //               controller.update(['livePhotos']);
  //             },
  //             child: CircleAvatar(
  //               radius: 12,
  //               backgroundColor: Colors.white,
  //               child: Icon(Icons.close, size: 16, color: Colors.grey),
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }

}
