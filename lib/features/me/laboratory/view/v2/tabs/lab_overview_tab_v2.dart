import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_contact_us_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_description_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/lab_service_photos_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/widgets/lab_banner_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overview tab for the redesigned lab "me" profile.
///
/// Mirrors the hospital v2 overview structure: cover banner first,
/// then description, gallery, contact, location, share banner, and
/// finally the QR-code card pinned at the bottom of the tab.
class LabOverviewTabV2 extends StatelessWidget {
  final LabFullDetailsController controller;

  const LabOverviewTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Obx(() {
      final d = controller.details.value;
      final profile = d?.profile;
      final contact = d?.contactInfo;
      final galleries = d?.galleries ?? <Galleries>[];
      final loc = contact?.location;
      final hasCoords = (loc?.coordinates?.isNotEmpty ?? false) &&
          loc!.coordinates!.length >= 2 &&
          loc.coordinates![0] != 0.0 &&
          loc.coordinates![1] != 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          LabBannerWidget(controller: controller),
          SizedBox(height: SizeConfig.size12),

          // ── Description ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: _DescriptionCard(
              description: profile?.description,
              onEdit: () => Get.to(() => const LabDescriptionScreen())
                  ?.then((_) => controller.fetchFullDetails()),
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          // ── Gallery ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: _GallerySection(
              galleries: galleries,
              onEdit: () => Get.to(() => LabServicePhotosPhotoScreen())
                  ?.then((_) => controller.fetchFullDetails()),
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          // ── Contact ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: _ContactCard(
              contact: contact,
              profile: profile,
              onEdit: () => Get.to(() => LabContactUsScreen())
                  ?.then((_) => controller.fetchFullDetails()),
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: WebsiteOverviewCard(
              websiteUrl: businessController
                  .businessProfileDetails.value?.data?.websiteUrl,
              onSave: (url) => businessController
                  .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          if (hasCoords)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
              child: BusinessLocationWidget(
                locationText: loc.name,
                latitude: double.parse(loc.coordinates![1].toString()),
                longitude: double.parse(loc.coordinates![0].toString()),
                businessName: profile?.name ?? '',
                padding: 0,
                isTitleShow: true,
              ),
            ),

          const BusinessShareBanner(),
          SizedBox(height: SizeConfig.size10),

          // ── QR Code (mirrors the hospital/food QR card) ──
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

class _DescriptionCard extends StatelessWidget {
  final String? description;
  final VoidCallback onEdit;

  const _DescriptionCard({required this.description, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final hasData = (description ?? '').isNotEmpty;
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.description.tr,
                  fontWeight: FontWeight.w700),
              _EditButton(onTap: onEdit),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          if (hasData)
            CustomText(
              description!,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            )
          else
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: AppStrings.labAddDescriptionForLab.tr,
              ctaIcon: Icons.description_outlined,
              onTap: onEdit,
            ),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  final List<Galleries> galleries;
  final VoidCallback onEdit;

  const _GallerySection({required this.galleries, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final allImages = galleries
        .expand((p) => p.imageUrls ?? const <String>[])
        .toList(growable: false);
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.gallery.tr, fontWeight: FontWeight.w700),
              _EditButton(onTap: onEdit),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          if (allImages.isEmpty)
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: AppStrings.gallery.tr,
              onTap: onEdit,
            )
          else
            _GalleryGrid(images: allImages),
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final List<String> images;

  const _GalleryGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;
    const double gap = 4;

    void open(int i) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: images,
            initialIndex: i,
          ),
        );

    Widget tile(int i, {bool overlay = false}) => GestureDetector(
          onTap: () => open(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: display[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
                if (overlay && extra > 0)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );

    if (display.length == 1) {
      return AspectRatio(aspectRatio: 1, child: tile(0));
    }
    if (display.length == 2) {
      return AspectRatio(
        aspectRatio: 2,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(child: tile(1)),
        ]),
      );
    }
    if (display.length == 3) {
      return AspectRatio(
        aspectRatio: 1,
        child: Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: gap),
          Expanded(
            child: Column(children: [
              Expanded(child: tile(1)),
              const SizedBox(height: gap),
              Expanded(child: tile(2)),
            ]),
          ),
        ]),
      );
    }
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(children: [
              Expanded(child: tile(0)),
              const SizedBox(width: gap),
              Expanded(child: tile(1)),
            ]),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(children: [
              Expanded(child: tile(2)),
              const SizedBox(width: gap),
              Expanded(child: tile(3, overlay: extra > 0)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ContactInfo? contact;
  final Profile? profile;
  final VoidCallback onEdit;

  const _ContactCard({
    required this.contact,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
          if (contact == null)
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: AppStrings.labAddContactInfo.tr,
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                      image: (profile?.logoUrl?.isNotEmpty ?? false)
                          ? DecorationImage(
                              image: NetworkImage(profile!.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: AssetImage(
                                  AppIconAssets.place_holder_image),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomText(profile?.name ?? '',
                      fontSize: 18, fontWeight: FontWeight.bold),
                  const SizedBox(height: 5),
                  CustomText(
                    profile?.description ?? '',
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  const Divider(height: 30),
                  if ((contact?.websiteUrl ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.website_click,
                        contact!.websiteUrl!, AppColors.primaryColor),
                  _contactItem(AppIconAssets.principal,
                      AppStrings.reception.tr, Colors.grey[700]!),
                  if ((contact?.email ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.email, contact!.email!,
                        AppColors.secondaryTextColor),
                  if ((contact?.phoneNo ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.phone_outline,
                        contact!.phoneNo!, AppColors.secondaryTextColor),
                  if ((contact?.location?.name ?? '').isNotEmpty)
                    _contactItem(AppIconAssets.location_new,
                        contact!.location!.name!, Colors.grey[700]!),
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
          LocalAssets(imagePath: icon, imgColor: iconColor),
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
