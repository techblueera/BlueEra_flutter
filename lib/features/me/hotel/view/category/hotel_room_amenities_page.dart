import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';

class HotelRoomAmenitiesPage extends StatefulWidget {
  const HotelRoomAmenitiesPage({super.key});

  @override
  State<HotelRoomAmenitiesPage> createState() => _HotelRoomAmenitiesPageState();
}
class _HotelRoomAmenitiesPageState extends State<HotelRoomAmenitiesPage> {

  final Map<String, Widget Function()> roomAmenitiesPages = {
    "Air Conditioning": () => Container(),
    "Free Wi-Fi": () => Container(),
    "Television": () => Container(),
    "Room Service": () => Container(),
    "Power Backup": () => Container(),
    "Balcony": () => Container(),
    "Attached Bathroom": () => Container(),
    "Wardrobe": () => Container(),
    "Desk / Chair": () => Container(),
    "Room Refrigerators": () => Container(),
    "Electric Cattle": () => Container(),
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Room Amenities",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 12),
            ...roomAmenitiesPages.keys.map((title) {
              return InkWell(
                onTap: () {
                  final pageBuilder = roomAmenitiesPages[title];
                  if (pageBuilder != null) {
                    Get.to(() => pageBuilder());
                  }
                },
                child: MeMenuCardDesign(
                  showToggleButton: true,
                  title: title,
                  icon: '',
                ),
              );
            }).toList(),
            SizedBox(height: SizeConfig.size14),
        
          ],
        ),
      ),
    );
  }
}
