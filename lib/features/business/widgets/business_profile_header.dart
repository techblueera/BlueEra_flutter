import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/visiting_cardlist_screen.dart';
import 'package:BlueEra/features/business/widgets/blinking_verify_button.dart';
import 'package:BlueEra/features/business/widgets/business_common_widget.dart';
import 'package:BlueEra/features/business/widgets/visiting_card_preview_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import '../../../core/api/apiService/api_keys.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constant.dart';
import '../../../core/routes/route_helper.dart';
import '../../../core/services/multipart_image_service.dart';
import '../../../widgets/common_box_shadow.dart';
import '../../../widgets/local_assets.dart';
import '../../../widgets/update_live_photo_dialog.dart';
import '../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../common/food/view/food/food_categroy.dart';
import '../../common/food/view/grocery/grocery_items_categrory.dart';
import '../../common/reel/view/channel/follower_following_screen.dart';
import '../auth/controller/view_business_details_controller.dart';
import '../auth/model/viewBusinessProfileModel.dart';

import '../visiting_card/view/business_details_edit_page_one.dart';
import 'package:dio/dio.dart' as dio;

import '../visiting_card/view/widget/business_verfication.dart';

class BusinessProfileHeader extends StatelessWidget {
  final BusinessProfileDetails? details;
  final ViewBusinessDetailsController controller;

  const BusinessProfileHeader(
      {super.key, required this.details, required this.controller});

