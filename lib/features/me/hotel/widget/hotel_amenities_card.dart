import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_amenities_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Hotel Amenities card — title + chip wrap of enabled amenities (or an
/// empty-state placeholder). Shared between the Amenities tab and the
/// Overview tab. Pencil edit affordance opens [HotelAmenitiesScreen] and
/// refreshes the controller's hotel data on return.
class HotelAmenitiesCard extends StatelessWidget {
  final HotelDetailController controller;

  const HotelAmenitiesCard({super.key, required this.controller});

  static const _hotelSpecs = <_AmenityChipSpec>[
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
        pick: _pickPowerBackup),
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final source = controller.hotelData.value?.profile?.hotelAmenities;
      final active = source == null
          ? const <_AmenityChipSpec>[]
          : _hotelSpecs.where((s) => s.pick(source) == true).toList();

      final onEdit = () => Get.to(HotelAmenitiesScreen())
          ?.then((_) => controller.loadHotelData());

      if (active.isEmpty) {
        return _SplitEmptyCard(
          message: "You Have Not Update Your \n Hotel Amenities",
          icon: Icons.spa_outlined,
          onTap: onEdit,
        );
      }

      return CommonCardWidget(
        padding: 12,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              title: "Hotel Amenities",
              onEdit: onEdit,
            ),
            SizedBox(height: SizeConfig.size12),
            Wrap(
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size8,
              children: active
                  .map((s) => _AmenityChip(label: s.label.tr, asset: s.asset))
                  .toList(growable: false),
            ),
          ],
        ),
      );
    });
  }

  static bool? _pickFreeParking(HotelAmenities a) => a.freeParking;
  static bool? _pickRestaurant(HotelAmenities a) => a.restaurant;
  static bool? _pickFrontDesk(HotelAmenities a) => a.frontDesk24x7;
  static bool? _pickElevator(HotelAmenities a) => a.elevatorLift;
  static bool? _pickCctv(HotelAmenities a) => a.cctvSurveillance;
  static bool? _pickPowerBackup(HotelAmenities a) => a.powerBackup;
  static bool? _pickLaundry(HotelAmenities a) => a.laundryService;
  static bool? _pickPool(HotelAmenities a) => a.swimmingPool;
  static bool? _pickAirport(HotelAmenities a) => a.airportTransportation;
  static bool? _pickBar(HotelAmenities a) => a.bar;
  static bool? _pickGym(HotelAmenities a) => a.gym;
}

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

class _AmenityChipSpec {
  final String label;
  final String asset;
  final bool? Function(HotelAmenities) pick;
  const _AmenityChipSpec({
    required this.label,
    required this.asset,
    required this.pick,
  });
}

class _SplitEmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback onTap;

  const _SplitEmptyCard({
    required this.message,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "Hotel Amenities",
            fontSize: 20,
            color: AppColors.black,
            fontWeight: FontWeight.w600,
            // textAlign: TextAlign.center,
            maxLines: 1,
          ),
          SizedBox(height: SizeConfig.size4),
          Divider(
            color: Color(0xffDDE2EE),
            height: 0.5,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size16,
            ),
            child: Center(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.emptyIcon,
                    height: 50,
                    width: 50,
                  ),
                  SizedBox(height: SizeConfig.size16),
                  CustomText(
                    message,
                    fontSize: 13,
                    color: AppColors.secondaryTextColor,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  SizedBox(height: SizeConfig.size16),
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size14,
                        vertical: SizeConfig.size8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          CustomText(
                            'Update Now',
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
            ),
          ),
        ],
      ),
    );
  }
}
