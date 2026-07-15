import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/availability_form_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/managment_trust_form_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/principal_message_screen.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/school_contact_us.dart'
    as contact_us;
import 'package:BlueEra/features/me/school/view/category/school_home/school_availability_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_campus_photo_gallery_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_contact_us_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_director_card_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_management_view.dart';
import 'package:BlueEra/features/me/school/view/v2/widgets/school_banner_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overview tab for the redesigned school "me" profile.
///
/// Each section renders its existing widget when populated, otherwise a
/// titled card with the shared b&w `EmptySectionPlaceholder` so the
/// owner gets a clear "tap to add" affordance for every missing block.
class SchoolOverviewTabV2 extends StatelessWidget {
  final SchoolAboutUsController controller;

  const SchoolOverviewTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final businessController = getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Obx(() {
      final data = controller.schoolDetailsData?.value;
      final coordinates = data?.location?.coordinates;
      final hasCoords = (coordinates?.isNotEmpty ?? false) &&
          coordinates!.length >= 2 &&
          coordinates[0] != 0.0 &&
          coordinates[1] != 0.0;

      final principal = data?.aboutId?.principalMessage;
      final hasDirector = (principal?.name?.isNotEmpty ?? false) || (principal?.message?.isNotEmpty ?? false);

      final management = data?.aboutId?.management ?? const [];
      final campusLife = data?.campusLife ?? const [];
      final contacts = data?.contacts ?? const [];
      // final availability = data?.availability ?? const [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          SchoolBannerWidget(controller: controller),
          SizedBox(height: SizeConfig.size12),

          // ── Director / Principal Message ──
          if (hasDirector)
            DirectorCard(
              schoolAboutUsController: controller,
              isEdit: true,
            )
          else
            _SectionEmptyCard(
              title: AppStrings.principalDirectorMessage.tr,
              ctaLabel: AppStrings.principalDirectorMessage.tr,
              ctaIcon: Icons.person_outline,
              onTap: () =>
                  Get.to(PrincipalMessageScreen())?.then((_) => controller.getSchoolByIdController()),
            ),

          // ── Management ──
          if (management.isNotEmpty)
            SchoolManagementSection(
              managementData: management,
              isEdit: true,
            )
          else
            _SectionEmptyCard(
              title: AppStrings.managementTrust.tr,
              ctaLabel: AppStrings.managementTrust.tr,
              ctaIcon: Icons.groups_outlined,
              onTap: () => Get.to(ManagementTrustFormScreen(isEdit: false))
                  ?.then((_) => controller.getSchoolByIdController()),
            ),

          // ── Campus Life Gallery ──
          if (campusLife.isNotEmpty)
            CampusPhotoGallery(
              campusLife: campusLife,
              isEdit: true,
            )
          else
            _SectionEmptyCard(
              title: AppStrings.campusLife.tr,
              ctaLabel: AppStrings.campusLife.tr,
              onTap: () =>
                  Get.to(CampusLifeListingScreen())?.then((_) => controller.getSchoolByIdController()),
            ),

          SizedBox(height: SizeConfig.size10),

          // ── Availability ──
          // if (availability.isNotEmpty)
          SchoolAvailabilityCard(
            controller: controller,
            onEditTap: () =>
                Get.to(const AvailabilityFormScreen())?.then((_) => controller.getSchoolByIdController()),
          ),
          // else
          //   _SectionEmptyCard(
          //     title: AppStrings.setYourAvailability.tr,
          //     ctaLabel: AppStrings.setYourAvailability.tr,
          //     ctaIcon: Icons.schedule_outlined,
          //     onTap: () => Get.to(const AvailabilityFormScreen())
          //         ?.then((_) => controller.getSchoolByIdController()),
          //   ),

          SizedBox(height: SizeConfig.size10),

          // ── Contact Us ──
          if (contacts.isNotEmpty)
            ContactUsSection(
              isEdit: true,
              contacts: contacts,
            )
          else
            _SectionEmptyCard(
              title: AppStrings.contactUs.tr,
              ctaLabel: AppStrings.contactUs.tr,
              ctaIcon: Icons.contact_phone_outlined,
              onTap: () =>
                  Get.to(contact_us.SchoolContactUs())?.then((_) => controller.getSchoolByIdController()),
            ),

          SizedBox(height: SizeConfig.size10),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: WebsiteOverviewCard(
              websiteUrl: businessController.businessProfileDetails.value?.data?.websiteUrl,
              onSave: (url) => businessController.updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
            ),
          ),

          SizedBox(height: SizeConfig.size10),

          if (hasCoords)
            CommonCardWidget(
              padding: 5,
              child: BusinessLocationWidget(
                locationText: data?.name,
                latitude: double.parse(coordinates[0].toString()),
                longitude: double.parse(coordinates[1].toString()),
                businessName: data?.name ?? '',
                padding: 0,
                isTitleShow: true,
              ),
            ),

          const ProfileShareBanner(),
          SizedBox(height: SizeConfig.size10),

          // ── QR Code (mirrors the hospital QR card) ──
          Obx(() {
            final details = businessController.businessProfileDetails.value?.data;
            if (details == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
              child: NewBusinessQrCodeWidget(data: details),
            );
          }),

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}

/// Titled card used for any school section that has no data yet — shows
/// the section heading + edit pill, then the shared greyscale
/// placeholder image with a tap-to-add CTA underneath.
class _SectionEmptyCard extends StatelessWidget {
  final String title;
  final String ctaLabel;
  final IconData ctaIcon;
  final VoidCallback onTap;

  const _SectionEmptyCard({
    required this.title,
    required this.ctaLabel,
    required this.onTap,
    this.ctaIcon = Icons.add_photo_alternate_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      child: CommonCardWidget(
        padding: 10,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(title, fontWeight: FontWeight.w700),
                _EditPill(onTap: onTap),
              ],
            ),
            SizedBox(height: SizeConfig.size8),
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: ctaLabel,
              ctaIcon: ctaIcon,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  final VoidCallback onTap;
  const _EditPill({required this.onTap});

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
            Icon(Icons.add, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              AppStrings.add.tr,
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
