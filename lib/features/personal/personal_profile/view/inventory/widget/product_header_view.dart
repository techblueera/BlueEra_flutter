import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_hour_widget.dart';
import 'package:BlueEra/features/business/widgets/business_website_url_widget.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_business_profile_full_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/api/apiService/api_keys.dart';

class ProductProfileHeader extends StatelessWidget {
  final BusinessProfileDetails? details;
  final ViewBusinessDetailsController controller;

  const ProductProfileHeader(
      {super.key, required this.details, required this.controller});

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

    return Column(
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
                ),
                borderRadius: BorderRadiusGeometry.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
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
                            commonSnackBar(message: AppStrings.noImageSelected);
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
                  fontSize: 20,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.bold),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CommonRatingRow(
                    rating: double.tryParse(
                            details?.avg_rating.toString() ?? '0.0') ??
                        0.0,
                    reviews: details?.total_ratings?.toInt() ?? 0,
                    distance: '${calculateDistanceKm(
                      LocationService.lat,
                      LocationService.lng,
                      details?.businessLocation?.lat?.toDouble() ?? 0.0,
                      details?.businessLocation?.lon?.toDouble() ?? 0.0,
                    ).toStringAsFixed(2)} Km Away',
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.secondaryTextColor, width: 0.5),
                        borderRadius: BorderRadius.circular(100.0)),
                    child: CustomText(details?.subCategoryDetails?.name,
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.location_outline,
                    imgColor: AppColors.secondaryTextColor,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: CustomText(details?.address,
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              BusinessHoursWidget(
                days: 'Monday – Friday',
                openTime: '9:00 AM',
                closeTime: '6:00 PM',
              ),
              const SizedBox(height: 8),
              WebsiteUrlWidget(
                websiteUrl: 'https://blueera.ai',
              )
            ],
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}
