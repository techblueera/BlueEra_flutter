import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/school_about_us.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/school_academics_page.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/career_jobs/school_job_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/notice_news/notice_news_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/school_contact_us.dart';
import 'package:BlueEra/features/me/school/view/category/school_student_corner.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SchoolUpdateScreen extends StatelessWidget {
  SchoolUpdateScreen({super.key});

  final schoolAboutUsController = Get.put(SchoolAboutUsController());

  final aboutUsController = Get.put(SchoolController());
  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: "About Us",
      icon: AppIconAssets.about_us,
      page: () => SchoolAboutUs(),
    ),
    ServiceMenuItem(
      title: "Academics",
      icon: AppIconAssets.academics,
      page: () => SchoolAcademicsPage(),
    ),
    ServiceMenuItem(
      title: "Student Corner",
      icon: AppIconAssets.student_corner,
      page: () => SchoolStudentCorner(),
    ),
    ServiceMenuItem(
      title: "Campus Life",
      icon: AppIconAssets.campus_life,
      page: () => CampusLifeListingScreen(),
    ),
    ServiceMenuItem(
      title: "Notices & News",
      icon: AppIconAssets.notices_news,
      page: () => NoticeNewsScreen(),
      // page: () => SchoolNoticeAndNews(),
    ),
    ServiceMenuItem(
      title: "Career / Jobs",
      icon: AppIconAssets.career_jobs,
      page: () => SchoolJobListingScreen(),
    ),
    ServiceMenuItem(
      title: "Contact Us",
      icon: AppIconAssets.contact_us,
      page: () => SchoolContactUs(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteE91.withValues(alpha: 0.5),
      child: Column(
        children: [
          SizedBox(height: 12),
          ...serviceMenus.map((item) {
            return InkWell(
              onTap: () {
                Get.to(item.page); // 👈 recommended GetX syntax
              },
              child: MeMenuCardDesign(
                title: item.title,
                icon: item.icon,
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(

      child: Center(child: CustomText("Coming soon...")),
    );
  }
}
