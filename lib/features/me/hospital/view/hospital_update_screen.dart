import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_about_us.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalUpdateScreen extends StatelessWidget {
  HospitalUpdateScreen({super.key});
  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: "About Us",
      icon: AppIconAssets.about_us,
      page: () => const HospitalAboutUsScreen(),
    ),
    ServiceMenuItem(
      title: "OPD (Out-Patient Departments)",
      icon: AppIconAssets.opd,
      page: () => const ComingSoon(),
    ),
    ServiceMenuItem(
      title: "IPD (In-Patient Departments)",
      icon: AppIconAssets.ipd,
      page: () => const ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Emergency & Critical Care",
      icon: AppIconAssets.emergency_care,
      page: () => const ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Diagnostic Departments",
      icon: AppIconAssets.diag_dept,
      page: () => const ComingSoon(),
      // page: () => SchoolNoticeAndNews(),
    ),
    ServiceMenuItem(
      title: "Medical Store",
      icon: AppIconAssets.medical_store,
      page: () => const ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Other Facilities ",
      icon: AppIconAssets.other_facilities,
      page: () => const ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Careers ",
      icon: AppIconAssets.career_jobs,
      page: () => const ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Gallery",
      icon: AppIconAssets.other_gallery,
      page: () => const ComingSoon(),
    ),

    ServiceMenuItem(
      title: "Contact Us",
      icon: AppIconAssets.contact_us,
      page: () => const ComingSoon(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteE91.withValues(alpha: 0.5),
      child: SingleChildScrollView(
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
            SizedBox(height: SizeConfig.size100),
          ],
        ),
      ),
    );
  }
}
