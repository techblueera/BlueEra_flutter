import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/opd/hospital_opd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Departments tab — wraps the existing OPD/IPD booking widget so users
/// can manage doctors and wards from this section.
class HospitalDepartmentsTabV2 extends StatelessWidget {
  final HospitalServiceAiController controller;

  const HospitalDepartmentsTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
      child: Column(
        children: [
          SizedBox(height: SizeConfig.size12),
          // Same deck the Inquiry tab carries. Its catalog card opens the OPD
          // department editor — the tab's own "Add Department" pill for the
          // first (out-patient) section. IPD wards keep their own pill inside
          // the section below; there is no single add-entry covering both.
          OrderActionsCarousel(
            onAddCatalog: () => Get.to(const HospitalOpdScreen()),
            catalogIcon: Icons.medical_services_rounded,
            catalogTitle: AppStrings.hospitalDepartments.tr,
            catalogSubtitle: AppStrings.manageHospitalDepartments.tr,
          ),
          SizedBox(height: SizeConfig.size12),
          HospitalBookingScreen(isReadOnly: false),
          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      ),
    );
  }
}
