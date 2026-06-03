import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_description_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';

/// ManufacturerProduct/Inventory overview body — mirrors the grocery v2 home
/// screen's overview structure piece for piece: joined-date pill +
/// identity card with edit pin + cover banner, then live photos,
/// description, contact-map card, QR code and share banner.
class ManufacturerProductHomeScreen extends StatefulWidget {
  const ManufacturerProductHomeScreen({super.key});

  @override
  State<ManufacturerProductHomeScreen> createState() => _ProductHomeScreenState();
}

class _ProductHomeScreenState extends State<ManufacturerProductHomeScreen> {
  final controller = getOrPut(() => ManufacturerInventoryController());
  final _businessController = Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Get.isRegistered<BottomBarController>() &&
          Get.find<BottomBarController>().currentIndex.value != 0) {
        return;
      }
      showBusinessLivePhotoBottomSheetIfNeeded(
        context: context,
        controller: _businessController,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Content-only — the outer CustomScrollView in InventoryScreen
    // owns the scroll + RefreshIndicator. Returning a Column lets this
    // widget render flat inside the parent scroll context.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildJoinedProfileCard(),
        SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: CommonBusinessLivePhoto(
            controller: _businessController,
          ),
        ),
        SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: const BusinessDescriptionCard(),
        ),
        SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: Obx(() {
            final details = _businessController.businessProfileDetails.value?.data;
            return BusinessContactMapCard(
              businessProfileDetails: details,
            );
          }),
        ),
        SizedBox(height: SizeConfig.size12),
        _buildQrCodeSection(),
        SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: const BusinessShareBanner(),
        ),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // JOINED + IDENTITY + COVER STACK — three stacked cards. Card
  // containers share the #00112042 / blur-10 shadow language used
  // across other section cards.
  // ─────────────────────────────────────────────
  Widget _buildJoinedProfileCard() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _section1JoinedDate(details),
            SizedBox(height: SizeConfig.size12),
            IntrinsicWidth(
              child: _profileCardWrap(
                child: _section2IdentityRating(details),
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            _profileCardWrap(child: _section3CoverBanner()),
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
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x42001120),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              'Joined - $joined',
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: clip ? Clip.hardEdge : Clip.none,
      child: child,
    );
  }

  Widget _section2IdentityRating(dynamic details) {
    final logo = _businessController.imagePath?.value ?? details?.logo ?? '';
    final rating = double.tryParse(details?.avg_rating?.toString() ?? '0.0') ?? 0.0;
    final reviews = (details?.total_ratings ?? 0).toInt();
    final subCat = (details?.subCategoryDetails?.name ?? details?.typeOfBusiness ?? '').toString();

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
              _avatarWithEditPin(logo),
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
                '($reviews ${reviews == 1 ? 'review' : 'reviews'})',
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

  Widget _avatarWithEditPin(String url) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _onEditCover,
              child: _avatar(
                url: url,
                size: 56,
                ringColor: AppColors.primaryColor.withValues(alpha: 0.35),
                ringWidth: 1.5,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: _onEditCover,
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

  Widget _section3CoverBanner() {
    return Obx(() {
      final cover = _businessController.coverImage?.value ?? '';
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
                            placeholder: (_, __) => Container(color: Colors.grey.shade100),
                            errorWidget: (_, __, ___) => _emptyCoverPlaceholder(),
                          )
                        : _emptyCoverPlaceholder(),
                    // Shimmer overlay while the new cover is uploading.
                    // The Edit button on this card kicks off the API
                    // call with `showProgress: false`, so the global
                    // progress dialog is silenced and this surface
                    // owns the "uploading" feedback.
                    Obx(() {
                      if (!_businessController.isUpdateBusinessProfileLoading.value) {
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
                      'Cover Photo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _onEditCover,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
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
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryColor),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(AppStrings.edit,
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryColor),
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
            Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(AppStrings.otherAddYourBannerHere.tr,
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _avatar({
    required String url,
    required double size,
    required Color ringColor,
    required double ringWidth,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: ringWidth),
      ),
      clipBehavior: Clip.hardEdge,
      child: url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _logoFallback(),
            )
          : _logoFallback(),
    );
  }

  Widget _logoFallback() => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.storefront, size: 20, color: AppColors.secondaryTextColor),
      );

  // ─────────────────────────────────────────────
  // QR CODE — share/download the business profile
  // ─────────────────────────────────────────────
  Widget _buildQrCodeSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: BusinessQrCodeWidget(data: details),
      );
    });
  }

  Future<void> _onEditCover() async {
    try {
      final newPath = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.editCoverPicture,
        cropAspectRatio: CropAspectRatio(width: 16, height: 9),
      );
      if (newPath == null || newPath.isEmpty) return;

      // No optimistic `coverImage.value = newPath` — CachedNetworkImage
      // can't render local file paths, and assigning one here would
      // flash the "Add photo" placeholder behind the shimmer overlay
      // until the server-confirmed URL lands.
      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );
      final dataImage = await multiPartImage(imagePath: compressed?.path ?? newPath);
      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }
      final details = _businessController.businessProfileDetails.value?.data;
      final reqProfile = {
        ApiKeys.businessId: details?.id ?? '',
        ApiKeys.business_name: details?.businessName,
        "coverPicture": dataImage,
      };
      await _businessController.updateBusinessProfileDetails(reqProfile);
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }
}
