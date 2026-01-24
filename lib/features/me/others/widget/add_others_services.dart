import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/others/view/other_service_gallery/other_service_photos_screen.dart';
import 'package:BlueEra/features/me/others/view/timing_screen.dart';
import 'package:BlueEra/features/me/others/view/about_us/about_us.dart';
import 'package:BlueEra/features/me/others/view/announcements/announcements_screen.dart';
import 'package:BlueEra/features/me/others/view/other_career_jobs/other_job_listing_screen.dart';
import 'package:BlueEra/features/me/others/view/other_privacy_condition/other_privacy_condition_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../laboratory/view/widgets/me_menu_card_design.dart';

class AddOthersServices extends StatefulWidget {
  const AddOthersServices({super.key});

  @override
  State<AddOthersServices> createState() => _AddOthersServicesState();
}

class _AddOthersServicesState extends State<AddOthersServices> {
  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: "About US",
      icon: AppIconAssets.about_us, // Replace with your actual icon asset
      page: () => OthersAboutUs(),
    ),
    ServiceMenuItem(
      title: "Products",
      icon: AppIconAssets.other_products,
      page: () => ComingSoon(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Services",
      icon: AppIconAssets.other_services,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Announcements",
      icon: AppIconAssets.other_announcements,
      page: () => AnnouncementsScreen(),
    ),
    ServiceMenuItem(
      title: "Gallery",
      icon: AppIconAssets.other_gallery,
      page: () => OtherServicePhotosPhotoScreen(),
    ),
    ServiceMenuItem(
      title: "Privacy Policy, Terms & Condition",
      icon: AppIconAssets.other_privacy,
      page: () => OtherPrivacyConditionScreen(),
    ),
    ServiceMenuItem(
      title: "Careers",
      icon: AppIconAssets.other_careers,
      page: () => OtherJobListingScreen(),
    ),
    ServiceMenuItem(
      title: "Timing",
      icon: AppIconAssets.other_timing,
      page: () => TimingScreen(),
    ),
    ServiceMenuItem(
      title: "Contact US",
      icon: AppIconAssets.contact_us,
      page: () => ComingSoon(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
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
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}
