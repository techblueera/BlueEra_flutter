import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_department_widget.dart';
import 'package:flutter/material.dart';

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
          HospitalBookingScreen(isReadOnly: false),
          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      ),
    );
  }
}
