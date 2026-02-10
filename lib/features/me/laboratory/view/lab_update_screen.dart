import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_contact_us_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'widgets/me_menu_card_design.dart';

class LabUpdateScreen extends StatelessWidget {
  LabUpdateScreen({super.key});

  final List<ServiceMenuItem> serviceMenus = [
    ServiceMenuItem(
      title: AppStrings.description,
      icon: AppIconAssets.other_privacy,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Basic Blood Test ",
      icon: AppIconAssets.BasicBloodTest,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Pathology",
      icon: AppIconAssets.Pathology,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Radiology",
      icon: AppIconAssets.Radiology,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Pulmonology Diagnostics",
      icon: AppIconAssets.PulmonologyDiagnostics,
      page: () => ComingSoon(),
      // page: () => SchoolNoticeAndNews(),
    ),
    ServiceMenuItem(
      title: "Ophthalmology & ENT",
      icon: AppIconAssets.OphthalmologyENT,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Others (Add Manually)",
      icon: AppIconAssets.OthersLab,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Facility ",
      icon: AppIconAssets.other_office_facility,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Gallery",
      icon: AppIconAssets.other_gallery,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Create Health Camp",
      icon: AppIconAssets.OthersLab,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Contact Us",
      icon: AppIconAssets.contact_us,
      page: () => LabContactUsScreen(),
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
