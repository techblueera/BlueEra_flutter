import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_contact_us_view.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/hospital_banner_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/managment_card_widget.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overview tab for the redesigned hospital "me" profile.
/// Aggregates header, management, gallery, contact, location, share banner
/// and the job-listing entry — preserving all functionality from the
/// original `HospitalHomeScreen`.
class HospitalOverviewTabV2 extends StatelessWidget {
  final HospitalServiceAiController controller;

  const HospitalOverviewTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);
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
          SizedBox(height: SizeConfig.size12),
          HospitalBannerWidget(controller: controller),
          SizedBox(height: SizeConfig.size12),
          // const HospitalHeaderView(isReadOnly: false),
          ManagementCardListWidget(isReadOnly: false),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size8),
            child: HospitalHomeGalleryWidget(
              photos: data?.gallery,
              isReadOnly: false,
            ),
          ),
          SizedBox(height: SizeConfig.size10),
          InkWell(
            onTap: () {
              Get.to(const HospitalJobListingScreen(isReadOnly: false));
            },
            child: cardViewWidget(title: AppStrings.jobVacancy.tr),
          ),
          SizedBox(height: SizeConfig.size10),
          HospitalContactUsView(
            contacts: data?.contacts ?? [],
            isReadOnly: false,
            description: data?.description,
          ),
          SizedBox(height: SizeConfig.size10),
          if (hasCoords)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
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
          const BusinessShareBanner(),
          SizedBox(height: SizeConfig.size10),

          // ── QR Code (mirrors the food home screen QR card) ──
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
