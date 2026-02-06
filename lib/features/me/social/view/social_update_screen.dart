import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/job_seekar/view/update_job_seekar_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/features/me/social/view/event_schedule_screen.dart';
import 'package:BlueEra/features/me/social/view/social_activity_form_screen.dart';
import 'package:BlueEra/features/me/social/view/social_add_achievements_screen.dart';
import 'package:BlueEra/features/me/social/view/social_profile_identity_screen.dart';
import 'package:BlueEra/features/me/social/view/social_vision_mission_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../laboratory/view/widgets/me_menu_card_design.dart';

class SocialUpdateScreen extends StatefulWidget {
  const SocialUpdateScreen({super.key});

  @override
  State<SocialUpdateScreen> createState() =>
      _SocialUpdateScreenState();
}

class _SocialUpdateScreenState
    extends State<SocialUpdateScreen> {

  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: "Profile Identity",
      icon: AppIconAssets.basicProfile, // Replace with your actual icon asset
      page: () => SocialProfileIdentityScreen(),
    ),
    ServiceMenuItem(
      title: "Activity Feed ",
      icon: AppIconAssets.social_activity_status,
      page: () => ComingSoon(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Events / Schedule",
      icon: AppIconAssets.availability,
      page: () => EventScheduleScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Achievements",
      icon: AppIconAssets.galleryCertifications,
      page: () => SocialAddAchievementsScreen(), // Update to your actual page
    ),

    ServiceMenuItem(
      title: "Vision & Mission",
      icon: AppIconAssets.vision_mission,
      page: () => SocialVisionMissionScreen(),
    ),
    ServiceMenuItem(
      title: "Social Activity",
      icon: AppIconAssets.social_activity,
      page: () => SocialActivityFormScreen(),
    ),

    ServiceMenuItem(
      title: "Job Portfolio/ Resume",
      icon: AppIconAssets.job_post_black,
      page: () => UpdateJobSeekerScreen(),
    ),
    ServiceMenuItem(
      title: "Contact",
      icon: AppIconAssets.contact_us,
      page: () => ComingSoon(),
    ),

  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.appBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 12),
            ...serviceMenus.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // Spacing between cards
                child: InkWell(
                  onTap: () => Get.to(item.page),
                  child: MeMenuCardDesign(
                    title: item.title,
                    icon: item.icon,
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: SizeConfig.size60),
          ],
        ),
      ),
    );
  }
}
