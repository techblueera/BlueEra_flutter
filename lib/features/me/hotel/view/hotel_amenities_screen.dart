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


class HotelAmenitiesScreen extends StatefulWidget {
  @override
  State<HotelAmenitiesScreen> createState() => _HotelAmenitiesScreenState();
}

class _HotelAmenitiesScreenState extends State<HotelAmenitiesScreen> {
  final HotelAmenityController controller = Get.put(HotelAmenityController());
  final List<Map<String, dynamic>> hotelAmenityList = [
    {
      "name": AppStrings.hotelFreeParking,
      "key": "FREE_PARKING",
      "key_id": "freeParking",
    },
    {
      "name": AppStrings.hotelRestaurant,
      "key": "RESTAURANT",
      "key_id": "restaurant",
    },
    {
      "name": AppStrings.hotelFrontDesk247,
      "key": "FRONT_DESK_24_7",
      "key_id": "frontDesk24x7",
    },
    {
      "name": AppStrings.hotelElevatorLift,
      "key": "ELEVATOR_LIFT",
      "key_id": "elevatorLift",
    },
    {
      "name": AppStrings.hotelCctvSurveillance,
      "key": "CCTV_SURVEILLANCE",
      "key_id": "cctvSurveillance",
    },
    {
      "name": AppStrings.hotelPowerBackup,
      "key": "POWER_BACKUP",
      "key_id": "powerBackup",
    },
    {
      "name": AppStrings.hotelLaundryService,
      "key": "WARDROBE",
      "key_id": "laundryService",
    },
    {
      "name": AppStrings.hotelSwimmingPool,
      "key": "SWIMMING_POOL",
      "key_id": "swimmingPool",
    },
    {
      "name": AppStrings.hotelAirportTransportation,
      "key": "AIRPORT_TRANSPORT",
      "key_id": "airportTransportation",
    },
    {
      "name": AppStrings.hotelBar,
      "key": "BAR",
      "key_id": "bar",
    },
    {
      "name": AppStrings.hotelGym,
      "key": "FITNESS_CENTER_GYM",
      "key_id": "gym",
    },
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
            Expanded(
              child: ListView.builder(
                itemCount: hotelAmenityList.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final item = hotelAmenityList[index];
                  final String key = item['key'];
                  final String key_id = item['key_id'];
                  final bool isEnabled =
                      controller.hotelAmenityStatus[key_id] ?? false;
                  return CommonCardWidget(
                      borderColorColor: AppColors.whiteE5,
                      cardMargin: 7,
                      padding: 10,
                      child: Row(
                        children: [
                          LocalAssets(
                              imagePath:
                              "assets/category/hotel_service/${key}.svg"),
                          SizedBox(
                            width: SizeConfig.size10,
                          ),
                          Expanded(
                            child: CustomText(
                              (item['name'] as String).tr,
                              color: AppColors.secondaryTextColor,
                              fontSize: 18,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                                value: isEnabled,
                                activeColor: AppColors.primaryColor,
                                onChanged: (bool newValue) {
                                  controller.updateAmenity(key_id, newValue);
                                  setState(() {});
                                }),
                          ),
                        ],
                      ));
                },
              ),
            ),
            // Submit Button Section
            Padding(
              padding:
              EdgeInsets.only(bottom: 20.0, right: 20, left: 20, top: 20),
              child: PositiveCustomBtn(
                  padding: EdgeInsets.zero,
                  onTap: () {
                    controller.submitAPI();
                  },
                  title: AppStrings.submit),
            ),
            SizedBox(
              height: 30,
            )
          ],
        );
      }),
    );
  }
}

