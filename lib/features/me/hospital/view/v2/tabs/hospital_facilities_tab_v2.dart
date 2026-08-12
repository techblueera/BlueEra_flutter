import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_critical_care_view.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/hospital_required_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Facilities tab — surfaces emergency / critical-care facilities along
/// with other hospital amenities. Reuses `EmergencyCriticalCareView` so the
/// edit flow remains identical to the original screen.
class HospitalFacilitiesTabV2 extends StatelessWidget {
  final HospitalServiceAiController controller;

  const HospitalFacilitiesTabV2({super.key, required this.controller});

  /// Mirrors the school Quick Info gate: facilities are mandatory. A
  /// hospital counts as "has facilities" when the server reports a count,
  /// when any facility name string is set, or when at least one
  /// emergency-care / other-facility flag is true on the fetched record.
  bool _hasFacilities(HospitalFullData? data) {
    if (data == null) return false;
    if ((data.facilityCount ?? 0) > 0) return true;
    final named = (data.facilityNames ?? [])
        .where((s) => s.trim().isNotEmpty)
        .length;
    if (named > 0) return true;
    final ec = data.emergencyCare;
    if ((ec?.emergencyCasualty ?? false) ||
        (ec?.traumaCare ?? false) ||
        (ec?.icu ?? false) ||
        (ec?.ccu ?? false) ||
        (ec?.nicu ?? false) ||
        (ec?.picu ?? false)) return true;
    final of = data.otherFacilities;
    if ((of?.ambulance ?? false) ||
        (of?.bloodBank ?? false) ||
        (of?.diagnosticDepartments ?? false) ||
        (of?.medicalStore ?? false) ||
        (of?.pmSwasthyaBimaYojana ?? false)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
      child: Column(
        children: [
          SizedBox(height: SizeConfig.size12),
          Obx(() {
            final data = controller.hospitalDataResModel?.value.data;
            if (_hasFacilities(data)) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size12),
              child: const HospitalRequiredBanner(
                heading: 'Facilities are required',
                message:
                    'Please mark at least one emergency care or other facility. This section is mandatory to complete your hospital profile.',
              ),
            );
          }),
          const EmergencyCriticalCareView(isReadOnly: false),
          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      ),
    );
  }
}
