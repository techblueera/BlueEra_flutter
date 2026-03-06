import 'dart:io';
import 'package:BlueEra/core/api/model/new_food_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;

import '../../../../../core/api/apiService/api_keys.dart';

class FoodHomeProfileHeader extends StatelessWidget {
  final BusinessProfileDetails? details;
  final ViewBusinessDetailsController controller;

  const FoodHomeProfileHeader(
      {super.key, required this.details,required this.controller});

  String cleanValue(String? value) {
    if (value == null) return '';
    if (value.trim().toLowerCase() == 'na') return '';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    String _getCoverImage(controller) {
      final cover = controller.coverImage?.value;
      final profile =
          controller.imagePath?.value; // or controller.businessImage?.value

      if (cover != null && cover.isNotEmpty) {
        return cover;
      }

      if (profile != null && profile.isNotEmpty) {
        return profile;
      }

      return ''; // shows empty widget in errorBuilder
    }

    return Container(
      // margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + Profile Image
          Container(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image

                ClipRRect(
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Image.network(
                      _getCoverImage(controller),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox();
                      },
                    ),
                  ),borderRadius: BorderRadiusGeometry.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
                ),

                // Profile image overlapping banner bottom
                Positioned(
                  left: 20,

                  top: 90, // makes it overlap smoothly
                  child: CommonProfileImage(
                    imagePath: controller.imagePath?.value ?? "",
                    onImageUpdate: (image) async {
                      controller.imagePath?.value = image;
                      dio.MultipartFile? imageByPart;
                      // if (viewBusinessDetailsController.isImageUpdated.value) {
                      if (controller.imagePath?.value.isNotEmpty ?? false) {
                        String fileName =
                            controller.imagePath?.value.split('/').last ?? "";
                        imageByPart = await dio.MultipartFile.fromFile(
                            controller.imagePath?.value ?? "",
                            filename: fileName);
                      }
                      // }
                      dynamic reqData = {
                        ApiKeys.businessId: businessId,
                        ApiKeys.logo_image: imageByPart,
                      };

                      await controller.updateBusinessDetails(reqData);
                    },
                    dialogTitle: AppStrings.uploadBusinessLogo.tr,
                  ),
                ),
                Positioned(
                    right: 10,
                    top: 8,
                    child: InkWell(
                        onTap: () async {
                          try {
                            final newPath =
                                await SelectProfilePictureDialog.showLogoDialog(
                                        context, AppStrings.editCoverPicture.tr,
                                        cropAspectRatio:
                                            CropAspectRatio(width: 3, height: 1)
                                        // cropAspectRatio: CropAspectRatio(width: 16, height: 9)
                                        )
                                    .catchError((_) => null);

                            if (newPath == null || newPath.isEmpty) {
                              commonSnackBar(
                                  message: AppStrings.noImageSelected);
                              return;
                            }

                            controller.coverImage?.value = newPath;

                            // Compress before upload
                            final file = File(newPath);
                            final compressed =
                                await FlutterImageCompress.compressAndGetFile(
                              file.absolute.path,
                              "${file.path}_compressed.jpg",
                              quality: 75,
                            );

                            final dataImage = await multiPartImage(
                              imagePath: compressed?.path ?? newPath,
                            );

                            if (dataImage == null) {
                              commonSnackBar(
                                  message: AppStrings.imageProcessingFailed);
                              return;
                            }

                            final reqProfile = {
                              ApiKeys.businessId: businessId,
                              ApiKeys.business_name: details?.businessName,
                              "coverPicture": dataImage
                            };
                            await controller
                                .updateBusinessProfileDetails(reqProfile);
                          } catch (e) {
                            commonSnackBar(
                                message: AppStrings.updatePictureFailed);
                          }
                        },
                        child: Image.asset('assets/images/camera.png'))),

                // Follow button & menu
              ],
            ),
          ),
          // --- FORM SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                CustomText(details?.businessName,
                    fontSize: 18,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
                const SizedBox(height: 10),
                ExpandableText(
                  text: details?.businessDescription ?? "",
                  trimLines: 4,
                  isReadMoreNewLine: false,
                  expandMode: ExpandMode.dialog,
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppConstants.OpenSans,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
class FoodHomeProfileHeaderReadOnly extends StatelessWidget {
final  BusinessProfile? businessProfile;

  FoodHomeProfileHeaderReadOnly(
      {super.key, this.businessProfile, });

  String cleanValue(String? value) {
    if (value == null) return '';
    if (value.trim().toLowerCase() == 'na') return '';
    return value;
  }

  @override
  Widget build(BuildContext context) {


    return Container(
      // margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + Profile Image
          Container(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image

                ClipRRect(
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Image.network(
                  businessProfile?.logo??"",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox();
                      },
                    ),
                  ),borderRadius: BorderRadiusGeometry.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
                ),

                Positioned(
                  left: 20,

                  top: 90, // makes it overlap smoothly
                  child: CommonProfileImage(
                    imagePath: businessProfile?.logo ?? "",isOwnProfile: false,
                    onImageUpdate: (image) async {

                    },
                    dialogTitle: AppStrings.uploadBusinessLogo.tr,
                  ),
                ),


                // Follow button & menu
              ],
            ),
          ),
          // --- FORM SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                CustomText(businessProfile?.businessName,
                    fontSize: 18,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.bold),
                const SizedBox(height: 10),
                ExpandableText(
                  text: businessProfile?.businessDescription ?? "",
                  trimLines: 4,
                  isReadMoreNewLine: false,
                  expandMode: ExpandMode.dialog,
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppConstants.OpenSans,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
