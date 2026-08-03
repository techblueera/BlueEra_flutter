import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_home_gallery_widget.dart';
import 'package:BlueEra/features/me/hotel/widget/hotel_booking_sheet.dart';
import 'package:BlueEra/features/me/hotel/widget/hotel_enquiry_sheet.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/visit_business_hero.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/widgets/custom_form_card.dart';
import '../../../../widgets/image_view_screen.dart';
import '../../../business/widgets/business_contact_map_card.dart';
import '../../../business/widgets/business_qrcode_widget.dart';
import '../../store/widget/store_live_photo_widget.dart';

class HotelDiscoverHomeScreen extends StatefulWidget {
  final HotelServiceData data;

  const HotelDiscoverHomeScreen({super.key, required this.data});

  @override
  State<HotelDiscoverHomeScreen> createState() =>
      _HotelDiscoverHomeScreenState();
}

class _HotelDiscoverHomeScreenState extends State<HotelDiscoverHomeScreen> {
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final storeController = getOrPut(() => StoreController());
  var selectedRoomType = "";

  String _formatTypeName(String type) {
    if (type.isEmpty) return "";
    String result = type.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
    return result[0].toUpperCase() + result.substring(1);
  }

  List<Rooms> get filteredRooms {
    return widget.data.rooms
            ?.where((room) => room.type == selectedRoomType)
            .toList() ??
        [];
  }

