import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_joined_profile_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_photos_screen.dart';
import 'package:BlueEra/features/me/hotel/view/v2/widgets/hotel_availability_view.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hotel/widget/hotel_amenities_card.dart';
import 'package:BlueEra/features/me/hotel/widget/hotel_choose_room_card.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Hotel overview body — mirrors the product/inventory v2 home
/// screen's overview structure: shared joined-date + identity + cover card,
/// then live photos, description, contact-map card, website, QR code and
/// share banner. Padded content-only; the parent's SingleChildScrollView
/// owns the scroll.
class HotelOverviewTabV2 extends StatefulWidget {
  final HotelDetailController controller;

  const HotelOverviewTabV2({super.key, required this.controller});

  @override
  State<HotelOverviewTabV2> createState() => _HotelOverviewTabV2State();
}

class _HotelOverviewTabV2State extends State<HotelOverviewTabV2> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.size20,
          ),
          child: BusinessJoinedProfileCard(
              businessController: _businessController),
        ),
        SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size30, right: SizeConfig.size12),
          child: HotelChooseRoomCard(controller: widget.controller),
        ),
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size30, right: SizeConfig.size12),
          child: HotelAmenitiesCard(controller: widget.controller),
        ),
        SizedBox(height: SizeConfig.size10),
        // Weekly hours — mirrors the lab overview tab. Reads from the shared
        // business availability endpoint via `_businessController.weeklySchedule`
        // and opens `HotelAvailabilityScreen` for edits.
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size30, right: SizeConfig.size12),
          child: HotelAvailabilityCard(businessController: _businessController),
        ),
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size30, right: SizeConfig.size12),
          child: CommonBusinessLivePhoto(
            controller: _businessController,
          ),
        ),
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size30, right: SizeConfig.size12),
          child: Obx(() {
            final photos = widget.controller.hotelData.value?.profile?.photos;
            final hasPhotos =
                photos?.any((p) => (p.imageReferences?.isNotEmpty ?? false)) ??
                    false;
            final onEdit = () => Get.to(PropertyPhotoScreen())
                ?.then((_) => widget.controller.loadHotelData());
            return CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.hotelGallery.tr,
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.medium,
                      ),
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: EdgeInsets.all(SizeConfig.size4),
                          child: LocalAssets(
                            imagePath: AppIconAssets.editIcon,
                            imgColor: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  if (hasPhotos)
                    HotelHomeGalleryWidget(photos: photos)
                  else
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_gallery.png',
                      ctaLabel: AppStrings.addPhotos.tr,
                      ctaIcon: Icons.add_photo_alternate_outlined,
                      onTap: onEdit,
                    ),
                ],
              ),
            );
          }),
        ),
        // Padding(
        //   padding: EdgeInsets.only(
        //       left: SizeConfig.size30, right: SizeConfig.size12),
        //   child: const BusinessDescriptionCard(),
        // ),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size30, right: SizeConfig.size12),
          child: Obx(() {
            final details =
                _businessController.businessProfileDetails.value?.data;
            return BusinessContactMapCard(
              businessProfileDetails: details,
            );
          }),
        ),
        // SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size30, right: SizeConfig.size12),
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
        _buildQrCodeSection(),
        Padding(
          padding: EdgeInsets.only(
              left: SizeConfig.size30, right: SizeConfig.size12),
          child: const ProfileShareBanner(),
        ),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  Widget _buildQrCodeSection() {
    return Obx(() {
      final details = _businessController.businessProfileDetails.value?.data;
      if (details == null) return const SizedBox.shrink();
      return Padding(
        padding:
            EdgeInsets.only(left: SizeConfig.size30, right: SizeConfig.size12),
        child: BusinessQrCodeWidget(data: details),
      );
    });
  }
}
