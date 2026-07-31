import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

class BusinessJoinedProfileCard extends StatelessWidget {
  final ViewBusinessDetailsController businessController;

  /// Whether the cards drop their elevation shadow. Every card here shares the
  /// same shadow, so this one flag controls all of them — pass `false` on
  /// surfaces that already sit on a shadowed/elevated container.
  final bool showShadow;

  const BusinessJoinedProfileCard({
    super.key,
    required this.businessController,
    this.showShadow = true,
  });

  /// Shared elevation shadow used by every card (joined pill, identity, cover).
  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x42001120),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  /// The shadow list to hand a card's `BoxDecoration`, or `null` when
  /// [showShadow] is off (BoxDecoration treats null as "no shadow").
  List<BoxShadow>? get _shadow => showShadow ? _cardShadow : null;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final details = businessController.businessProfileDetails.value?.data;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: SizeConfig.size8),
            _section1JoinedDate(details),
            SizedBox(height: SizeConfig.size12),
            IntrinsicWidth(

              child: _profileCardWrap(
                child: _section2IdentityRating(context, details),
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            _profileCardWrap(child: _section3CoverBanner(context)),
          ],
        ),
      );
    });
  }

  Widget _section1JoinedDate(dynamic details) {
    final joined = _formatJoinedDate(details?.createdAt?.toString());
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: _shadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              '${AppStrings.joined.tr} - $joined',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoinedDate(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '--';
    final mm = dt.month.toString().padLeft(2, '0');
    return '${dt.day}/$mm/${dt.year}';
  }

  Widget _profileCardWrap({required Widget child, bool clip = false}) {
    return Container(
      width: Get.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _shadow,
      ),
      clipBehavior: clip ? Clip.hardEdge : Clip.none,
      child: child,
    );
  }

  Widget _section2IdentityRating(BuildContext context, dynamic details) {
    final logo = businessController.imagePath?.value ?? details?.logo ?? '';
    final rating =
        double.tryParse(details?.avg_rating?.toString() ?? '0.0') ?? 0.0;
    final reviews = (details?.total_ratings ?? 0).toInt();
    final subCat =
        (details?.subCategoryDetails?.name ?? details?.typeOfBusiness ?? '')
            .toString();

    // No forced width: the card is wrapped in IntrinsicWidth by the caller, so
    // it hugs its content (name/rating) instead of stretching full width. A
    // very long name still clamps to the available width (ellipsis) because
    // IntrinsicWidth is bounded by the parent's constraints.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size12,
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _avatarWithEditPin(context, logo),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        details?.businessName ?? '',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: SizeConfig.size4),
                      CustomText(
                        subCat,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Container(height: 1, color: Colors.grey.shade200),
            SizedBox(height: SizeConfig.size10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB400)),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  rating > 0 ? rating.toStringAsFixed(1) : 'N/A',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(width: SizeConfig.size6),
                CustomText(
                  '($reviews ${reviews == 1 ? AppStrings.review.tr : '${AppStrings.review.tr}'})',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ],
        ),
    );
  }

  // Slightly larger logo with an outer ring/frame so it stands out in the
  // identity card.
  static const double _logoSize = 68;

  // Avatar shows the LOGO; both the avatar and its pin open the logo editor.
  // A circular shimmer covers it while the new logo uploads — mirroring the
  // cover banner's shimmer instead of the global progress dialog.
  Widget _avatarWithEditPin(BuildContext context, String url) {
    return SizedBox(
      width: _logoSize,
      height: _logoSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _onEditLogo(context),
              child: _logoRing(url),
            ),
          ),
          Positioned.fill(
            child: Obx(() {
              if (!businessController.isUpdateBusinessDetailsLoading.value) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: buildLoadingShimmer(
                    child: Container(color: Colors.white),
                  ),
                ),
              );
            }),
          ),
          // Edit pin straddles the circle edge — its center sits on the
          // bottom-right of the ring, so it reads half-inside / half-outside.
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _onEditLogo(context),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, size: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section3CoverBanner(BuildContext context) {
    return Obx(() {
      final cover = businessController.coverImage?.value ?? '';
      final hasBanner = cover.isNotEmpty;
      return Padding(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasBanner
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey.shade100),
                            errorWidget: (_, __, ___) =>
                                _emptyCoverPlaceholder(),
                          )
                        : _emptyCoverPlaceholder(),
                    // Shimmer overlay while the new cover uploads. The Edit
                    // button on this card fires the API with the global
                    // progress dialog silenced, so this surface owns the
                    // "uploading" feedback.
                    Obx(() {
                      if (!businessController
                          .isUpdateBusinessProfileLoading.value) {
                        return const SizedBox.shrink();
                      }
                      return buildLoadingShimmer(
                        child: Container(color: Colors.white),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.coverPhoto,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onEditCover(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size12,
                          vertical: SizeConfig.size6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.primaryColor),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(AppStrings.edit,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _emptyCoverPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined,
                size: 20, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(AppStrings.otherAddYourBannerHere.tr,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  // Circular logo with a white gap + primary-tinted outer border ring.
  Widget _logoRing(String url) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.55),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, __, ___) => _logoFallback(),
              )
            : _logoFallback(),
      ),
    );
  }

  Widget _logoFallback() => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.storefront,
            size: 20, color: AppColors.secondaryTextColor),
      );

  // ─────────────────────────────────────────────
  // EDIT HANDLERS — logo (square) and cover (16:9) are distinct uploads
  // hitting different endpoints, so editing one never clobbers the other.
  // ─────────────────────────────────────────────
  Future<void> _onEditLogo(BuildContext context) async {
    try {
      final newPath = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.uploadProfilePicture,
        cropAspectRatio: CropAspectRatio(width: 1, height: 1),
      );
      if (newPath == null || newPath.isEmpty) return;

      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );
      final dataImage =
          await multiPartImage(imagePath: compressed?.path ?? newPath);
      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }
      final details = businessController.businessProfileDetails.value?.data;
      final reqData = {
        ApiKeys.businessId: details?.id ?? '',
        ApiKeys.logo_image: dataImage,
      };
      // Silence the global progress dialog — the avatar shimmer owns the
      // "uploading" feedback (same pattern as the cover banner).
      await businessController.updateBusinessDetails(reqData,
          showProgress: false);
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  Future<void> _onEditCover(BuildContext context) async {
    try {
      final newPath = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.editCoverPicture,
        cropAspectRatio: CropAspectRatio(width: 16, height: 9),
      );
      if (newPath == null || newPath.isEmpty) return;

      // No optimistic `coverImage.value = newPath` — CachedNetworkImage can't
      // render local file paths, and assigning one here would flash the
      // "Add photo" placeholder behind the shimmer until the server URL lands.
      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );
      final dataImage =
          await multiPartImage(imagePath: compressed?.path ?? newPath);
      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }
      final details = businessController.businessProfileDetails.value?.data;
      final reqProfile = {
        ApiKeys.businessId: details?.id ?? '',
        ApiKeys.business_name: details?.businessName,
        "coverPicture": dataImage,
      };
      await businessController.updateBusinessProfileDetails(reqProfile);
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }
}
