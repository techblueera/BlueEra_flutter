import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/room_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/room_listing_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoomSelectionScreen extends StatefulWidget {
  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  final controller = Get.put(RoomDetailController());

  final List<Map<String, dynamic>> roomDetailsList = [
    {"name": "Standard Room", "key_id": "standardRoom", "key": "STANDARD_ROOM"},
    {"name": "Economy Room", "key_id": "economyRoom", "key": "ECONOMY_ROOM"},
    {"name": "Deluxe Room", "key_id": "deluxeRoom", "key": "DELUXE_ROOM"},
    {
      "name": "Super Deluxe Room",
      "key_id": "superDeluxeRoom",
      "key": "SUPER_DELUXE_ROOM"
    },
    {"name": "Premium Room", "key_id": "premiumRoom", "key": "PREMIUM_ROOM"},
    {
      "name": "Executive Room",
      "key_id": "executiveRoom",
      "key": "EXECUTIVE_ROOM"
    },
    {"name": "Family Room", "key_id": "familyRoom", "key": "FAMILY_ROOM"},
    {"name": "Suite Room", "key_id": "suiteRoom", "key": "SUITE_ROOM"},
    {"name": "Luxury Suite", "key_id": "luxurySuite", "key": "LUXURY_SUITE"},
    {"name": "Studio Room", "key_id": "studioRoom", "key": "STUDIO_ROOM"},
    {
      "name": "Villa / Cottage (if applicable)",
      "key_id": "villaCottage",
      "key": "VILLA_COTTAGE"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Room Details",
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: roomDetailsList.length,
                  itemBuilder: (context, index) {
                    final item = roomDetailsList[index];
                    final String keyId = item['key_id'];
                    final String key = item['key'];

                    return CommonCardWidget(
                        borderColorColor: AppColors.whiteE5,
                        cardMargin: 7,
                        padding: 15,
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
                            InkWell(
                              onTap: () {
                                Get.to(RoomListingScreen(
                                  roomType: keyId,
                                  roomName: item['name'],
                                ));
                              },
                              child: CustomText(
                                "Add",
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                          ],
                        ));
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),

              // ),
              SizedBox(
                height: 30,
              )
              // Optional Submit button if you want to save manually
            ],
          );
        }),
      ),
    );
  }

  // Helper to place placeholder icons matching your design
}


