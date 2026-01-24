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

class RoomAmenitiesScreen extends StatefulWidget {
  @override
  State<RoomAmenitiesScreen> createState() => _RoomAmenitiesScreenState();
}

class _RoomAmenitiesScreenState extends State<RoomAmenitiesScreen> {
  final RoomAmenityController controller = Get.put(RoomAmenityController());
  final List<Map<String, dynamic>> roomAmenityList = [
    {
      "name": "Air Conditioning",
      "key": "AIR_CONDITIONING",
      "key_id": "airConditioning",
    },
    {
      "name": "Free Wi-Fi",
      "key": "WIFI",
      "key_id": "freeWifi",
    },
    {
      "name": "Television",
      "key": "TELEVISION",
      "key_id": "television",
    },
    {
      "name": "Room Service",
      "key": "ROOM_SERVICE",
      "key_id": "roomService",
    },
    {
      "name": "Power Backup",
      "key": "POWER_BACKUP",
      "key_id": "powerBackup",
    },
    {
      "name": "Balcony",
      "key": "BALCONY",
      "key_id": "balcony",
    },
    {
      "name": "Attached Bathroom",
      "key": "ATTACHED_BATHROOM",
      "key_id": "attachedBathroom",
    },
    {
      "name": "Wardrobe",
      "key": "WARDROBE",
      "key_id": "wardrobe",
    },
    {
      "name": "Desk / Chair",
      "key": "WORK_DESK",
      "key_id": "deskChair",
    },
    {
      "name": "Room Refrigerators",
      "key": "ROOM_REFRIGERATOR",
      "key_id": "roomRefrigerators",
    },
    {
      "name": "Electric kettle",
      "key": "ELECTRIC_KETTLE",
      "key_id": "electricKettle",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Room Amenities"),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: roomAmenityList.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final item = roomAmenityList[index];
                  final String key = item['key'];
                  final String key_id = item['key_id'];
                  final bool isEnabled =
                      controller.roomAmenityStatus[key_id] ?? false;
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
                              item['name'],
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

