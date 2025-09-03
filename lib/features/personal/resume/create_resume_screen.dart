import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/resume_controller.dart';
import 'package:BlueEra/features/personal/resume/sections/about_me_section.dart';
import 'package:BlueEra/features/personal/resume/sections/add_more_section.dart';
import 'package:BlueEra/features/personal/resume/sections/education_section.dart';
import 'package:BlueEra/features/personal/resume/sections/experience_section.dart';
import 'package:BlueEra/features/personal/resume/sections/profile_section.dart';
import 'package:BlueEra/features/personal/resume/sections/resume_templates_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateResumeScreen extends StatefulWidget {
  @override
  State<CreateResumeScreen> createState() => _CreateResumeScreenState();
}

class _CreateResumeScreenState extends State<CreateResumeScreen> {
  final ResumeController controller = Get.put(ResumeController());

  final ProfilePicController profilePicController =
      Get.put(ProfilePicController());
  @override
  void initState() {
    // TODO: implement initState
    apiCall();

    super.initState();
  }
  //
  apiCall() async {
    await profilePicController.getMyResume();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Create Resume",
        titleColor: AppColors.mainTextColor,
        showRightTextButton: true,
        rightTextButtonText: "Templates",
        onRightTextButtonTap: (){
          navigatePushTo(context, ResumeTemplateScreen());
        },
      ),
      body: SafeArea(
          child: ListView(
        padding: EdgeInsets.all(SizeConfig.paddingM),
        children: [
          Obx(() {
            return HorizontalTabSelector(
              horizontalMargin: 0,
              tabs: controller.sectionChips,
              selectedIndex: controller.selectedChip.value,
              onTabSelected: (index, value) {
                controller.selectedChip.value = index;
              },
              labelBuilder: (label) => label,
            );
          }),
          SizedBox(height: SizeConfig.size16),
          Obx(() {
            switch (controller.selectedChip.value) {
              case 0: // Profile
                return ProfileSection();
              case 1: // Education
                return EducationSection();
              case 2: // Experience / Salary
                return ExperienceSection();
              case 3: // Current Job
                return AboutMeSection();
              case 4: // Add More
                return AddMoreSection(); // placeholder
              default:
                return SizedBox();
            }
          }),
          SizedBox(height: SizeConfig.size20),
        ],
      )),
    );
  }
}

// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/jobs/widget/profile_header.dart';
// import 'package:BlueEra/features/common/jobs/widget/profile_section_card.dart';
// import 'package:BlueEra/features/personal/resume/fields/add_bio_screen.dart';
// import 'package:BlueEra/features/personal/resume/controller/resume_controller.dart';
// import 'package:BlueEra/features/personal/resume/fields/add_current_job.dart';
// import 'package:BlueEra/features/personal/resume/fields/add_salary_details.dart';
// import 'package:BlueEra/features/personal/resume/fields/highest_qualification_screen.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/profile_bio.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class CreateResumeScreen extends StatelessWidget {
//   final ResumeController controller = Get.put(ResumeController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonBackAppBar(title: "Create Resume"),
//       body: SafeArea(
//           child: ListView(
//         padding: EdgeInsets.all(SizeConfig.paddingM),
//         children: [
//           SizedBox(
//             height: SizeConfig.size38,
//             child: ListView.separated(
//               scrollDirection: Axis.horizontal,
//               itemCount: controller.sectionChips.length,
//               separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size8),
//               itemBuilder: (context, index) {
//                 return Obx(() {
//                   final isSelected = controller.selectedChip.value == index;
//                   return GestureDetector(
//                     onTap: () => controller.selectedChip.value = index,
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: SizeConfig.size18,
//                         vertical: SizeConfig.size8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: isSelected
//                             ? AppColors.skyBlueFF
//                             : AppColors.transparent,
//                         border: Border.all(
//                           color: isSelected
//                               ? AppColors.transparent
//                               : AppColors.grey99,
//                           width: 1.5,
//                         ),
//                         borderRadius: BorderRadius.circular(SizeConfig.size10),
//                       ),
//                       child: Text(
//                         controller.sectionChips[index],
//                         style: TextStyle(
//                           color:
//                               isSelected ? AppColors.black30 : AppColors.grey6D,
//                           fontWeight: FontWeight.w600,
//                           fontSize: SizeConfig.medium,
//                         ),
//                       ),
//                     ),
//                   );
//                 });
//               },
//             ),
//           ),

