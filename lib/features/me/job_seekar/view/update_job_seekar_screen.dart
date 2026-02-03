import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/job_seekar/view/addmore/job_seekar_add_more_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/certification/job_seeker_certificate_form_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/education/job_seeker_education_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/joob_seeker_personal_details_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/project_portfolio/portfolio_form_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/publication/job_seeker_publication_form_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/skills/job_seeker_skills_form_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/work_experience/job_seeker_work_exp_form_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/basic_profile_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/pricing_engagement_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_contact_us_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professional_profile_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_certificates_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_timing_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../laboratory/view/widgets/me_menu_card_design.dart';

class UpdateJobSeekerScreen extends StatefulWidget {
  const UpdateJobSeekerScreen({super.key});

  @override
  State<UpdateJobSeekerScreen> createState() =>
      _UpdateJobSeekerScreenState();
}

class _UpdateJobSeekerScreenState
    extends State<UpdateJobSeekerScreen> {

  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: "Basic Profile",
      icon: AppIconAssets.basicProfile, // Replace with your actual icon asset
      page: () => JobSeekerPersonalDetailsScreen(),
    ),
    ServiceMenuItem(
      title: "Education",
      icon: AppIconAssets.servicesOffered,
      page: () => JobSeekerEducationScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Work Experience",
      icon: AppIconAssets.aboutProfessional,
      page: () => JobSeekerWorkExpFormScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Skills",
      icon: AppIconAssets.galleryCertifications,
      page: () => JobSeekerSkillsFormScreen(), // Update to your actual page
    ),

    ServiceMenuItem(
      title: "Certifications",
      icon: AppIconAssets.caseStudies,
      page: () => JobSeekerCertificateFormScreen(),
    ),
    ServiceMenuItem(
      title: "Publication",
      icon: AppIconAssets.caseStudies,
      page: () => JobSeekerAddPublishingFormScreen(),
    ),

    ServiceMenuItem(
      title: "Portfolio Projects",
      icon: AppIconAssets.engagementModel,
      page: () => JobSeekerPortfolioFormScreen(),
    ),
    ServiceMenuItem(
      title: "Resume",
      icon: AppIconAssets.availability,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Add More",
      icon: AppIconAssets.availability,
      page: () => AddMoreJobSeekerScreen(),
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
