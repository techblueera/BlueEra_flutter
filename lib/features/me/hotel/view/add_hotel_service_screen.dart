import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/hotel_service_categories_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_category_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_contact_us/hotel_contact_us.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_photos_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_screen.dart';
import 'package:BlueEra/features/me/hotel/view/room_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/room_detils_screen.dart';
import 'package:BlueEra/features/me/hotel/view/room_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddHotelServiceScreen extends StatelessWidget {
   AddHotelServiceScreen({super.key});

  final List<Map<String, String>> menuList = [
    {"name": "Upload Document", "key": "UPLOAD_DOCUMENT"},
    {"name": "About Property", "key": "ABOUT_PROPERTY"},
    {"name": "Room Details", "key": "ROOM_DETAILS"},
    {"name": "Room Amenities", "key": "ROOM_AMENITIES"},
    {"name": "Hotel Amenities", "key": "HOTEL_AMENITIES"},
    {"name": "Hotel Policies", "key": "HOTEL_POLICIES"},
    {"name": "Restaurant Menu", "key": "RESTAURANT_MENU"},
    {"name": "Property Photos", "key": "PROPERTY_PHOTOS"},
    {"name": "Career", "key": "CAREER"},
    {"name": "Contact Us", "key": "CONTACT_US"},
  ];

  @override
  Widget build(BuildContext context) {
    logs("hotelIDGlobal==== $hotelIDGlobal");
    return Scaffold(
      body: ListView.builder(
        itemCount: menuList.length,
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = menuList[index];


          return InkWell(
            onTap: () {
              handleNavigation({'key': item['key']});
            },
            child: CommonCardWidget(
                borderColorColor: AppColors.whiteE5,
                cardMargin: 7,
                child: Row(
                  children: [
                    LocalAssets(
                        imagePath:
                        "assets/category/hotel_service/${item['key']}.svg"),
                    SizedBox(
                      width: SizeConfig.size10,
                    ),
                    CustomText(
                      item['name'],
                      color: AppColors.secondaryTextColor,
                      fontSize: 18,
                    )
                  ],
                )),
          );

        },
      ),
    );
  }

  void handleNavigation(dynamic data) {
    // Access the key from the data object (assuming Map or Object with .key)
    final String? key = data is Map ? data['key'] : data.key;

    final Map<String, Widget Function()> routeMap = {
      "ROOM_DETAILS": () => RoomSelectionScreen(),
      "ROOM_AMENITIES": () => RoomAmenitiesScreen(),
      "HOTEL_AMENITIES": () => HotelAmenitiesScreen(),
      "HOTEL_POLICIES": () => HotelPoliciesScreen(),
      "CAREER": () => const ComingSoon(),
      "PROPERTY_PHOTOS": () =>  PropertyPhotoScreen(),
      "RESTAURANT_MENU": () => const ComingSoon(),
      "CONTACT_US": () => const HotelContactUs(),
      "ABOUT_PROPERTY": () => const ComingSoon(),
      "UPLOAD_DOCUMENT": () => const ComingSoon(),
    };

    final routeBuilder = routeMap[key];

    if (routeBuilder != null) {
      Get.to(routeBuilder());
    } else {
      print("Route not found for key: $key");
    }
  }
}

