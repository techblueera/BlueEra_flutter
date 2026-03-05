import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_contact_us_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/lab_service_photos_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'widgets/me_menu_card_design.dart';
import 'health_camp_list_screen.dart';
import 'lab_description_screen.dart';
import 'facility_screen.dart';

class LabUpdateScreen extends StatelessWidget {
  LabUpdateScreen({super.key});

  List<ServiceMenuItem> get serviceMenus => [
    ServiceMenuItem(
      title: AppStrings.description.tr,
      icon: AppIconAssets.other_privacy,
      page: () => const LabDescriptionScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.basicBloodTest.tr,
      icon: AppIconAssets.BasicBloodTest,
      page: () => LabTestListScreen(
        collection: 'Blood test',
        title: AppStrings.basicBloodTest.tr,
      ),
    ),
    ServiceMenuItem(
      title: AppStrings.pathology.tr,
      icon: AppIconAssets.Pathology,
      page: () => LabTestListScreen(
        collection: 'Pathology',
        title: AppStrings.pathology.tr,
      ),
    ),
    ServiceMenuItem(
      title: AppStrings.radiology.tr,
      icon: AppIconAssets.Radiology,
      page: () => LabTestListScreen(
        collection: 'Radiology',
        title: AppStrings.radiology.tr,
      ),
    ),
    ServiceMenuItem(
      title: AppStrings.pulmonologyDiagnostics.tr,
      icon: AppIconAssets.PulmonologyDiagnostics,
      page: () => LabTestListScreen(
        collection: 'Pulmonology Diagnostics',
        title: AppStrings.pulmonologyDiagnostics.tr,
      ),
    ),
    ServiceMenuItem(
      title: AppStrings.ophthalmologyEnt.tr,
      icon: AppIconAssets.OphthalmologyENT,
      page: () => LabTestListScreen(
        collection: 'Ophthalmology & ENT',
        title: AppStrings.ophthalmologyEnt.tr,
      ),
    ),
    ServiceMenuItem(
      title: AppStrings.othersAddManually.tr,
      icon: AppIconAssets.OthersLab,
      page: () => LabTestListScreen(
        collection: 'Others',
        title: AppStrings.others.tr,
      ),
    ),
    ServiceMenuItem(
      title: AppStrings.facility.tr,
      icon: AppIconAssets.other_office_facility,
      page: () => FacilityScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.gallery.tr,
      icon: AppIconAssets.other_gallery,
      page: () => LabServicePhotosPhotoScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.createHealthCamp.tr,
      icon: AppIconAssets.OthersLab,
      page: () => const HealthCampListScreen(),
    ),
    ServiceMenuItem(
      title: AppStrings.contactUs.tr,
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
