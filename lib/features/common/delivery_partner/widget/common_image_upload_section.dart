import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonImageUploadTile extends StatelessWidget {
  final String title;
  final Rxn<File> imageFile;
  final BuildContext context;
  final VoidCallback? onImageSelected;

  const CommonImageUploadTile({
    super.key,
    required this.title,
    required this.imageFile,
    required this.context,
    this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = imageFile.value;

      return InkWell(
        onTap: () {
          if(file == null){
            onImageSelected?.call();
          }else{
            Get.to(()=>
              ImageViewScreen(
                subTitle: title,
                appBarTitle: "Image Viewer",
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
                LocalAssets(imagePath: AppIconAssets.uploadIcon),
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
                  child: Image.file(file, fit: BoxFit.cover, width: double.infinity),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      imageFile.value = null; // remove image
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
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
    String title = "Select Photo",
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
        commonSnackBar(message: "Error selecting image: $e");
      return null;
    }
  }
}
