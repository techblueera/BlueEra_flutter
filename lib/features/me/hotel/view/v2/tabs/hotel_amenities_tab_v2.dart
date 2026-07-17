import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icon_assets.dart';

/// Amenities + Policies tab — chip-based Hotel Amenities + Room Amenities
/// cards mirror the mockup design (title with edit pencil, pill chips with
/// SVG icons). Room amenities aggregate across every room in
/// `profile.rooms`: a chip appears if ANY room has that amenity enabled.
/// Policies retains its inline pill list below.
class HotelAmenitiesTabV2 extends StatelessWidget {
  final HotelDetailController controller;

  const HotelAmenitiesTabV2({super.key, required this.controller});

  // ── Amenity chip specs (label + SVG basename + boolean picker). Static so
  // there's a single source of truth for both the current tab UI and the
  // corresponding edit screens.

  static const _hotelSpecs = <_AmenityChipSpec<HotelAmenities>>[
    _AmenityChipSpec(
        label: AppStrings.hotelFreeParking,
        asset: 'FREE_PARKING',
        pick: _pickFreeParking),
    _AmenityChipSpec(
        label: AppStrings.hotelRestaurant,
        asset: 'RESTAURANT',
        pick: _pickRestaurant),
    _AmenityChipSpec(
        label: AppStrings.hotelFrontDesk247,
        asset: 'FRONT_DESK_24_7',
        pick: _pickFrontDesk),
    _AmenityChipSpec(
        label: AppStrings.hotelElevatorLift,
        asset: 'ELEVATOR_LIFT',
        pick: _pickElevator),
    _AmenityChipSpec(
        label: AppStrings.hotelCctvSurveillance,
        asset: 'CCTV_SURVEILLANCE',
        pick: _pickCctv),
    _AmenityChipSpec(
        label: AppStrings.hotelPowerBackup,
        asset: 'POWER_BACKUP',
        pick: _pickHotelPowerBackup),
    _AmenityChipSpec(
        label: AppStrings.hotelLaundryService,
        asset: 'WARDROBE',
        pick: _pickLaundry),
    _AmenityChipSpec(
        label: AppStrings.hotelSwimmingPool,
        asset: 'SWIMMING_POOL',
        pick: _pickPool),
    _AmenityChipSpec(
        label: AppStrings.hotelAirportTransportation,
        asset: 'AIRPORT_TRANSPORT',
        pick: _pickAirport),
    _AmenityChipSpec(label: AppStrings.hotelBar, asset: 'BAR', pick: _pickBar),
    _AmenityChipSpec(
        label: AppStrings.hotelGym,
        asset: 'FITNESS_CENTER_GYM',
        pick: _pickGym),
  ];

  static const _roomSpecs = <_AmenityChipSpec<Amenities>>[
    _AmenityChipSpec(
        label: AppStrings.hotelAirConditioning,
        asset: 'AIR_CONDITIONING',
        pick: _pickAc),
    _AmenityChipSpec(
        label: AppStrings.hotelFreeWifi, asset: 'WIFI', pick: _pickWifi),
    _AmenityChipSpec(
        label: AppStrings.hotelTelevision, asset: 'TELEVISION', pick: _pickTv),
    _AmenityChipSpec(
        label: AppStrings.hotelRoomServiceItem,
        asset: 'ROOM_SERVICE',
        pick: _pickRoomService),
    _AmenityChipSpec(
        label: AppStrings.hotelPowerBackup,
        asset: 'POWER_BACKUP',
        pick: _pickRoomPowerBackup),
    _AmenityChipSpec(
        label: AppStrings.hotelBalcony, asset: 'BALCONY', pick: _pickBalcony),
    _AmenityChipSpec(
        label: AppStrings.hotelAttachedBathroom,
        asset: 'ATTACHED_BATHROOM',
        pick: _pickAttachedBath),
    _AmenityChipSpec(
        label: AppStrings.hotelWardrobe,
        asset: 'WARDROBE',
        pick: _pickWardrobe),
    _AmenityChipSpec(
        label: AppStrings.hotelDeskChair, asset: 'WORK_DESK', pick: _pickDesk),
    _AmenityChipSpec(
        label: AppStrings.hotelRoomRefrigerators,
        asset: 'ROOM_REFRIGERATOR',
        pick: _pickFridge),
    _AmenityChipSpec(
        label: AppStrings.hotelElectricKettle,
        asset: 'ELECTRIC_KETTLE',
        pick: _pickKettle),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.hotelData.value?.profile;
      final rooms = controller.hotelData.value?.rooms ?? const <Rooms>[];

      final activeHotel = _activeSpecs(_hotelSpecs, profile?.hotelAmenities);
      final activeRoom = _activeRoomSpecs(rooms);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),

