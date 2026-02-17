import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_vision_mission_screen.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_history_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/history_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/management_and_trust.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class HospitalAboutUsScreen extends StatefulWidget {
  const HospitalAboutUsScreen({super.key});

  @override
  State<HospitalAboutUsScreen> createState() => _SchoolAboutUsState();
}

class _SchoolAboutUsState extends State<HospitalAboutUsScreen> {
  final schoolAboutUsController = Get.put(SchoolAboutUsController());
  final List<ServiceMenuItem> visionAboutMenus = [
    ServiceMenuItem(
      title: "Vision & Mission",
      icon: AppIconAssets.vision_mission,
      page: () => HospitalVisionMissionScreen(),
    ),
    ServiceMenuItem(
      title: "History",
      icon: AppIconAssets.history,
      page: () => HospitalHistoryScreen(),
    ),
    ServiceMenuItem(
      title: "Management / Trust",
      icon: AppIconAssets.management_trust,
      page: () => ManagementAndTrust(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "About Us",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...visionAboutMenus.map((item) {
            return InkWell(
              onTap: () {
                Get.to(item.page); // 👈 recommended GetX syntax
              },
              child: MeMenuCardDesign(
                title: item.title,
                icon: item.icon,
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}