//           SizedBox(height: SizeConfig.size16),

//           /// Profile Section
//           ProfileHeader(),
//           SizedBox(height: SizeConfig.size10),

//           /// Bio
//           ProfileBio(),
//           SizedBox(height: SizeConfig.size10),

//           /// Education Section
//           Obx(() {
//             final items = controller.educationList;
//             return ProfileSectionCard(
//               title: "Bio",
//               items: items.toList(),
//               onAddPressed: () => navigatePushTo(context, AddBioScreen()),
//             );
//           }),
//           SizedBox(height: SizeConfig.size10),

//           /// Work Experience Section
//           ProfileSectionCard(
//             title: "Highest Qualification",
//             items: controller.workExperienceList,
//             onAddPressed: () =>
//                 navigatePushTo(context, HighestQualificationScreen()),
//           ),
//           SizedBox(height: SizeConfig.size10),

//           /// Work Experience Section
//           ProfileSectionCard(
//             title: "Salary Details",
//             items: controller.workExperienceList,
//                onAddPressed: () =>
//                 navigatePushTo(context, AddSalaryDetailsScreen()),
//           ),
//           SizedBox(height: SizeConfig.size10),

//           /// Work Experience Section
//           ProfileSectionCard(
//             title: "Current Job",
//             items: controller.workExperienceList,
//             onAddPressed: () =>
//                 navigatePushTo(context, AddCurrentJobScreen()),
//           ),
//           SizedBox(height: SizeConfig.size10),

//           SizedBox(height: SizeConfig.size20),

//           // // Proceed Button
//           // CustomBtn(
//           //   onTap: () {
//           //   },
//           //   title: "Proceed to application",
//           //   isValidate: true,
//           // ),
//         ],
//       )),
//     );
//   }
// }
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_image_assets.dart';
// import 'package:BlueEra/core/constants/size_config.dart';

// import 'package:BlueEra/features/common/jobs/widget/portfolio_section.dart';
// import 'package:BlueEra/features/common/jobs/widget/profile_header.dart';
// import 'package:BlueEra/features/common/jobs/widget/profile_section_card.dart';
// import 'package:BlueEra/features/common/jobs/widget/skill_section.dart';
// import 'package:BlueEra/features/personal/resume/add_achievement_screen.dart';
// import 'package:BlueEra/features/personal/resume/certificate_screen.dart';
// import 'package:BlueEra/features/personal/resume/education_resume_screen.dart';
// import 'package:BlueEra/features/personal/resume/hobbies_screen.dart';
// import 'package:BlueEra/features/personal/resume/portfolio_screen.dart';
// import 'package:BlueEra/features/personal/resume/skills_resume_screen.dart';
// import 'package:BlueEra/features/personal/resume/work_experience_resume_screen.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/profile_bio.dart';
// import 'package:flutter/material.dart';

// class CreateResumeScreen extends StatefulWidget {
//   const CreateResumeScreen({super.key});

//   @override
//   State<CreateResumeScreen> createState() => _CreateResumeScreenState();
// }

