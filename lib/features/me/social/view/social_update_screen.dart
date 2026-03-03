import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/job_seekar/job_seeker_resume_overview_screen.dart';
import 'package:BlueEra/features/me/social/view/event_schedule_screen.dart';
import 'package:BlueEra/features/me/social/view/social_achievements/social_certificates_screen.dart';
import 'package:BlueEra/features/me/social/view/social_activity_list_screen.dart';
import 'package:BlueEra/features/me/social/view/social_contact_us/soical_contact_us_view_screen.dart';
import 'package:BlueEra/features/me/social/view/social_feed/social_feed_screen.dart';
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
      title: AppStrings.profileIdentity,
      icon: AppIconAssets.basicProfile, // Replace with your actual icon asset
      page: () => SocialProfileIdentityScreen(),
    ),
    ServiceMenuItem(
      title:AppStrings.activityFeed,
      icon: AppIconAssets.social_activity_status,
      page: () => SocialFeedScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title:AppStrings.eventsSchedule,
      icon: AppIconAssets.availability,
      page: () => EventScheduleScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: AppStrings.achievements,
      icon: AppIconAssets.galleryCertifications,
      page: () => SocialCertificatesScreen(), // Update to your actual page
    ),

    ServiceMenuItem(
      title:AppStrings.visionMission,
      icon: AppIconAssets.vision_mission,
      page: () => SocialVisionMissionScreen(),
    ),
    ServiceMenuItem(
      title:AppStrings.socialActivity,
      icon: AppIconAssets.social_activity,
      page: () => SocialActivityListScreen(),
    ),

    ServiceMenuItem(
      title: AppStrings.jobs,
      icon: AppIconAssets.job_post_black,
      page: () => JobSeekerResumeOverviewScreen(),
      // page: () => UpdateJobSeekerScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.contact,
      icon: AppIconAssets.contact_us,
      page: () => SocialContactUsViewScreen(),
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
