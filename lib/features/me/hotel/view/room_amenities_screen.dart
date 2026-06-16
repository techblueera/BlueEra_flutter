import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/room_amenity_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Toggle list of per-room amenities (AC, Wi-Fi, TV, …). Toggles mutate
/// [RoomAmenityController.roomAmenityStatus] locally and the user commits
/// the snapshot via the bottom "Submit" button.
class RoomAmenitiesScreen extends StatelessWidget {
  RoomAmenitiesScreen({super.key, this.roomID});

  final String? roomID;
  final RoomAmenityController controller = Get.put(RoomAmenityController());

  /// Display name + SVG asset key + JSON payload key for each amenity row.
  static const List<_AmenityItem> _amenities = [
    _AmenityItem(
        name: AppStrings.hotelAirConditioning,
        assetKey: 'AIR_CONDITIONING',
        keyId: 'airConditioning'),
    _AmenityItem(
        name: AppStrings.hotelFreeWifi, assetKey: 'WIFI', keyId: 'freeWifi'),
    _AmenityItem(
        name: AppStrings.hotelTelevision,
        assetKey: 'TELEVISION',
        keyId: 'television'),
    _AmenityItem(
        name: AppStrings.hotelRoomServiceItem,
        assetKey: 'ROOM_SERVICE',
        keyId: 'roomService'),
    _AmenityItem(
        name: AppStrings.hotelPowerBackup,
        assetKey: 'POWER_BACKUP',
        keyId: 'powerBackup'),
    _AmenityItem(
        name: AppStrings.hotelBalcony, assetKey: 'BALCONY', keyId: 'balcony'),
    _AmenityItem(
        name: AppStrings.hotelAttachedBathroom,
        assetKey: 'ATTACHED_BATHROOM',
        keyId: 'attachedBathroom'),
    _AmenityItem(
        name: AppStrings.hotelWardrobe,
        assetKey: 'WARDROBE',
        keyId: 'wardrobe'),
    _AmenityItem(
        name: AppStrings.hotelDeskChair,
        assetKey: 'WORK_DESK',
        keyId: 'deskChair'),
    _AmenityItem(
        name: AppStrings.hotelRoomRefrigerators,
        assetKey: 'ROOM_REFRIGERATOR',
        keyId: 'roomRefrigerators'),
    _AmenityItem(
        name: AppStrings.hotelElectricKettle,
        assetKey: 'ELECTRIC_KETTLE',
        keyId: 'electricKettle'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.hotelRoomAmenities.tr),
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
            // Read the observable INSIDE the Obx so the Switch actually
            // subscribes to `roomAmenityStatus` — reading it outside left
            // the Obx with no observable, which threw "improper use of GetX".
            child: Obx(
              () => Switch(
                value: controller.roomAmenityStatus[item.keyId] ?? false,
                activeThumbColor: AppColors.primaryColor,
                onChanged: (v) => controller.updateAmenity(item.keyId, v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: PositiveCustomBtn(
        padding: EdgeInsets.zero,
        onTap: () async {
          await controller.submitAPI(roomID ?? "");
        },
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