  String cleanValue(String? value) {
    if (value == null) return '';
    if (value.trim().toLowerCase() == 'na') return '';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool _isBottomSheetOpen = false;
    String ownerName = cleanValue(details!.ownerDetails?.first.name);
    String ownerRole =
        cleanValue(details?.ownerDetails?.first.role_in_business);
    String finalText =
        ownerRole.isNotEmpty ? "$ownerName ($ownerRole)" : ownerName;
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
        children: [
          // Banner + Profile Image
          Container(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image

                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
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
                        child: Image.asset('assets/diwali_card/camera.png'))),

                // Follow button & menu

                Positioned(
                  right: 12,
                  top: 140,
                  child: Container(
                    width: Get.width,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        (details?.businessIsVerified ?? false)
                            ? Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 13, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Color(0xffC5FFC9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CustomText(
                                    AppStrings.verifiedProfile,
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : Flexible(
                                child: BlinkingVerifyButton(
                                  onTap: () {
                                    Get.to(BusinessVerification());

                                    //commonSnackBar(message: "Coming soon....");
                                  },
                                ),
                              ),
                        SizedBox(
                          width: SizeConfig.size10,
                        ),
                        InkWell(
                          onTap: () {
                            Get.to(FoodCategoryPage());
                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) =>
                            //           BusinessDetailsEditPageOne(
                            //         prevBusinessDetails: details,
                            //       ),
                            //     ));

                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 5),
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryColor,
                                )),
                            child: const CustomText(
                              AppStrings.editProfile,
                              color: AppColors.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Business name and buttons
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ---- Business Name ----
                CustomText(
                  "${details?.businessName ?? ''}",
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.size24,
                ),

                const SizedBox(height: 8),

                /// ---- Category + Owner Edit Buttons ----
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InkWell(
                      onTap: () {
                        openBusinessDetailsEditSheet(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: CustomText(
                                "${details?.categoryDetails?.name ?? ''}",
                                color: AppColors.secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size10),
                            LocalAssets(
                              imagePath: AppIconAssets.editIcon,
                              height: SizeConfig.size12,
                              width: SizeConfig.size12,
                              imgColor: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        String cleanValue(String? value) {
                          if (value == null) return '';
                          if (value.trim().toLowerCase() == 'na') return '';
                          return value;
                        }

                        TextEditingController ownerNameCtrl =
                            TextEditingController(
                          text: cleanValue(details!.ownerDetails?.first.name),
                        );

                        TextEditingController ownerRoleCtrl =
                            TextEditingController(
                          text: cleanValue(
                              details?.ownerDetails?.first.role_in_business),
                        );

                        TextEditingController ownerEmailCtrl =
                            TextEditingController(
                          text: cleanValue(details?.ownerDetails?.first.email),
                        );

                        openOwnerEditSheet(
                          context: context,
                          nameController: ownerNameCtrl,
                          roleController: ownerRoleCtrl,
                          emailController: ownerEmailCtrl,
                          onSave: () async {
                            if (!GetUtils.isEmail(ownerEmailCtrl.text.trim())) {
                              commonSnackBar(
                                  message: AppStrings.pleaseEnterValidEmail);
                              return;
                            }

                            Map<String, dynamic> updatedParams = {
                              ApiKeys.owner_details: jsonEncode([
                                {
                                  ApiKeys.name: ownerNameCtrl.text,
                                  ApiKeys.role_in_business: ownerRoleCtrl.text,
                                  ApiKeys.email: ownerEmailCtrl.text,
                                }
                              ]),
                            };

                            await Get.find<ViewBusinessDetailsController>()
                                .updateBusinessDetails(updatedParams);
                            Get.back();
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.secondaryTextColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: CustomText(
                                finalText,
                                color: AppColors.secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size10),
                            LocalAssets(
                              imagePath: AppIconAssets.editIcon,
                              height: SizeConfig.size12,
                              width: SizeConfig.size12,
                              imgColor: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// ---- My Store & Visiting Card Buttons ----
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: theme.colorScheme.primary),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          if ((controller.businessProfileDetails?.data
                                          ?.livePhotos ??
                                      [])
                                  .length <
                              3) {
                            showLivePhotoDialog(context: context);
                          } else {
                            Get.toNamed(RouteHelper.getInventoryScreenRoute());
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: CustomText(
                            AppStrings.myStore,
                            color: theme.colorScheme.surface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        onPressed: () async {
                          if (_isBottomSheetOpen) return;
                          _isBottomSheetOpen = true;
                          await _showVisitingCardDialog(context);
                          _isBottomSheetOpen = false;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: CustomText(
                            AppStrings.visitingCard,
                            // AppLocalizations.of(context)!.visitingCard,
                            color: theme.colorScheme.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: SizeConfig.size10),

                /// ---- Info Stats Container ----
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size10,
                    horizontal: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.whiteE5, width: 1),
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                    boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minWidth: constraints.maxWidth),
                          child: IntrinsicWidth(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      buildInfo("${AppStrings.ratings.tr}",
                                          "★ ${(details?.rating ?? 0).toStringAsFixed(1)}"),
                                      SizedBox(height: SizeConfig.size12),
                                      buildInfo("${AppStrings.view.tr}",
                                          "${formatIndianNumber(details?.total_views ?? 0)}"),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: SizeConfig.size50,
                                  child: VerticalDivider(
                                    color: AppColors.coloGreyText,
                                    width: 12,
                                    thickness: 1.2,
                                  ),
                                ),
                                Flexible(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      buildInfo("${AppStrings.inquiries.tr}",
                                          formatIndianNumber(0)),
                                      SizedBox(height: SizeConfig.size12),
                                      InkWell(
                                        onTap: () {
                                          Get.to(() => FollowersFollowingPage(
                                                tabIndex: 1,
                                                userID: details?.userId ?? "",
                                              ));
                                        },
                                        child: buildInfo(
                                          AppStrings.followers.tr,
                                          "${formatIndianNumber(details?.total_followers ?? 0)}",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: SizeConfig.size50,
                                  child: VerticalDivider(
                                    color: AppColors.coloGreyText,
                                    width: 12,
                                    thickness: 1.2,
                                  ),
                                ),
                                SizedBox(width: SizeConfig.size15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CustomText(
                                      "${AppStrings.joined.tr}",
                                      fontSize: SizeConfig.size12,
                                      color: AppColors.secondaryTextColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    SizedBox(height: SizeConfig.size2),
                                    CustomText(
                                      formattedCreatedAt(details?.createdAt),
                                      fontSize: SizeConfig.size12,
                                      maxLines: 1,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    SizedBox(height: SizeConfig.size10),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Stats Section
        ],
      ),
    );
  }

  Future<void> _showVisitingCardDialog(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey,
      builder: (context) {
        return SizedBox(
          height: Get.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VisitingCardPreview(details: details),
                        SizedBox(height: SizeConfig.size20),

                        // visiting card designs
                        buildCard1(details!),
                        SizedBox(height: 20),
                        buildCard2(details!),
                        SizedBox(height: 20),
                        buildCard3(details!),
                        SizedBox(height: 20),
                        buildCard4(details!),
                        SizedBox(height: 20),
                        buildCard5(details!),
                        SizedBox(height: 20),
                        buildCard6(details!),
                        SizedBox(height: 20),
                        buildCard7(details!),
                        SizedBox(height: 20),

                        buildCard8(details!),
                        SizedBox(height: 20),
                        buildCard9(details!),
                        SizedBox(height: 20),

                        buildCard10(details!),
                        SizedBox(height: 20),
                        buildCard11(details!),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