// class _CreateResumeScreenState extends State<CreateResumeScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//        appBar: CommonBackAppBar(
//          title: "Create Resume",
//        ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(12),
//           children: [
//             const ProfileHeader(),
//             SizedBox(height: SizeConfig.size10),
//             ProfileBio(),
//             SizedBox(height: SizeConfig.size10),
//             ProfileSectionCard(
//               title: "Education",
//               items: [
//                 {
//                   'title': 'Bachelor of Science (B.Sc) (Hons)',
//                   'subtitle1': 'TBD College',
//                   'subtitle2': '2020 - 2023',
//                   'trailing': 'Percentage: 60.0%',
//                 },
//                 {
//                   'title': 'Bachelor of Commerce',
//                   'subtitle1': 'TBD College',
//                   'subtitle2': 'ABC University',
//                   'trailing': 'Percentage: 72.5%',
//                 },
//               ],
//               onAddPressed: () {
//                 navigatePushTo(context, EducationResumeScreen());
//               },
//             ),
//             SizedBox(height: SizeConfig.size10),
//             ProfileSectionCard(
//               title: "Work Experience",
//               items: [
//                 {
//                   'title': 'UI/UX Designer',
//                   'subtitle1': 'BlueCS Limited, Full time',
//                   'subtitle2': 'Jan 2021 - Full time',
//                   'trailing': 'West Bengal, Durgapur - Remote',
//                 },
//                 {
//                   'title': 'Flutter Developer',
//                   'subtitle1': 'BlueCS Limited, Full time',
//                   'subtitle2': 'Jan 2021 - Full time',
//                   'trailing': 'West Bengal, Durgapur - Remote',
//                 },
//               ],
//               onAddPressed: () {
//                 navigatePushTo(context, WorkExperienceResumeScreen());
//               },
//             ),
//             SizedBox(height: SizeConfig.size10),
//             SkillSection(
//               skills: const [
//                 "Design",
//                 "Website Design",
//                 "Product Design",
//                 "UI/UX Design",
//                 "Software Design",
//               ],
//               onAddPressed: () {
//                 navigatePushTo(context, SkillsResumeScreen());
//               },
//             ),
//             SizedBox(height: SizeConfig.size10),
//             PortfolioSection(
//               links: [
//                 {
//                   'title': 'LinkedIn: ',
//                   'link': 'https://www.linkedin.com/in/example/',
//                 },
//                 {
//                   'title': 'Behance: ',
//                   'link': 'https://www.behance.net/example',
//                 },
//               ],
//               onAddPressed: () {
//                 navigatePushTo(context, PortfolioLinkScreen());
//               },
//             ),
//             SizedBox(height: SizeConfig.size10),
//             ProfileSectionCard(
//               title: "Achievements",
//               items: [
//                 {
//                   'title': 'Employee of the month',
//                   'subtitle1': 'BlueCS Limited',
//                   'subtitle2': 'March 2024',
//                   'trailing': 'Recognized for dedication, attention to detail, and consistently exceeding expectations in my role.',
//                 },
//                 {
//                   'title': 'Employee of the month',
//                   'subtitle1': 'BlueCS Limited',
//                   'subtitle2': 'March 2024',
//                   'trailing': 'Recognized for dedication, attention to detail, and consistently exceeding expectations in my role.',
//                 },
//               ],
//               onAddPressed: () {
//                 navigatePushTo(context, AddAchievementScreen());
//               },
//             ),
//             SizedBox(height: SizeConfig.size10),
//             ProfileSectionCard(
//               title: "Certifications",
//               items: const [
//                 {
//                   'title': 'Bachelor of Science (B.Sc) (Hons)',
//                   'subtitle1': 'TBD College, 2020 - 2023',
//                   'document': [
//                     AppImageAssets.certificate,
//                     AppImageAssets.certificate,
//                     AppImageAssets.certificate,
//                     // Add more if needed
//                   ]
//                 },
//               ],
//               onAddPressed: () {
//                 navigatePushTo(context, CertificateScreen());
//               },
//             ),
//             SizedBox(height: SizeConfig.size10),
//             SkillSection(
//               title: "Hobbies",
//               skills: const ["Read Books", "Learn New Tools", "Playing Football", "Singing", "Dancing"],
//               onAddPressed: () {
//                 navigatePushTo(context, HobbiesScreen());
//               },
//             ),
//             SizedBox(height: SizeConfig.size10),
//             CustomBtn(
//                 onTap: () {},
//                 title: "Proceed to application",
//                 isValidate: true,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
