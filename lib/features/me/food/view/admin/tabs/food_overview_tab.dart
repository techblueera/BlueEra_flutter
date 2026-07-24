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

/// **Overview** tab of the restaurant merchant home: the profile the customer
/// sees — joined card, live photos, description, contact/map, website, QR and
/// the referral share banner.
///
/// Every section reads from the permanent [ViewBusinessDetailsController], so
/// this tab fires no food API of its own.
///
/// Content-only: the host wraps it in the shared refreshable scroll view,
/// which pads `left: 20` and nothing on the right — hence the symmetric
/// 12-px insets below (they add to the left inset the host already applies).
class FoodOverviewTab extends StatelessWidget {
  const FoodOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final businessController =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BusinessJoinedProfileCard(businessController: businessController),
        // Live photos use the same shared widget the grocery home renders, so
        // styling and behaviour stay in sync across me-section.
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
            final details = businessController.businessProfileDetails.value?.data;
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
            final details = businessController.businessProfileDetails.value?.data;
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

  // QR CODE â€” share/download the business profile.
  Widget _qrCodeSection(ViewBusinessDetailsController businessController) {
    return Obx(() {
      final details = businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: BusinessQrCodeWidget(data: details),
      );
    });
  }
}
