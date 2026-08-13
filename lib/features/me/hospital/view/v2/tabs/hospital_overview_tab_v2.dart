import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_critical_care_view.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/hospital_emergency_care_screen.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/opd/hospital_opd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_contact_us_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/managment_card_widget.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_home_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overview tab for the redesigned hospital "me" profile.
///
/// Every section lives inside a shared [padded] closure so the whole tab
/// shares one horizontal inset — matching the [BusinessJoinedProfileCard]
/// cover header at the top. Change [padded] once and every section below
/// re-flows together.
class HospitalOverviewTabV2 extends StatelessWidget {
  final HospitalServiceAiController controller;

  const HospitalOverviewTabV2({super.key, required this.controller});

  /// Overview-tab detector for the departments gate. Stricter than the
  /// departments-tab version: named-but-empty departments (only chips,
  /// no doctors or beds yet) should still surface the required-card here
  /// because the OPD/IPD preview would otherwise render as a chip strip
  /// followed by "No Data found" — confusing on the overview. So a
  /// hospital only counts as having departments when at least one
  /// department carries an OPD doctor or an IPD bed/ward.
  bool _hasDepartments(HospitalFullData? data) {
    if (data == null) return false;
    return (data.departments ?? [])
        .any((d) => ((d.opd ?? []).isNotEmpty) || ((d.ipd ?? []).isNotEmpty));
  }

  /// Mirrors the facilities-tab detector. A hospital counts as having
  /// facilities when the server reports a count, any facility name is set,
  /// or at least one emergency-care / other-facility flag is true. Used
  /// only to decide whether to render the facilities preview section
  /// below — hides the whole block when empty rather than showing an
  /// empty-state card.
  bool _hasFacilities(HospitalFullData? data) {
    if (data == null) return false;
    if ((data.facilityCount ?? 0) > 0) return true;
    final named =
        (data.facilityNames ?? []).where((s) => s.trim().isNotEmpty).length;
    if (named > 0) return true;
    final ec = data.emergencyCare;
    if ((ec?.emergencyCasualty ?? false) ||
        (ec?.traumaCare ?? false) ||
        (ec?.icu ?? false) ||
        (ec?.ccu ?? false) ||
        (ec?.nicu ?? false) ||
        (ec?.picu ?? false)) return true;
    final of = data.otherFacilities;
    if ((of?.ambulance ?? false) ||
        (of?.bloodBank ?? false) ||
        (of?.diagnosticDepartments ?? false) ||
        (of?.medicalStore ?? false) ||
        (of?.pmSwasthyaBimaYojana ?? false)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    // Single source of truth for every section's horizontal inset —
    // asymmetric to leave a wider left gutter for the timeline-style
    // rhythm while keeping the right edge tight. Change here and every
    // section (including the top header) re-flows together.
    Widget padded({required Widget child}) => Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.size25,
            // right: SizeConfig.size10,
          ),
          child: child,
        );

    // Uniform vertical rhythm between sections.
    final gap = SizedBox(height: SizeConfig.size10);

    return Obx(() {
      final data = controller.hospitalDataResModel?.value.data;
      final coordinates =
          data?.contacts?.firstOrNull?.branch?.location?.coordinates;
      final hasCoords = (coordinates?.isNotEmpty ?? false) &&
          coordinates!.length >= 2 &&
          coordinates[0] != 0.0 &&
          coordinates[1] != 0.0;

      // Only used to hide the two preview sections below when the
      // hospital has no departments / no facilities yet. Everything else
      // in the overview renders unchanged.
      final hasDepartments = _hasDepartments(data);
      final hasFacilities = _hasFacilities(data);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Joined-date pill + identity + cover ──
          // Same horizontal inset as every other section below; the extra
          // top offset gives the header a bit of breathing room from the
          // tab-strip above.
          Padding(
            padding: EdgeInsets.only(
              left: SizeConfig.size16,
              // right: SizeConfig.size12,
              top: SizeConfig.size10,
            ),
            child: BusinessJoinedProfileCard(
                businessController: businessController),
          ),
          // gap,

          // ── OPD / IPD departments (read-only preview) ──
          // Mirrors the school Quick Info required pattern
          // (`_QuickInfoRequiredBanner`): when the hospital has no
          // departments the preview is replaced by a required-card with
          // an Add button that opens `HospitalOpdScreen`. On return we
          // refetch so the card auto-swaps for the real preview.
          if (hasDepartments)
            Padding(
                padding: EdgeInsets.only(left: SizeConfig.size15),
                child: HospitalBookingScreen())
          else
            Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.size25,
                right: SizeConfig.size10,
                top: SizeConfig.size10,
              ),
              child: _RequiredSectionCard(
                heading: 'Departments are required',
                message:
                    'Please add at least one OPD or IPD department. This section is mandatory to complete your hospital profile.',
                ctaLabel: 'Add Departments',
                onTap: () => Get.to(const HospitalOpdScreen())?.then(
                    (_) => controller.getHospitalFullDetailsController()),
              ),
            ),
          // gap,