          // ── Hotel Amenities ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: _AmenityCard(
              title: AppStrings.hotelAmenitiesTitle.tr,
              activeChips: activeHotel,
              emptyLabel: AppStrings.hotelNoAmenitiesAdded.tr,
              emptyIcon: Icons.spa_outlined,
              onEdit: () => Get.to(HotelAmenitiesScreen())
                  ?.then((_) => controller.loadHotelData()),
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          // ── Room Amenities (aggregated across all rooms) ──
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          //   child: _AmenityCard(
          //     title: AppStrings.hotelRoomAmenities.tr,
          //     activeChips: activeRoom,
          //     emptyLabel: AppStrings.hotelNoAmenitiesAdded.tr,
          //     emptyIcon: Icons.king_bed_outlined,
          //     onEdit: () => Get.to(RoomAmenitiesScreen(
          //       roomID: rooms.isNotEmpty ? rooms.first.id : null,
          //     ))?.then((_) => controller.loadHotelData()),
          //   ),
          // ),

          SizedBox(height: SizeConfig.size10),

          // ── Policies ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: CommonCardWidget(
              padding: 12,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    title: AppStrings.hotelPoliciesTitle.tr,
                    onEdit: () => Get.to(HotelPoliciesScreen())
                        ?.then((_) => controller.loadHotelData()),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  if (profile?.policy != null)
                    _PolicySummary(policy: profile!.policy!)
                  else
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_gallery.png',
                      ctaLabel: AppStrings.hotelNoPoliciesAdded.tr,
                      ctaIcon: Icons.policy_outlined,
                      onTap: () => Get.to(HotelPoliciesScreen())
                          ?.then((_) => controller.loadHotelData()),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }

  // Returns the subset of specs whose picker resolves to true on [source].
  List<_AmenityChipSpec<T>> _activeSpecs<T>(
    List<_AmenityChipSpec<T>> specs,
    T? source,
  ) {
    if (source == null) return const [];
    return specs.where((s) => s.pick(source) == true).toList(growable: false);
  }

  // Aggregates room amenities across every room — an amenity chip appears
  // if ANY room has it enabled. Keeps the tab useful even when a property
  // has multiple room types with slightly different amenity sets.
  List<_AmenityChipSpec<Amenities>> _activeRoomSpecs(List<Rooms> rooms) {
    if (rooms.isEmpty) return const [];
    return _roomSpecs.where((spec) {
      return rooms.any((r) {
        final a = r.amenities;
        return a != null && spec.pick(a) == true;
      });
    }).toList(growable: false);
  }

  // ── Static pickers — kept out of Amenities/HotelAmenities so the models
  // stay untouched. Tear-off references let the const spec lists stay const.
  static bool? _pickFreeParking(HotelAmenities a) => a.freeParking;
  static bool? _pickRestaurant(HotelAmenities a) => a.restaurant;
  static bool? _pickFrontDesk(HotelAmenities a) => a.frontDesk24x7;
  static bool? _pickElevator(HotelAmenities a) => a.elevatorLift;
  static bool? _pickCctv(HotelAmenities a) => a.cctvSurveillance;
  static bool? _pickHotelPowerBackup(HotelAmenities a) => a.powerBackup;
  static bool? _pickLaundry(HotelAmenities a) => a.laundryService;
  static bool? _pickPool(HotelAmenities a) => a.swimmingPool;
  static bool? _pickAirport(HotelAmenities a) => a.airportTransportation;
  static bool? _pickBar(HotelAmenities a) => a.bar;
  static bool? _pickGym(HotelAmenities a) => a.gym;

  static bool? _pickAc(Amenities a) => a.airConditioning;
  static bool? _pickWifi(Amenities a) => a.freeWifi;
  static bool? _pickTv(Amenities a) => a.television;
  static bool? _pickRoomService(Amenities a) => a.roomService;
  static bool? _pickRoomPowerBackup(Amenities a) => a.powerBackup;
  static bool? _pickBalcony(Amenities a) => a.balcony;
  static bool? _pickAttachedBath(Amenities a) => a.attachedBathroom;
  static bool? _pickWardrobe(Amenities a) => a.wardrobe;
  static bool? _pickDesk(Amenities a) => a.deskChair;
  static bool? _pickFridge(Amenities a) => a.roomRefrigerators;
  static bool? _pickKettle(Amenities a) => a.electricKettle;
}