  List<String> get dynamicRoomTypes {
    final rooms = widget.data.rooms ?? [];
    return rooms
        .map((e) => e.type ?? "")
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> types = [];
  Profile? profile;

  @override
  void initState() {
    profile = widget.data.profile;
    types = dynamicRoomTypes;
    selectedRoomType = types.isNotEmpty ? types.first : '';
    super.initState();
    final id = profile?.businessId ?? '';
    if (id.isNotEmpty) {
      viewBusinessDetailsController.viewBusinessProfileById(id);
      ProfileClickTracker.track(
        userId: id,
        source: ChatClickSource.searchResult,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: profile?.businessId != userId
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.paddingS,
                  right: SizeConfig.paddingS,
                  bottom: 15,
                  top: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PositiveCustomBtn(
                        onTap: _openHotelEnquirySheet,
                        title: AppStrings.inquiry,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header (edge-to-edge hero includes overlay app-bar) ---
            Obx(() {
              viewBusinessDetailsController.profileVersion.value;
              final details = viewBusinessDetailsController
                  .visitedBusinessProfileDetails?.data;
              return VisitBusinessHero(
                details: details,
                onRated: () =>
                    viewBusinessDetailsController.viewBusinessProfileById(
                  profile?.businessId ?? '',
                  silent: true,
                ),
                onFollowChanged: () =>
                    viewBusinessDetailsController.viewBusinessProfileById(
                  profile?.businessId ?? '',
                  silent: true,
                ),
              );
            }),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Choose Room ---
                  _buildChooseRoom(),

                  // --- Amenities ---
                  SizedBox(height: SizeConfig.size10),
                  _buildAmenitiesSection(),

                  // --- Policies ---
                  SizedBox(height: SizeConfig.size10),
                  _buildPoliciesSection(),

                  // --- Gallery ---
                  SizedBox(height: SizeConfig.size10),
                  _buildGallerySection(),
                  // --- Live photo  ---
                  SizedBox(height: SizeConfig.size10),
                  Obx(() {
                    if (viewBusinessDetailsController.isProfileLoading.value) {
                      return const SizedBox.shrink();
                    }
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    final photos = (details?.livePhotos ?? const <String>[])
                        .where((p) => p.trim().isNotEmpty)
                        .toList();
                    if (photos.isEmpty) return const SizedBox.shrink();
                    return CustomFormCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomText(
                            'Live Photos',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: 10),
                          StoreLivePhotoWidget(
                            livePhotos: photos,
                            natureOfBusiness:
                                details?.subCategoryDetails?.name ??
                                    details?.natureOfBusiness ??
                                    'OTHER',
                            onViewFullScreen: ({
                              required int index,
                              required List<String> storeImage,
                              required String natureOfBusiness,
                            }) {
                              navigatePushTo(
                                context,
                                ImageViewScreen(
                                  appBarTitle: details?.businessName ?? '',
                                  subTitle: natureOfBusiness,
                                  imageUrls: storeImage,
                                  initialIndex: index,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  // --- Contact Us ---
                  // SizedBox(height: SizeConfig.size10),
                  Obx(() {
                    if (viewBusinessDetailsController.isProfileLoading.value) {
                      return const SizedBox.shrink();
                    }
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    return BusinessContactMapCard(
                      businessProfileDetails: details,
                      showEditButton: false,
                    );
                  }),

                  SizedBox(height: SizeConfig.size5),

                  /// WEBSITE PREVIEW
                  // `profile.website` from the search response is empty for
                  // most listings; the actual URL comes from the user-service
                  // detail payload as `data.website_url` → `websiteUrl` on the
                  // parsed profile. Fall back to `profile.website` only when
                  // the detail hasn't loaded yet.
                  //
                  // `visitedBusinessProfileDetails` is a plain field on the
                  // controller (not an `.obs`), so we touch `profileVersion`
                  // — the reactive version-counter bumped after each refresh
                  // — to give this Obx something to subscribe to. Same
                  // pattern used by the header Obx above.
                  Obx(() {
                    viewBusinessDetailsController.profileVersion.value;
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    final url = (details?.websiteUrl?.isNotEmpty ?? false)
                        ? details!.websiteUrl!
                        : (profile?.website ?? '');
                    return WebsitePreviewCard(url: url);
                  }),

                  Obx(() {
                    if (viewBusinessDetailsController.isProfileLoading.value) {
                      return const SizedBox.shrink();
                    }
                    final details = viewBusinessDetailsController
                        .visitedBusinessProfileDetails?.data;
                    return BusinessQrCodeWidget(data: details);
                  }),
                  SizedBox(height: kBottomNavigationBarHeight + 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CHOOSE ROOM ───────────────────────────────────────────────────

  Widget _buildChooseRoom() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.chooseRoom),
          const SizedBox(height: 12),
          if (types.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noRoomsAvailable.tr,
                imageSize: 60,
              ),
            )
          else ...[
            // Room type chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: types.map((type) {
                  bool isSelected = selectedRoomType == type;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRoomType = type),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.secondaryTextColor,
                        ),
                      ),
                      child: CustomText(
                        _formatTypeName(type),
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.normal,
                        fontSize: SizeConfig.medium,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Room cards
            SizedBox(
              height: 310,
              child: filteredRooms.isEmpty
                  ? const Center(child: CustomText(AppStrings.noRoomsAvailable))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        return _buildRoomCard(filteredRooms[index]);
                      },
                    ),
            ),
          ],
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Rooms room) {
    final imageUrl = room.images?.exteriorImages?.firstOrNull ?? '';
    return GestureDetector(
      onTap: () => _openRoomAmenitiesSheet(room),
      child: Container(
        width: 236,
        height: 303,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, _) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (ctx, _, __) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.hotel,
                              size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.hotel,
                            size: 50, color: Colors.grey),
                      ),
              ),
            ),

            // Bottom overlay
            Positioned(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10.0, right: 10, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          room.name ?? "N/A",
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          "\u20B9${room.pricePerDay ?? 0}/day",
                          color: Colors.white,
                          fontSize: 16,
                          maxLines: 1,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 5),
                        if (room.bedType?.isNotEmpty ?? false)
                          Row(
                            children: [
                              LocalAssets(
                                imagePath: AppIconAssets.bad,
                                imgColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              CustomText(
                                room.bedType ?? "",
                                color: Colors.white,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                fontSize: SizeConfig.small,
                              ),
                            ],
                          ),
                        if (room.maxOccupancy?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              LocalAssets(
                                imagePath: AppIconAssets.occupancy,
                                imgColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              CustomText(
                                room.maxOccupancy ?? "",
                                color: Colors.white,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                fontSize: SizeConfig.small,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ROOM AMENITIES SHEET ───────────────────────────────────────────

  /// Opens a bottom sheet listing the tapped room's amenities. Uses the
  /// per-room [Rooms.amenities] (freeWifi, AC, TV, etc.) — distinct from
  /// the hotel-level amenity list rendered in [_buildAmenitiesSection].
  void _openRoomAmenitiesSheet(Rooms room) {
    final amen = room.amenities;
    final chips = <_AmenityItem>[];
    // SVG basenames mirror the room-amenity specs used elsewhere in the
    // hotel me-tab (assets/category/hotel_service/<NAME>.svg).
    if (amen?.freeWifi == true) {
      chips.add(_AmenityItem('WIFI', AppStrings.amenityWifi.tr));
    }
    if (amen?.airConditioning == true) {
      chips.add(_AmenityItem('AIR_CONDITIONING', AppStrings.amenityAC.tr));
    }
    if (amen?.television == true) {
      chips.add(_AmenityItem('TELEVISION', AppStrings.amenityTV.tr));
    }
    if (amen?.roomService == true) {
      chips.add(_AmenityItem('ROOM_SERVICE', AppStrings.amenityRoomService.tr));
    }
    if (amen?.powerBackup == true) {
      chips.add(_AmenityItem('POWER_BACKUP', AppStrings.amenityPowerBackup.tr));
    }
    if (amen?.balcony == true) {
      chips.add(_AmenityItem('BALCONY', AppStrings.amenityBalcony.tr));
    }
    if (amen?.attachedBathroom == true) {
      chips.add(
          _AmenityItem('ATTACHED_BATHROOM', AppStrings.amenityBathroom.tr));
    }
    if (amen?.wardrobe == true) {
      chips.add(_AmenityItem('WARDROBE', AppStrings.amenityWardrobe.tr));
    }
    if (amen?.deskChair == true) {
      chips.add(_AmenityItem('WORK_DESK', AppStrings.amenityDeskChair.tr));
    }
    if (amen?.roomRefrigerators == true) {
      chips.add(
          _AmenityItem('ROOM_REFRIGERATOR', AppStrings.amenityRefrigerator.tr));
    }
    if (amen?.electricKettle == true) {
      chips.add(
          _AmenityItem('ELECTRIC_KETTLE', AppStrings.amenityElectricKettle.tr));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: SizeConfig.size12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            CustomText(
              (room.name?.isNotEmpty ?? false) ? room.name! : 'Room',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              AppStrings.hotelRoomAmenities.tr,
              fontSize: 13,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size16),
            if (chips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: EmptyStateWidget(
                  message: AppStrings.noAmenitiesListed.tr,
                  imageSize: 60,
                ),
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children:
                    chips.map((a) => _amenityChip(a.asset, a.label)).toList(),
              ),
            SizedBox(height: SizeConfig.size16),
          ],
        ),
      ),
    );
  }

  // ─── GALLERY ────────────────────────────────────────────────────────

  Widget _buildGallerySection() {
    final allImages = profile?.photos
            ?.expand((p) => p.imageReferences ?? <String>[])
            .toList() ??
        [];

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.gallery),
          const SizedBox(height: 12),
          if (allImages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noPhotosAvailableMsg.tr,
                imageSize: 60,
              ),
            )
          else
            HotelHomeGalleryWidget(photos: profile?.photos),
        ],
      ),
    );
  }

  // ─── AMENITIES ──────────────────────────────────────────────────────

  Widget _buildAmenitiesSection() {
    // Backend puts *hotel*-level amenities on `profile.amenities`
    // (freeParking, restaurant, front-desk, etc.) and *room*-level
    // amenities on each `Rooms.amenities` (freeWifi, AC, TV, etc.).
    // Checking the wrong field set here is why the hotel amenities chips
    // used to render empty.
    final amen = profile?.amenities;
    final chips = <_AmenityItem>[];
    // SVG basenames mirror those used by `HotelAmenitiesCard._hotelSpecs`
    // (assets/category/hotel_service/<NAME>.svg) so the icons on the
    // discover screen stay in sync with the me-tab amenities card.
    if (amen?.freeParking == true) {
      chips.add(_AmenityItem('FREE_PARKING', AppStrings.hotelFreeParking.tr));
    }
    if (amen?.restaurant == true) {
      chips.add(_AmenityItem('RESTAURANT', AppStrings.hotelRestaurant.tr));
    }
    if (amen?.frontDesk24x7 == true) {
      chips.add(
          _AmenityItem('FRONT_DESK_24_7', AppStrings.hotelFrontDesk247.tr));
    }
    if (amen?.elevatorLift == true) {
      chips.add(_AmenityItem('ELEVATOR_LIFT', AppStrings.hotelElevatorLift.tr));
    }
    if (amen?.cctvSurveillance == true) {
      chips.add(_AmenityItem(
          'CCTV_SURVEILLANCE', AppStrings.hotelCctvSurveillance.tr));
    }
    if (amen?.powerBackup == true) {
      chips.add(_AmenityItem('POWER_BACKUP', AppStrings.hotelPowerBackup.tr));
    }
    if (amen?.laundryService == true) {
      chips.add(_AmenityItem('WARDROBE', AppStrings.hotelLaundryService.tr));
    }
    if (amen?.swimmingPool == true) {
      chips.add(_AmenityItem('SWIMMING_POOL', AppStrings.hotelSwimmingPool.tr));
    }
    if (amen?.airportTransportation == true) {
      chips.add(_AmenityItem(
          'AIRPORT_TRANSPORT', AppStrings.hotelAirportTransportation.tr));
    }
    if (amen?.bar == true) {
      chips.add(_AmenityItem('BAR', AppStrings.hotelBar.tr));
    }
    if (amen?.gym == true) {
      chips.add(_AmenityItem('FITNESS_CENTER_GYM', AppStrings.hotelGym.tr));
    }

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.hotelAmenities),
          SizedBox(height: SizeConfig.size6),
          if (chips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noAmenitiesListed.tr,
                imageSize: 60,
              ),
            )
          else
            // Fixed 4-per-row grid — each tile takes an equal fourth of
            // the card width. `childAspectRatio: 1.25` makes cells wider
            // than tall so the icon-well + one-line label fully consume
            // the cell height, killing the top/bottom whitespace that a
            // near-square cell was leaving around the `MainAxisSize.min`
            // chip. Explicit `padding: EdgeInsets.zero` also stops the
            // GridView from adopting any inherited MediaQuery padding.
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisCount: 4,
              mainAxisSpacing: SizeConfig.size6,
              crossAxisSpacing: SizeConfig.size6,
              childAspectRatio: 1.05,
              children: chips
                  .map((a) => _amenityChip(a.asset, a.label))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  // ─── POLICIES ───────────────────────────────────────────────────────

  /// Flattens `profile.policy` into localized chip labels — check-in /
  /// check-out times, plus every boolean flag the hotel enabled. Empty
  /// list means nothing worth showing yet, and the section renders the
  /// shared empty state.
  List<String> _policyItems() {
    final p = profile?.policy;
    if (p == null) return const <String>[];
    final items = <String>[];
    if (p.checkInTime != null) {
      items.add('${AppStrings.hotelCheckInLabel.tr} ${p.checkInTime}');
    }
    if (p.checkOutTime != null) {
      items.add('${AppStrings.hotelCheckOutLabel.tr} ${p.checkOutTime}');
    }
    if (p.earlyCheckInAllowed == true) {
      items.add(AppStrings.hotelEarlyCheckInAllowed.tr);
    }
    if (p.lateCheckOutAllowed == true) {
      items.add(AppStrings.hotelLateCheckOutAllowed.tr);
    }
    if (p.freeCancellation == true) {
      items.add(AppStrings.hotelFreeCancellation.tr);
    }
    if (p.localIdAllowed == true) {
      items.add(AppStrings.hotelLocalIdAccepted.tr);
    }
    if (p.marriedCoupleAllowed == true) {
      items.add(AppStrings.hotelMarriedCouplesAllowed.tr);
    }
    if (p.bachelorStudentAllowed == true) {
      items.add(AppStrings.hotelBachelorsStudentsAllowed.tr);
    }
    if (p.aadharMandatory == true) {
      items.add(AppStrings.hotelAadharMandatoryChip.tr);
    }
    if (p.smokingDrinkingAllowed == true) {
      items.add(AppStrings.hotelSmokingDrinkingAllowedChip.tr);
    }
    if (p.foodRestrictions?.enabled == true) {
      items.add(AppStrings.hotelFoodRestrictionsLabel.tr);
    }
    return items;
  }

  Widget _buildPoliciesSection() {
    final items = _policyItems();
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.hotelPoliciesTitle),
          SizedBox(height: SizeConfig.size12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.hotelNoPoliciesAdded.tr,
                imageSize: 60,
              ),
            )
          else
            Wrap(
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size8,
              children: items
                  .map((item) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                            vertical: SizeConfig.size6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xffDDE2EE), width: 0.5),
                        ),
                        child: CustomText(item,
                            fontSize: 12, color: AppColors.grey7E),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _amenityChip(String asset, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: LocalAssets(
            imagePath: 'assets/category/hotel_service/$asset.svg',
            height: 22,
            width: 22,
            imgColor: AppColors.grey7E,
          ),
        ),
        const SizedBox(height: 4),
        CustomText(label, fontSize: 11, textAlign: TextAlign.center),
      ],
    );
  }

  // ─── CONTACT US (clickable) ─────────────────────────────────────────

  Widget _buildContactCard() {
    final contact = profile?.contacts?.firstOrNull;
    final hasContact = (contact?.email?.isNotEmpty ?? false) ||
        (contact?.phone?.isNotEmpty ?? false) ||
        (profile?.website?.isNotEmpty ?? false) ||
        (profile?.location?.name?.isNotEmpty ?? false);

    final firstImageUrl = profile?.photos
        ?.expand((p) => p.imageReferences ?? <String>[])
        .firstOrNull;

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.contactUs),
          const SizedBox(height: 12),
          if (!hasContact && (profile?.name?.isEmpty ?? true))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noContactDetailsMsg.tr,
                imageSize: 60,
              ),
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
                  // Logo & Name
                  Row(
                    children: [
                      if (firstImageUrl?.isNotEmpty ?? false)
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: firstImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, _) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                              errorWidget: (ctx, _, __) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: CustomText(
                          profile?.name ?? '',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (profile?.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    ExpandableText(text: profile?.description ?? ""),
                  ],
                  const Divider(height: 20),

                  // Clickable contact items
                  if (profile?.website?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.website_click,
                      label: profile?.website ?? "",
                      iconColor: AppColors.primaryColor,
                      onTap: () => _launchUrl(profile?.website ?? ""),
                    ),
                  if (contact?.email?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.email,
                      label: contact?.email ?? "",
                      iconColor: AppColors.secondaryTextColor,
                      onTap: () => _launchEmail(contact?.email ?? ""),
                    ),
                  if (contact?.phone?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.phone_outline,
                      label: contact?.phone ?? "",
                      iconColor: AppColors.secondaryTextColor,
                      onTap: () => _launchCaller(contact?.phone ?? ""),
                    ),
                  if (profile?.location?.name?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.location_new,
                      label: profile?.location?.name ?? "",
                      iconColor: Colors.grey[700]!,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactItemClickable({
    required String icon,
    required String label,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              LocalAssets(
                imagePath: icon,
                imgColor: iconColor,
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  label,
                  color: onTap != null
                      ? AppColors.primaryColor
                      : AppColors.mainTextColor,
                  fontSize: SizeConfig.medium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LOCATION ───────────────────────────────────────────────────────

  Widget _buildLocationSection() {
    final coords = profile?.location?.coordinates;
    if (coords == null ||
        coords.length < 2 ||
        (coords[0] == 0.0 && coords[1] == 0.0)) {
      return const SizedBox.shrink();
    }

    return BusinessLocationWidget(
      locationText: profile?.location?.name,
      latitude: coords[1].toDouble(),
      longitude: coords[0].toDouble(),
      businessName: profile?.name ?? "",
      padding: 0,
      isTitleShow: true,
    );
  }

  // ─── LAUNCHERS ──────────────────────────────────────────────────────

  /// Opens the hotel-enquiry sheet for the currently-viewed listing. Pulls
  /// the hotel id, owner id and snapshot fields from [profile] so the
  /// sheet header — and the eventual in-chat card — renders without an
  /// extra fetch.
  ///
  /// Before opening we register the hotel's actual Rooms with
  /// [HotelBookingSheet.cacheRoomsForHotel] so the enquiry-first flow
  /// (customer taps "Book Now" on the accepted chat card) can render a
  /// real room picker instead of the free-text fallback. The cache is
  /// keyed by hotelId and lives only for this session — losing it on
  /// restart is fine, the sheet gracefully falls back to text chips.
  void _openHotelEnquirySheet() {
    // `profile.sId` is the hotel-profile's own `_id` (the hotel listing
    // the customer is enquiring about); `profile.businessId` is the
    // owner-business id used as the chat counterpart, matching the
    // existing chat handoff above.
    final hotelId = (profile?.sId ?? widget.data.businessId ?? '').trim();
    final ownerId = (profile?.businessId ?? '').trim();
    if (hotelId.isEmpty || ownerId.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }
    HotelBookingSheet.cacheRoomsForHotel(hotelId, _roomsForBooking());
    HotelEnquirySheet.open(
      context,
      listing: HotelEnquiryListing(
        hotelId: hotelId,
        ownerId: ownerId,
        ownerName: (profile?.name ?? '').trim(),
        hotelName: (profile?.name ?? '').trim(),
        coverImage: profile?.coverUrl,
        location: profile?.location?.name,
      ),
    );
  }

  /// Projection of `widget.data.rooms` onto the sheet's room-option
  /// shape. Drops inactive rooms and rooms missing an id (nothing the
  /// server would accept as a `room_id`). Uses the first exterior image
  /// as the thumbnail — same convention as `_buildRoomCard`.
  List<HotelBookingRoomOption> _roomsForBooking() {
    final rooms = widget.data.rooms ?? const <Rooms>[];
    final out = <HotelBookingRoomOption>[];
    for (final r in rooms) {
      final id = (r.sId ?? '').trim();
      if (id.isEmpty) continue;
      if (r.isActive == false) continue;
      out.add(HotelBookingRoomOption(
        id: id,
        name: (r.name ?? '').trim(),
        type: (r.type ?? '').trim(),
        image: r.images?.exteriorImages?.firstOrNull,
        pricePerDay: r.pricePerDay,
        bedType: r.bedType,
        maxOccupancy: r.maxOccupancy,
      ));
    }
    return out;
  }

  void _launchCaller(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenDialer.tr);
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }

  void _launchEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenEmail.tr);
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  void _launchUrl(String url) async {
    try {
      String finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'https://$url';
      }
      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenLink.tr);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }
}

class _AmenityItem {
  final String asset;
  final String label;
  _AmenityItem(this.asset, this.label);
}
