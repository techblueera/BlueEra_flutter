import 'package:BlueEra/core/api/apiService/api_keys.dart';
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
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_critical_care_view.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_contact_us_view.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/managment_card_widget.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_home_screen.dart';
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
          Padding(
              padding: EdgeInsets.only(left: SizeConfig.size15),
              child: HospitalBookingScreen()),
          // gap,

          // ── Other Facilities (Emergency, ICU, CCU, Ambulance, …) ──
          // Read-only returns SizedBox.shrink() when the hospital has no
          // facilities, so the section auto-collapses when empty.
          Padding(
              padding: EdgeInsets.only(left: SizeConfig.size15),
              child: const EmergencyCriticalCareView()),
          // gap,

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

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}
