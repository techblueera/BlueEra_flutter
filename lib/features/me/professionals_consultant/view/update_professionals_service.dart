import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/basic_profile_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/basic_profile_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/pricing_engagement_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_profile_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../laboratory/view/widgets/me_menu_card_design.dart';

class UpdateProfessionalsServicesScreen extends StatefulWidget {
  const UpdateProfessionalsServicesScreen({super.key});

  @override
  State<UpdateProfessionalsServicesScreen> createState() =>
      _UpdateProfessionalsServicesScreenState();
}

class _UpdateProfessionalsServicesScreenState
    extends State<UpdateProfessionalsServicesScreen> {
  final controller = Get.put(ProfileController());

  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: "Basic Profile",
      icon: AppIconAssets.basicProfile, // Replace with your actual icon asset
      page: () => BasicProfileScreen(),
    ),
    ServiceMenuItem(
      title: "About Professional",
      icon: AppIconAssets.aboutProfessional,
      page: () => ProfessionalProfileScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Services Offered",
      icon: AppIconAssets.servicesOffered,
      page: () =>  ComingSoon(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Gallery & Certifications",
      icon: AppIconAssets.galleryCertifications,
      page: () =>  ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Portfolio / Case Studies",
      icon: AppIconAssets.caseStudies,
      page: () =>  ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Pricing / Engagement Model",
      icon: AppIconAssets.engagementModel,
      page: () =>  PricingEngagementScreen(),
    ),
    ServiceMenuItem(
      title: "Availability",
      icon: AppIconAssets.availability,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Contact & Leads Section",
      icon: AppIconAssets.contact_us,
      page: () =>  ComingSoon(),
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
