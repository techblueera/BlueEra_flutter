import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_critical_care_view.dart';
import 'package:flutter/material.dart';

/// Facilities tab — surfaces emergency / critical-care facilities along
/// with other hospital amenities. Reuses `EmergencyCriticalCareView` so the
/// edit flow remains identical to the original screen.
class HospitalFacilitiesTabV2 extends StatelessWidget {
  final HospitalServiceAiController controller;

  const HospitalFacilitiesTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
      child: Column(
        children: [
          const EmergencyCriticalCareView(isReadOnly: false),
          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      ),
    );
  }
}
