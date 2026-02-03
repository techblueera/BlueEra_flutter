import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/job_seekar/view/additional_information/job_seeker_additional_info_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/education/job_seeker_education_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/hobbies/job_seeker_hobbies_form_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/joob_seeker_personal_details_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/ngo_orgamisation/job_seeker_ngo_form_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/patent/job_seeker_patents_form_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/skills/job_seeker_skills_form_screen.dart';
import 'package:BlueEra/features/me/job_seekar/view/work_experience/job_seeker_work_exp_form_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMoreJobSeekerScreen extends StatefulWidget {
  const AddMoreJobSeekerScreen({super.key});

  @override
  State<AddMoreJobSeekerScreen> createState() =>
      _AddMoreJobSeekerScreenState();
}

class _AddMoreJobSeekerScreenState
    extends State<AddMoreJobSeekerScreen> {

  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: AppStrings.hobbies,
      icon: AppIconAssets.basicProfile, // Replace with your actual icon asset
      page: () => JobSeekerHobbiesFormScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.addAdditionalInformation,
      icon: AppIconAssets.basicProfile,
      page: () => JobSeekerAdditionalInfoFormScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: AppStrings.ngoStudentOrganisations,
      icon: AppIconAssets.servicesOffered,
      page: () => JobSeekerAddNgoFormScreen(), // Update to your actual page
    ),
    ServiceMenuItem(
      title: AppStrings.patents,
      icon: AppIconAssets.aboutProfessional,
      page: () => JobSeekerPatentsFormScreen(), // Update to your actual page
    ),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(title: AppStrings.addMore,),
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
