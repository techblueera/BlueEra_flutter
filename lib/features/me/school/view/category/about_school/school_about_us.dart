import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/history_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/management_and_trust.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/principal_message_screen.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/vision_and_mission.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
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

  final List<ServiceMenuItem> visionAboutMenus = [
    ServiceMenuItem(
      title: "Vision & Mission",
      icon: AppIconAssets.vision_mission,
      page: () => VisionAndMission(),
    ),
    ServiceMenuItem(
      title: "History",
      icon:AppIconAssets.history,
      page: () => HistoryScreen(),
    ),
    ServiceMenuItem(
      title: "Principal / Director Message",
      icon:AppIconAssets.principal_director_message,
      page: () => PrincipalMessageScreen(),
    ),
    ServiceMenuItem(
      title: "Management / Trust",
      icon:AppIconAssets.management_trust,
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
