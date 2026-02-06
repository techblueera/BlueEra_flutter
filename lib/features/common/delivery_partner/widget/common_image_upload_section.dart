import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonImageUploadTile extends StatelessWidget {
  final String title;
  final Rxn<File> imageFile;
  final BuildContext context;
  final VoidCallback? onImageSelected;
  final VoidCallback? onImageRemove;

  const CommonImageUploadTile({
    super.key,
    required this.title,
    required this.imageFile,
    required this.context,
    this.onImageSelected,
    this.onImageRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = imageFile.value;

      return InkWell(
        onTap: () {
          if (file == null) {
            onImageSelected?.call();
          } else {
            Get.to(
              () => ImageViewScreen(
                appBarTitle: title,
                imageUrls: [file.path],
                initialIndex: 0,
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: AppColors.greyE5),
            boxShadow: [AppShadows.textFieldShadow],
          ),
          child: file == null
              ? Padding(
                  padding: EdgeInsets.all(SizeConfig.size12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LocalAssets(imagePath: AppIconAssets.documentUploadIcon),
                      SizedBox(width: SizeConfig.size8),
                      CustomText(
                        title,
                        fontSize: SizeConfig.medium,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: SizeConfig.size150,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(file,
                            fit: BoxFit.cover, width: double.infinity),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onImageRemove ??
                              () {
                                // onImageRemove?.call();
                                imageFile.value = null; // remove image
                              },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }

  static Future<String?> pickImage({
    required BuildContext context,
    String title = AppStrings.selectPhoto,
  }) async {
    try {
      final String? selected = await SelectProfilePictureDialog.showLogoDialog(
        context,
        title,
      );

      if (selected != null && selected.isNotEmpty) {
        return selected;
      } else {
        return null;
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.errorSelectingImage.tr} $e");
      return null;
    }
  }
}

class CommonProfileImageUpload extends StatelessWidget {
  final String title;
  final String? imgUrl;
  final Rxn<File> imageFile;
  final BuildContext context;
  final VoidCallback? onImageSelected;
  final VoidCallback? onImageRemove;

  const CommonProfileImageUpload({
    super.key,
    required this.title,
    required this.imageFile,
    required this.context,
    this.onImageSelected,
    this.onImageRemove,
    this.imgUrl,
  });
// Helper method to determine what to display
  Widget _buildImageChild() {
    // 1. Check if a local file was picked (User just selected a new image)
    if (imageFile.value != null) {
      return Image.file(
        File(imageFile.value?.path??""),
        fit: BoxFit.cover,
        width: 80,
        height: 80,
      );
    }

    // 2. Check if a Network URL exists (Existing profile data)
    if (imgUrl != null && imgUrl!.isNotEmpty) {
      return NetWorkOcToAssets(
        imgUrl: imgUrl!,
        customErrorImage: AppIconAssets.user_out_line,
      );
    }

    // 3. Default: Show the placeholder asset
    return LocalAssets(
      imagePath: AppIconAssets.user_out_line,
    );
  }
  @override
  Widget build(BuildContext context) {
    logs("imgUrl?.isNotEmpty === ${imgUrl?.isNotEmpty}");
    return Obx(() {

      return InkWell(
        onTap: () {
          onImageSelected?.call();
        },
        child: Stack(
          children: [
            InkWell(
              onTap: () => onImageSelected?.call(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryColor, width: 1),
                ),
                child: ClipOval(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.white,
                    child: _buildImageChild(), // Extracted for cleaner code
                  ),
                ),
              ),
            ),
            // InkWell(
            //   onTap: () {
            //     onImageSelected?.call();
            //   },
            //   child: Container(
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       border: Border.all(color: AppColors.primaryColor, width: 1),
            //     ),
            //     child: (imgUrl?.isNotEmpty ?? false)
            //         ? ClipOval(
            //             child: CircleAvatar(
            //                 radius: 40,
            //                 backgroundColor: AppColors.white,
            //                 child:NetWorkOcToAssets(imgUrl:imgUrl ?? "",customErrorImage: AppIconAssets.user_out_line,)),
            //           )
            //         : file == null
            //             ? CircleAvatar(
            //                 radius: 40,
            //                 backgroundColor: AppColors.white,
            //                 child: LocalAssets(
            //                     imagePath: AppIconAssets.user_out_line),
            //               )
            //             : ClipOval(
            //                 child: CircleAvatar(
            //                   radius: 40,
            //                   backgroundColor: AppColors.white,
            //                   child: (imgUrl?.isNotEmpty ?? false)
            //                       ? Image(
            //                           image: NetworkImage(imgUrl ?? "")..evict(),
            //                           fit: BoxFit.cover,
            //                           width: 100, // radius * 2
            //                           height: 100,
            //                         )
            //                       : Image(
            //                           image: FileImage(File(file.path))..evict(),
            //                           fit: BoxFit.cover,
            //                           width: 100, // radius * 2
            //                           height: 100,
            //                         ),
            //                 ),
            //               ),
            //   ),
            // ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: () {
                  logs("logMsg");
                  onImageSelected?.call();
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                    child: LocalAssets(
                      imagePath: AppIconAssets.editIcon,
                      height: SizeConfig.size14,
                      width: SizeConfig.size14,
                      imgColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  static Future<String?> pickImage({
    required BuildContext context,
    String title = AppStrings.selectPhoto,
  }) async {
    try {
      final String? selected = await SelectProfilePictureDialog.showLogoDialog(
        context,
        title,
      );

      if (selected != null && selected.isNotEmpty) {
        return selected;
      } else {
        return null;
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.errorSelectingImage.tr} $e");
      return null;
    }
  }
}
