import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
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
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../category/acadamics/school_quick_info_form_screen.dart';
import '../../category/acadamics/widgets/school_quick_info_view.dart';

/// Overview tab for the redesigned school "me" profile.
///
/// Layout mirrors the product/inventory v2 overview: shared joined-date +
/// identity + cover card, live photos, business description, then the
/// school-specific sections (director, management, campus life,
/// availability, contact us, location), followed by website, QR, and share
/// banner.
///
/// Every top-level child sits inside [_hPad] so the outer edges of every
/// card align at [_hInset] from both screen edges. `BusinessJoinedProfileCard`
/// is the sole exception — it self-pads internally at the same inset, so
/// wrapping it again would double the gutter.
class SchoolOverviewTabV2 extends StatefulWidget {
  final SchoolAboutUsController controller;

  const SchoolOverviewTabV2({super.key, required this.controller});

  @override
  State<SchoolOverviewTabV2> createState() => _SchoolOverviewTabV2State();
}

class _SchoolOverviewTabV2State extends State<SchoolOverviewTabV2> {
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  // Single source of truth for horizontal gutter used across every card in
  // this tab. Change here and every section stays aligned.
  double get _hInset => SizeConfig.size12;

  Widget _hPad({required Widget child}) => Padding(
        padding: EdgeInsets.symmetric(horizontal: _hInset),
        child: child,
      );

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
    return Obx(() {
      final data = widget.controller.schoolDetailsData?.value;
      final coordinates = data?.location?.coordinates;
      final hasCoords = (coordinates?.isNotEmpty ?? false) &&
          coordinates!.length >= 2 &&
          coordinates[0] != 0.0 &&
          coordinates[1] != 0.0;

      final principal = data?.aboutId?.principalMessage;
      final hasDirector = (principal?.name?.isNotEmpty ?? false) ||
          (principal?.message?.isNotEmpty ?? false);

      final management = data?.aboutId?.management ?? const [];
      final campusLife = data?.campusLife ?? const [];
      final contacts = data?.contacts ?? const [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Joined date + identity + cover (self-pads at _hInset) ──
          BusinessJoinedProfileCard(businessController: _businessController),

          // SizedBox(height: SizeConfig.size10),

          // ── Director / Principal Message ──
          // _hPad(
          //   child:
          hasDirector
              ? DirectorCard(
                  schoolAboutUsController: widget.controller,
                  isEdit: true,
                )
              : _SectionEmptyCard(
                  title: AppStrings.principalDirectorMessage.tr,
                  ctaLabel: AppStrings.principalDirectorMessage.tr,
                  ctaIcon: Icons.person_outline,
                  onTap: () => Get.to(PrincipalMessageScreen())?.then(
                      (_) => widget.controller.getSchoolByIdController()),
                ),
          // ),

          // SizedBox(height: SizeConfig.size10),

          // ── School Quick Info (Class range / Ratio / Medium) ──
          _hPad(
            child: SchoolQuickInfoCard(
              controller: widget.controller,
              onEditTap: () => Get.to(const SchoolQuickInfoFormScreen())
                  ?.then((_) => widget.controller.getSchoolByIdController()),
            ),
          ),

          // SizedBox(height: SizeConfig.size10),

          // ── Management ──
          // _hPad(
          //   child:
          management.isNotEmpty
              ? SchoolManagementSection(
                  managementData: management,
                  isEdit: true,
                )
              : _SectionEmptyCard(
                  title: AppStrings.managementTrust.tr,
                  ctaLabel: AppStrings.managementTrust.tr,
                  ctaIcon: Icons.groups_outlined,
                  onTap: () => Get.to(ManagementTrustFormScreen(isEdit: false))
                      ?.then(
                          (_) => widget.controller.getSchoolByIdController()),
                ),
          // ),

          // SizedBox(height: SizeConfig.size10),

          // ── Availability ──
          _hPad(
            child: SchoolAvailabilityCard(
              controller: widget.controller,
              onEditTap: () => Get.to(const AvailabilityFormScreen())
                  ?.then((_) => widget.controller.getSchoolByIdController()),
            ),
          ),

          // SizedBox(height: SizeConfig.size10),

          // ── Live photos ──
          _hPad(
            child: CommonBusinessLivePhoto(controller: _businessController),
          ),

          SizedBox(height: SizeConfig.size10),

          // ── Campus Life Gallery ──
          _hPad(
            child: campusLife.isNotEmpty
                ? CampusPhotoGallery(
                    campusLife: campusLife,
                    isEdit: true,
                  )
                : _SectionEmptyCard(
                    title: AppStrings.campusLife.tr,
                    ctaLabel: AppStrings.campusLife.tr,
                    onTap: () => Get.to(CampusLifeListingScreen())?.then(
                        (_) => widget.controller.getSchoolByIdController()),
                  ),
          ),

          // SizedBox(height: SizeConfig.size10),

          // ── Contact Us ──
          _hPad(
            child: contacts.isNotEmpty
                ? ContactUsSection(
                    isEdit: true,
                    contacts: contacts,
                  )
                : _SectionEmptyCard(
                    title: AppStrings.contactUs.tr,
                    ctaLabel: AppStrings.contactUs.tr,
                    ctaIcon: Icons.contact_phone_outlined,
                    onTap: () => Get.to(contact_us.SchoolContactUs())?.then(
                        (_) => widget.controller.getSchoolByIdController()),
                  ),
          ),

          SizedBox(height: SizeConfig.size10),

          // ── Website (shared, business data) ──
          _hPad(
            child: Obx(() {
              final details =
                  _businessController.businessProfileDetails.value?.data;
              return WebsiteOverviewCard(
                websiteUrl: details?.websiteUrl,
                onSave: (url) => _businessController
                    .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
              );
            }),
          ),

          // ── Location (school data) ──
          if (hasCoords) SizedBox(height: SizeConfig.size10),
          if (hasCoords)
            _hPad(
              child: CommonCardWidget(
                padding: 5,
                cardMargin: 0,
                child: BusinessLocationWidget(
                  locationText: data?.name,
                  latitude: double.parse(coordinates[0].toString()),
                  longitude: double.parse(coordinates[1].toString()),
                  businessName: data?.name ?? '',
                  padding: 0,
                  isTitleShow: true,
                ),
              ),
            ),

          // SizedBox(height: SizeConfig.size10),

          // ── QR Code (shared) ──
          _hPad(child: _buildQrCodeSection()),

          // SizedBox(height: SizeConfig.size10),

          // ── Share banner (shared) ──
          _hPad(child: const ProfileShareBanner()),

          SizedBox(height: SizeConfig.size16),
        ],
      );
    });
  }

  Widget _buildQrCodeSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return NewBusinessQrCodeWidget(data: details);
    });
  }
}

/// Titled card used for any school section that has no data yet — shows
/// the section heading + edit pill, then the shared greyscale
/// placeholder image with a tap-to-add CTA underneath. No horizontal
/// padding here — the parent tab applies the shared gutter via `_hPad`.
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
    return CommonCardWidget(
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
