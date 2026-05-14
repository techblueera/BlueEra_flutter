import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_emergency_contact.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_history_screen.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_vision_mission_screen.dart';
import 'package:BlueEra/features/me/hospital/view/management/hospital_management_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalAboutUsScreen extends StatelessWidget {
  const HospitalAboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menus = <ServiceMenuItem>[
      ServiceMenuItem(
        title: AppStrings.visionMission,
        icon: AppIconAssets.vision_mission,
        page: () => HospitalVisionMissionScreen(),
      ),
      ServiceMenuItem(
        title: AppStrings.history,
        icon: AppIconAssets.history,
        page: () => HospitalHistoryScreen(),
      ),
      ServiceMenuItem(
        title: AppStrings.managementTrust,
        icon: AppIconAssets.management_trust,
        page: () => HospitalManagementScreen(),
      ),
      ServiceMenuItem(
        title: AppStrings.emergencyContact,
        icon: AppIconAssets.emerg_call,
        page: () => HospitalEmergencyContactScreen(),
      ),
    ];

    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.aboutUs),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ...menus.map(
            (item) => InkWell(
              onTap: () => Get.to(item.page),
              child: MeMenuCardDesign(title: item.title, icon: item.icon),
            ),
          ),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}
