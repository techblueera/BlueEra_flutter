import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/job_seekar/view/addmore/job_seekar_add_more_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/certification/job_seeker_certification_listing_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/joob_seeker_personal_details_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/project_portfolio/job_seeker_portfolio_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/publication/job_seeker_publication_listing_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/skills/job_seeker_skill_view_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/sections/education_section.dart';
import 'package:BlueEra/features/personal/resume/sections/experience_section.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../laboratory/view/widgets/me_menu_card_design.dart';

class UpdateJobSeekerScreen extends StatefulWidget {
  const UpdateJobSeekerScreen({super.key});

  @override
  State<UpdateJobSeekerScreen> createState() => _UpdateJobSeekerScreenState();
}

class _UpdateJobSeekerScreenState extends State<UpdateJobSeekerScreen> {
  final getResumeController = getOrPut(() => ProfilePicController());

  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: "Basic Profile",
      icon: AppIconAssets.basicProfile, // Replace with your actual icon asset
      page: () => JobSeekerPersonalDetailsScreen(),
    ),
    ServiceMenuItem(
      title: "Education",
      icon: AppIconAssets.servicesOffered,
      page: () => EducationSection(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Work Experience",
      icon: AppIconAssets.aboutProfessional,
      page: () => ExperienceSection(), // Update to your actual page
      // page: () => JobSeekerWorkExpFormScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Skills",
      icon: AppIconAssets.galleryCertifications,
      page: () => JobSeekerSkillViewScreen(), // Update to your actual page
      // page: () => JobSeekerSkillsFormScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: "Certifications",
      icon: AppIconAssets.caseStudies,
      page: () => JobSeekerCertificationListingScreen(),
    ),
    ServiceMenuItem(
      title: "Publication",
      icon: AppIconAssets.caseStudies,
      page: () => JobSeekerPublicationListingScreen(),
    ),
    ServiceMenuItem(
      title: "Portfolio Projects",
      icon: AppIconAssets.engagementModel,
      page: () => JobSeekerPortfolioScreen(),
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
  void initState() {
    // TODO: implement initState
    super.initState();
    getResumeController.getMyResume();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Job Portfolio/ Resume",
      ),
      backgroundColor: AppColors.appBackgroundColor,
      body: SingleChildScrollView(
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
