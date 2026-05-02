import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_contact_us/hotel_contact_us.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_photos_screen.dart';
import 'package:BlueEra/features/me/hotel/view/v2/widgets/hotel_banner_widget.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_home_gallery_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overview tab for the redesigned hotel "me" profile.
///
/// Mirrors the hospital v2 overview structure: cover banner first,
/// then gallery, contact, location, share banner, and the QR-code card
/// pinned at the bottom of the tab.
class HotelOverviewTabV2 extends StatelessWidget {
  final HotelDetailController controller;

  const HotelOverviewTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Obx(() {
      final profile = controller.hotelData.value?.profile;
      final loc = profile?.locationHotel;
      final hasCoords = loc != null &&
          loc.latitude != null &&
          loc.longitude != null &&
          double.tryParse(loc.latitude.toString()) != 0.0 &&
          double.tryParse(loc.longitude.toString()) != 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          HotelBannerWidget(controller: controller),
          SizedBox(height: SizeConfig.size12),

          // ── Gallery ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: _GallerySection(
              photos: profile?.photos,
              onEdit: () => Get.to(PropertyPhotoScreen())
                  ?.then((_) => controller.loadHotelData()),
            ),
          ),
          SizedBox(height: SizeConfig.size12),

          // ── Contact ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: _ContactCard(
              profile: profile,
              onEdit: () => Get.to(const HotelContactUs())
                  ?.then((_) => controller.loadHotelData()),
            ),
          ),
          SizedBox(height: SizeConfig.size12),

          if (hasCoords)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
              child: BusinessLocationWidget(
                locationText: loc.name,
                latitude: double.parse(loc.latitude.toString()),
                longitude: double.parse(loc.longitude.toString()),
                businessName: (profile?.name?.isNotEmpty ?? false)
                    ? profile!.name!
                    : businessNameGlobal,
                padding: 0,
                isTitleShow: true,
              ),
            ),

          const BusinessShareBanner(),
          SizedBox(height: SizeConfig.size10),

          // ── QR Code (mirrors the hospital QR card) ──
          Obx(() {
            final details =
                businessController.businessProfileDetails.value?.data;
            if (details == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
              child: BusinessQrCodeWidget(data: details),
            );
          }),

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}

class _GallerySection extends StatelessWidget {
  final List<Photos>? photos;
  final VoidCallback onEdit;

  const _GallerySection({required this.photos, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final hasPhotos = photos?.isNotEmpty ?? false;
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.hotelGallery.tr,
                  fontWeight: FontWeight.w700),
              _EditButton(onTap: onEdit),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          if (hasPhotos)
            HotelHomeGalleryWidget(photos: photos)
          else
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: AppStrings.hotelNoPhotosAdded.tr,
              onTap: onEdit,
            ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Profile? profile;
  final VoidCallback onEdit;

  const _ContactCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final hasContacts = profile?.contacts?.isNotEmpty ?? false;
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.contactUs.tr,
                  fontWeight: FontWeight.w700),
              _EditButton(onTap: onEdit),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (!hasContacts)
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: AppStrings.hotelNoContactDetailsAdded.tr,
              ctaIcon: Icons.contact_phone_outlined,
              onTap: onEdit,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((profile?.logoUrl?.isNotEmpty ?? false) ||
                      (profile?.photos?.isNotEmpty ?? false))
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(
                            (profile?.logoUrl?.isNotEmpty ?? false)
                                ? profile!.logoUrl!
                                : (profile?.photos?.first.imageReferences
                                        ?.first ??
                                    ''),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  CustomText(
                    (profile?.name?.isNotEmpty ?? false)
                        ? profile!.name!
                        : businessNameGlobal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 5),
                  CustomText(
                    profile?.description ?? '',
                    color: AppColors.secondaryTextColor,
                    fontSize: 12,
                  ),
                  const Divider(height: 30),
                  if ((profile?.website ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.website_click,
                        profile!.website!, AppColors.primaryColor),
                  _contactItem(AppIconAssets.principal,
                      AppStrings.reception.tr, Colors.grey[700]!),
                  _contactItem(
                      AppIconAssets.email,
                      profile?.contacts?.firstOrNull?.email ?? 'N/A',
                      AppColors.secondaryTextColor),
                  _contactItem(
                      AppIconAssets.phone_outline,
                      profile?.contacts?.firstOrNull?.phone ?? 'N/A',
                      AppColors.secondaryTextColor),
                  _contactItem(AppIconAssets.location_new,
                      profile?.locationHotel?.name ?? 'N/A',
                      Colors.grey[700]!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
              imagePath: icon, imgColor: iconColor, height: 20, width: 20),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(label, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined,
                size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.edit.tr,
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
