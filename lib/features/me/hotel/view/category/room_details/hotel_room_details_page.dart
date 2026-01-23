import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../laboratory/view/widgets/me_menu_card_design.dart';

class HotelRoomDetailsMain extends StatefulWidget {
  const HotelRoomDetailsMain({super.key});

  @override
  State<HotelRoomDetailsMain> createState() => _HotelRoomDetailsMainState();
}
class _HotelRoomDetailsMainState extends State<HotelRoomDetailsMain> {

  final Map<String, Widget Function()> roomDetailsPages = {
    "Standard Room": () => Container(),
    "Economy Room": () => Container(),
    "Deluxe Room": () => Container(),
    "Super Deluxe Room": () => Container(),
    "Premium Room": () => Container(),
    "Executive Room": () => Container(),
    "Family Room": () => Container(),
    "Suite Room": () => Container(),
    "Luxury Suite": () => Container(),
    "Studio Room": () => Container(),
    "Villa / Cottage (if applicable)": () => Container(),
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Room Details",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 12),
            ...roomDetailsPages.keys.map((title) {
              return InkWell(
                onTap: () {
                  final pageBuilder = roomDetailsPages[title];
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

          ],
        ),
      ),
    );
  }
}
