import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/history_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/management_and_trust.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/principal_message_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/vision_and_mission.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../laboratory/view/widgets/me_menu_card_design.dart';
class SchoolAboutUs extends StatefulWidget {
  const SchoolAboutUs({super.key});

  @override
  State<SchoolAboutUs> createState() => _SchoolAboutUsState();
}
class _SchoolAboutUsState extends State<SchoolAboutUs> {

  final Map<String, Widget Function()> servicePages = {
    "Vision & Mission": () => VisionAndMission(),
    "History": () => HistoryScreen(),
    "Principal / Director Message": () => PrincipalMessageScreen(),
    "Management / Trust": () => ManagementAndTrust(),
  };

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
          ...servicePages.keys.map((title) {
            return InkWell(
              onTap: () {
                final pageBuilder = servicePages[title];
                if (pageBuilder != null) {
                  Get.to(pageBuilder());
                }
              },
              child: MeMenuCardDesign(
                title: title,
                icon: 'assets/icons/service_icon.svg',
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}