/// Reusable amenity card: header + wrap of pill chips (or an empty state).
class _AmenityCard<T> extends StatelessWidget {
  final String title;
  final List<_AmenityChipSpec<T>> activeChips;
  final String emptyLabel;
  final IconData emptyIcon;
  final VoidCallback onEdit;

  const _AmenityCard({
    required this.title,
    required this.activeChips,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      padding: 12,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title, onEdit: onEdit),
          SizedBox(height: SizeConfig.size12),
          if (activeChips.isEmpty)
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: emptyLabel,
              ctaIcon: emptyIcon,
              onTap: onEdit,
            )
          else
            Wrap(
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size8,
              children: activeChips
                  .map((s) => _AmenityChip(label: s.label.tr, asset: s.asset))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

/// Rounded pill chip — subtle grey border, icon + label, used in every
/// amenity card.
class _AmenityChip extends StatelessWidget {
  final String label;
  final String asset;

  const _AmenityChip({required this.label, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xffDDE2EE), width: 0.5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
            imagePath: 'assets/category/hotel_service/$asset.svg',
            height: 18,
            width: 18,
            imgColor: AppColors.grey7E,
          ),
          SizedBox(width: SizeConfig.size8),
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.grey7E,
          ),
        ],
      ),
    );
  }
}

/// Card title + minimalist pencil-outline edit affordance (matches mockup).
class _CardHeader extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;

  const _CardHeader({required this.title, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CustomText(
            title,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.black22,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
    );
  }
}

class _PolicySummary extends StatelessWidget {
  final Policy policy;
  const _PolicySummary({required this.policy});

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    if (policy.checkInTime != null) {
      items.add('${AppStrings.hotelCheckInLabel.tr} ${policy.checkInTime}');
    }
    if (policy.checkOutTime != null) {
      items.add('${AppStrings.hotelCheckOutLabel.tr} ${policy.checkOutTime}');
    }
    if (policy.earlyCheckInAllowed == true) {
      items.add(AppStrings.hotelEarlyCheckInAllowed.tr);
    }
    if (policy.lateCheckOutAllowed == true) {
      items.add(AppStrings.hotelLateCheckOutAllowed.tr);
    }
    if (policy.freeCancellation == true) {
      items.add(AppStrings.hotelFreeCancellation.tr);
    }
    if (policy.localIdAllowed == true) {
      items.add(AppStrings.hotelLocalIdAccepted.tr);
    }
    if (policy.marriedCoupleAllowed == true) {
      items.add(AppStrings.hotelMarriedCouplesAllowed.tr);
    }
    if (policy.bachelorStudentAllowed == true) {
      items.add(AppStrings.hotelBachelorsStudentsAllowed.tr);
    }
    if (policy.aadharMandatory == true) {
      items.add(AppStrings.hotelAadharMandatoryChip.tr);
    }
    if (policy.smokingDrinkingAllowed == true) {
      items.add(AppStrings.hotelSmokingDrinkingAllowedChip.tr);
    }
    if (policy.foodRestrictions?.enabled == true &&
        (policy.foodRestrictions?.restrictions?.isNotEmpty ?? false)) {
      items.add(
          '${AppStrings.hotelFoodRestrictionsLabel.tr}: ${policy.foodRestrictions!.restrictions!.join(', ')}');
    }

    if (items.isEmpty) {
      return EmptySectionPlaceholder(
        imageAsset: 'assets/images/other_gallery.png',
        ctaLabel: AppStrings.hotelNoPoliciesAdded.tr,
        ctaIcon: Icons.policy_outlined,
        onTap: () => Get.to(HotelPoliciesScreen()),
      );
    }

    return Wrap(
      spacing: SizeConfig.size8,
      runSpacing: SizeConfig.size8,
      children: items
          .map((item) => Container(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xffDDE2EE), width: 0.5),
                ),
                child: CustomText(item, fontSize: 12, color: AppColors.grey7E),
              ))
          .toList(),
    );
  }
}

/// Compile-time chip spec: localized label, SVG basename, and a picker that
/// pulls the boolean off a source model (`HotelAmenities` or `Amenities`).
class _AmenityChipSpec<T> {
  final String label;
  final String asset;
  final bool? Function(T) pick;
  const _AmenityChipSpec({
    required this.label,
    required this.asset,
    required this.pick,
  });
}
