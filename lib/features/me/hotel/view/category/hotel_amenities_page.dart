import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';

class HotelAmenitiesPage extends StatefulWidget {
  const HotelAmenitiesPage({super.key});

  @override
  State<HotelAmenitiesPage> createState() => _HotelAmenitiesPageState();
}
class _HotelAmenitiesPageState extends State<HotelAmenitiesPage> {

  final Map<String, Widget Function()> hotelAmenitiesPages = {
    "Free Parking": () => Container(),
    "Restaurant": () => Container(),
    "24×7 Front Desk": () => Container(),
    "Elevator / Lift": () => Container(),
    "CCTV Surveillance": () => Container(),
    "Power Backup": () => Container(),
    "Laundry Service": () => Container(),
    "Swimming Pool": () => Container(),
    "Airport Transportation": () => Container(),
    "Bar": () => Container(),
    "Gym": () => Container(),
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Hotel Amenities",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 12),
            ...hotelAmenitiesPages.keys.map((title) {
              return InkWell(
                onTap: () {
                  final pageBuilder = hotelAmenitiesPages[title];
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
