import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_other_facilities_controller.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_about_us.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_photos_screen.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_contact_us/hospital_contact_us.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/ipd/hospital_ipd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/opd/hospital_opd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/hospital_emergency_care_screen.dart';
import 'package:BlueEra/features/me/hospital/view/other_facilities/hospital_other_facilities_screen.dart';
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
      page: () => const HospitalOpdScreen(),
    ),
    ServiceMenuItem(
      title: "IPD (In-Patient Departments)",
      icon: AppIconAssets.ipd,
      page: () => const HospitalIpdScreen(),
    ),
    ServiceMenuItem(
      title: "Emergency & Critical Care",
      icon: AppIconAssets.emergency_care,
      page: () => const HospitalEmergencyCareScreen(),
    ),
    ServiceMenuItem(
      key: "diagnostic",
      title: "Diagnostic Departments",
      icon: AppIconAssets.diag_dept,
      page: () => const ComingSoon(),
      // page: () => SchoolNoticeAndNews(),
    ),
    ServiceMenuItem(
      key: "medical",
      title: "Medical Store",
      icon: AppIconAssets.medical_store,
      page: () => const ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Other Facilities ",
      icon: AppIconAssets.other_facilities,
      page: () => const HospitalOtherFacilitiesScreen(),
    ),
    ServiceMenuItem(
      title: "Careers",
      icon: AppIconAssets.career_jobs,
      page: () => const HospitalJobListingScreen(isReadOnly: false,),
    ),
    ServiceMenuItem(
      title: "Gallery",
      icon: AppIconAssets.other_gallery,
      page: () =>  HospitalPhotosScreen(),
    ),
    ServiceMenuItem(
      title: "Contact Us",
      icon: AppIconAssets.contact_us,
      page: () => const HospitalContactUs(),
    ),
  ];
  final controller = getOrPut(() => HospitalOtherFacilitiesController());

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteE91.withValues(alpha: 0.5),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 12),
            ...serviceMenus.map((item) {
              return item.key == "diagnostic"
                  ? Obx(() {
                      return MeMenuCardDesign(
                        title: "Diagnostic Departments",
                        icon: AppIconAssets.diag_dept,
                        showToggleButton: true,
                        // isToggleOn: false,
                        isToggleOn: controller.diagnosticStatus.value,
                        onToggleChanged: (v) {
                          controller.diagnosticStatus.value = v;
                          controller.updateStatus(
                              keyParm: "diagnosticDepartments");
                          // controller.updateToggle();
                        },
                      );
                    })
                  : item.key == "medical"
                      ? Obx(() {
                          return MeMenuCardDesign(
                            title: "Medical Store",
                            icon: AppIconAssets.medical_store,
                            showToggleButton: true,
                            isToggleOn: controller.medicalStoreStatus.value,
                            onToggleChanged: (v) {
                              controller.medicalStoreStatus.value = v;
                              controller.updateStatus(keyParm: "medicalStore");

                              // controller.updateToggle();
                            },
                          );
                        })
                      : InkWell(
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
