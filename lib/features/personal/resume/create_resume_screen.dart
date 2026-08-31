import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/resume_controller.dart';
import 'package:BlueEra/features/personal/resume/sections/about_me_section.dart';
import 'package:BlueEra/features/personal/resume/sections/add_more_section.dart';
import 'package:BlueEra/features/personal/resume/sections/education_section.dart';
import 'package:BlueEra/features/personal/resume/sections/experience_section.dart';
import 'package:BlueEra/features/personal/resume/sections/profile_section.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:get/get.dart';

class CreateResumeScreen extends StatefulWidget {
  @override
  State<CreateResumeScreen> createState() => _CreateResumeScreenState();
}

class _CreateResumeScreenState extends State<CreateResumeScreen> {
  final ResumeController controller = Get.find<ResumeController>();

  final ProfilePicController profilePicController =
      Get.find<ProfilePicController>();
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
        title: AppStrings.createResume.tr,
        titleColor: AppColors.mainTextColor,
        showRightTextButton: true,
        rightTextButtonText: AppStrings.template.tr,
        onRightTextButtonTap: () {
          // Routed (not navigatePushTo, which uses a raw MaterialPageRoute GetX
          // never sees) so ResumeTemplateBinding actually runs.
          Get.toNamed(RouteHelper.getResumeTemplateScreenRoute());
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
