import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../category/hotel_amenities_page.dart';
import '../category/hotel_policies_page.dart';
import '../category/hotel_room_amenities_page.dart';
import '../category/room_details/hotel_room_details_page.dart';
class AddHotelService extends StatefulWidget {
  const AddHotelService({super.key});

  @override
  State<AddHotelService> createState() => _AddHotelServiceState();
}
class _AddHotelServiceState extends State<AddHotelService> {

  final Map<String, Widget Function()> servicePages = {
    "About Property": () => Container(),
    "Room Details": () => HotelRoomDetailsMain(),
    "Room Amenities": () => HotelRoomAmenitiesPage(),
    "Hotel Amenities": () => HotelAmenitiesPage(),
    "Hotel Policies": () => HotelPoliciesPage(),
    "Restaurant Menu": () => Container(),
    "Property Photos": () => Container(),
    "Update Price": () => Container(),
    "Career": () => Container(),
    "Contact Us": () => Container(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add Hotel Service",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...servicePages.keys.map((title) {
            return InkWell(
              onTap: () {
                final pageBuilder = servicePages[title];
                if (pageBuilder != null) {
                  Get.to(() => pageBuilder());
                }
              },
              child: MeMenuCardDesign(
                title: title,
                icon: '',
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Add course action
                },
                icon: const Icon(Icons.add_circle_outline, size: 20,color: AppColors.primaryColor),
                label: CustomText(
                    "Add More",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