          // ── Other Facilities (Emergency, ICU, CCU, Ambulance, …) ──
          // Same required-card treatment as departments above: when no
          // facility flags are set the preview is replaced by a card that
          // routes straight to `HospitalEmergencyCareScreen`.
          if (hasFacilities)
            Padding(
                padding: EdgeInsets.only(left: SizeConfig.size15),
                child: const EmergencyCriticalCareView())
          else
            Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.size25,
                right: SizeConfig.size10,
                top: SizeConfig.size10,
              ),
              child: _RequiredSectionCard(
                heading: 'Facilities are required',
                message:
                    'Please mark at least one emergency care or other facility. This section is mandatory to complete your hospital profile.',
                ctaLabel: 'Add Facilities',
                onTap: () => Get.to(const HospitalEmergencyCareScreen())?.then(
                    (_) => controller.getHospitalFullDetailsController()),
              ),
            ),
          // gap,

          // Gate: everything past this point is hidden until BOTH
          // departments AND facilities have data. Mirrors the school
          // Overview's Quick Info gate — the header and the two required
          // cards above stay visible so the user always has a way to
          // fill the missing essentials, and the rest of the profile
          // only appears once both are saved.
          if (hasDepartments && hasFacilities) ...[
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.size15),
              child: ManagementCardListWidget(isReadOnly: false),
            ),
            // gap,

            Padding(
              padding: EdgeInsets.only(right: 10, left: SizeConfig.size25),
              child: HospitalHomeGalleryWidget(
                photos: data?.gallery,
                isReadOnly: false,
              ),
            ),

            // gap,

            Padding(
              padding: EdgeInsets.only(left: SizeConfig.size15),
              child: InkWell(
                onTap: () {
                  Get.to(const HospitalJobListingScreen(isReadOnly: false));
                },
                child: cardViewWidget(title: AppStrings.jobVacancy.tr),
              ),
            ),
            // gap,

            Padding(
              padding: EdgeInsets.only(left: SizeConfig.size15),
              child: HospitalContactUsView(
                contacts: data?.contacts ?? [],
                isReadOnly: false,
                description: data?.description,
              ),
            ),
            // gap,

            padded(
              child: WebsiteOverviewCard(
                websiteUrl: businessController
                    .businessProfileDetails.value?.data?.websiteUrl,
                onSave: (url) => businessController
                    .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
              ),
            ),

            if (hasCoords) ...[
              // gap,
              padded(
                child: BusinessLocationWidget(
                  locationText:
                      data?.contacts?.firstOrNull?.branch?.location?.name,
                  latitude: double.parse(coordinates[1].toString()),
                  longitude: double.parse(coordinates[0].toString()),
                  businessName: data?.name ?? "",
                  padding: 0,
                  isTitleShow: true,
                ),
              ),
            ],

            // gap,
            padded(child: const ProfileShareBanner()),

            // ── QR Code (mirrors the lab/food QR card) ──
            Obx(() {
              final details =
                  businessController.businessProfileDetails.value?.data;
              if (details == null) return const SizedBox.shrink();
              return Column(
                children: [
                  // gap,
                  padded(
                    child: BusinessQrCodeWidget(
                      data: details,
                      // Encode the hospital deep link so scanning opens the
                      // hospital directly (`/app/business/hospital/<ownerUserId>`
                      // → DiscoverHospitalHomeScreen) rather than the generic
                      // profile share-preview.
                      deepLinkOverride:
                          hospitalDeepLink(hospitalId: details.userId),
                    ),
                  ),
                ],
              );
            }),
          ],

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}

/// Required-section card used in the overview whenever a mandatory
/// section (departments, facilities) has no data yet. Mirrors the school
/// Overview's `_QuickInfoRequiredBanner`: white card with an empty-state
/// illustration, heading + message, and a primary "Add" pill that routes
/// straight to the add screen so the user can fill the missing data
/// without leaving the overview.
class _RequiredSectionCard extends StatelessWidget {
  final String heading;
  final String message;
  final String ctaLabel;
  final VoidCallback onTap;

  const _RequiredSectionCard({
    required this.heading,
    required this.message,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppIconAssets.emptyIcon,
            height: 60,
            width: 60,
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            heading,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            message,
            fontSize: 13,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
          SizedBox(height: SizeConfig.size16),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  CustomText(
                    ctaLabel,
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
