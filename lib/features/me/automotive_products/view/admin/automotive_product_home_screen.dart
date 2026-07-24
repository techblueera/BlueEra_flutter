import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/business/widgets/business_description_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// AutomotiveProduct/Inventory overview body — mirrors the grocery v2 home
/// screen's overview structure: shared joined-date + identity + cover card,
/// then live photos, description, contact-map card, QR code and share banner.
class AutomotiveProductHomeScreen extends StatefulWidget {
  const AutomotiveProductHomeScreen({super.key});

  @override
  State<AutomotiveProductHomeScreen> createState() => _AutomotiveProductHomeScreenState();
}

class _AutomotiveProductHomeScreenState extends State<AutomotiveProductHomeScreen> {
  final controller = getOrPut(() => AutomotiveInventoryController());
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
        BusinessJoinedProfileCard(businessController: _businessController),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: CommonBusinessLivePhoto(
            controller: _businessController,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: const BusinessDescriptionCard(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: Obx(() {
            final details =
                _businessController.businessProfileDetails.value?.data;
            return WebsiteOverviewCard(
              websiteUrl: details?.websiteUrl,
              onSave: (url) => _businessController.updateBusinessProfileDetails(
                {ApiKeys.websiteUrl: url},
              ),
            );
          }),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: Obx(() {
            final details =
                _businessController.businessProfileDetails.value?.data;
            return BusinessContactMapCard(
              businessProfileDetails: details,
            );
          }),
        ),

        _buildQrCodeSection(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: const ProfileShareBanner(),
        ),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

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
}
