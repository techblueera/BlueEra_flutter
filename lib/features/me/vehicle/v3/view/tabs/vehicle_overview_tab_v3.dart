import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_description_card.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Overview** tab of the vehicle showroom home — the profile a customer
/// sees: joined card, live photos, description, website, contact/map, QR and
/// the referral banner.
///
/// Identical in composition to the grocery overview tab; all of it reads the
/// permanent [ViewBusinessDetailsController], so this tab makes no
/// vehicle-service calls at all. That matters for v3 in particular: the old
/// vehicle overview was built on `/facilities`, `/gallery`, `/testimonials`
/// and `/contact-us`, every one of which the rebuilt service dropped.
///
/// Content-only — the host wraps it in the shared refreshable scroll view,
/// which pads `left: 20` and nothing on the right, hence the symmetric 12-px
/// insets below.
class VehicleOverviewTabV3 extends StatelessWidget {
  const VehicleOverviewTabV3({super.key});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BusinessJoinedProfileCard(businessController: businessController),
        SizedBox(height: SizeConfig.size2),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: CommonBusinessLivePhoto(controller: businessController),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: const BusinessDescriptionCard(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: Obx(() {
            final details =
                businessController.businessProfileDetails.value?.data;
            return WebsiteOverviewCard(
              websiteUrl: details?.websiteUrl,
              onSave: (url) => businessController
                  .updateBusinessProfileDetails({ApiKeys.websiteUrl: url}),
            );
          }),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: Obx(() {
            final details =
                businessController.businessProfileDetails.value?.data;
            return BusinessContactMapCard(businessProfileDetails: details);
          }),
        ),
        _qrCodeSection(businessController),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: const ProfileShareBanner(),
        ),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  Widget _qrCodeSection(ViewBusinessDetailsController businessController) {
    return Obx(() {
      final details = businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        // No deep-link override: unlike grocery there is no dedicated
        // storefront landing for a showroom yet, so the QR keeps the generic
        // business-profile link.
        child: BusinessQrCodeWidget(data: details),
      );
    });
  }
}
