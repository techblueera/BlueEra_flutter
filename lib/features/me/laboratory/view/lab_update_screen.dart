import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_contact_us_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_service_gallery/lab_service_photos_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_test_catalog_screen.dart';
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
          page: () => LabTestCatalogScreen(
            collection: 'Blood & Routine Tests',
            title: AppStrings.basicBloodTest.tr,
          ),
        ),
        ServiceMenuItem(
          title: "Preventive & Wellness Checkups",
          icon: AppIconAssets.Pathology,
          page: () => LabTestCatalogScreen(
            collection: 'Preventive & Wellness Checkups',
            title: "Preventive & Wellness Checkups",
          ),
        ),
        ServiceMenuItem(
          title: "Women, Pregnancy & Child Health",
          icon: AppIconAssets.Radiology,
          page: () => LabTestCatalogScreen(
            collection: 'Women, Pregnancy & Child Health',
            title: "Women, Pregnancy & Child Health",
          ),
        ),
        ServiceMenuItem(
          title: "Diagnostics & Imaging",
          icon: AppIconAssets.PulmonologyDiagnostics,
          page: () => LabTestCatalogScreen(
            collection: 'Diagnostics & Imaging',
            title: "Diagnostics & Imaging",
          ),
        ),
        ServiceMenuItem(
          title: "Organ & System Health",
          icon: AppIconAssets.BasicBloodTest,
          page: () => LabTestCatalogScreen(
            collection: 'Organ & System Health',
            title: "Organ & System Health",
          ),
        ),
        ServiceMenuItem(
          title: "Infection, Cancer & Immunity",
          icon: AppIconAssets.OphthalmologyENT,
          page: () => LabTestCatalogScreen(
            collection: 'Infection, Cancer & Immunity',
            title: "Infection, Cancer & Immunity",
          ),
        ),
        ServiceMenuItem(
          title: AppStrings.othersAddManually.tr,
          icon: AppIconAssets.OthersLab,
          page: () => LabTestCatalogScreen(
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
