import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_amenity_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Toggle list of hotel-wide amenities (parking, restaurant, lift, …).
/// Each toggle mutates [HotelAmenityController.hotelAmenityStatus] locally;
/// the user commits the whole snapshot with the bottom "Submit" button.
class HotelAmenitiesScreen extends StatelessWidget {
  HotelAmenitiesScreen({super.key});

  final HotelAmenityController controller = Get.put(HotelAmenityController());

  /// Display name + payload key + asset key for each amenity row.
  static const List<_AmenityItem> _amenities = [
    _AmenityItem(
        name: AppStrings.hotelFreeParking,
        assetKey: 'FREE_PARKING',
        keyId: 'freeParking'),
    _AmenityItem(
        name: AppStrings.hotelRestaurant,
        assetKey: 'RESTAURANT',
        keyId: 'restaurant'),
    _AmenityItem(
        name: AppStrings.hotelFrontDesk247,
        assetKey: 'FRONT_DESK_24_7',
        keyId: 'frontDesk24x7'),
    _AmenityItem(
        name: AppStrings.hotelElevatorLift,
        assetKey: 'ELEVATOR_LIFT',
        keyId: 'elevatorLift'),
    _AmenityItem(
        name: AppStrings.hotelCctvSurveillance,
        assetKey: 'CCTV_SURVEILLANCE',
        keyId: 'cctvSurveillance'),
    _AmenityItem(
        name: AppStrings.hotelPowerBackup,
        assetKey: 'POWER_BACKUP',
        keyId: 'powerBackup'),
    _AmenityItem(
        name: AppStrings.hotelLaundryService,
        assetKey: 'WARDROBE',
        keyId: 'laundryService'),
    _AmenityItem(
        name: AppStrings.hotelSwimmingPool,
        assetKey: 'SWIMMING_POOL',
        keyId: 'swimmingPool'),
    _AmenityItem(
        name: AppStrings.hotelAirportTransportation,
        assetKey: 'AIRPORT_TRANSPORT',
        keyId: 'airportTransportation'),
    _AmenityItem(name: AppStrings.hotelBar, assetKey: 'BAR', keyId: 'bar'),
    _AmenityItem(
        name: AppStrings.hotelGym, assetKey: 'FITNESS_CENTER_GYM', keyId: 'gym'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.hotelAmenitiesTitle.tr),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(child: _buildAmenityList()),
            _buildSubmitButton(),
            const SizedBox(height: 30),
          ],
        );
      }),
    );
  }

  Widget _buildAmenityList() {
    return ListView.builder(
      itemCount: _amenities.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) => _buildAmenityRow(_amenities[index]),
    );
  }

  Widget _buildAmenityRow(_AmenityItem item) {
    return CommonCardWidget(
      borderColorColor: AppColors.whiteE5,
      cardMargin: 7,
      padding: 10,
      child: Row(
        children: [
          LocalAssets(
            imagePath: 'assets/category/hotel_service/${item.assetKey}.svg',
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CustomText(
              item.name.tr,
              color: AppColors.secondaryTextColor,
              fontSize: 18,
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Obx(
              () => Switch(
                value: controller.hotelAmenityStatus[item.keyId] ?? false,
                activeThumbColor: AppColors.primaryColor,
                onChanged: (v) => controller.updateAmenity(item.keyId, v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: PositiveCustomBtn(
        padding: EdgeInsets.zero,
        onTap: controller.submitAPI,
        title: AppStrings.submit,
      ),
    );
  }
}

/// Compile-time row spec: localized display name, SVG basename, payload key.
class _AmenityItem {
  final String name;
  final String assetKey;
  final String keyId;
  const _AmenityItem({
    required this.name,
    required this.assetKey,
    required this.keyId,
  });
}
