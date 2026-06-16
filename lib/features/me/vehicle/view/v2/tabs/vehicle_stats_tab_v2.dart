import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/widgets/vehicle_overview_sections.dart';
import 'package:flutter/material.dart';

/// Stats tab — the same KPI tiles surfaced in the Overview header, in an
/// expanded layout. Mirrors the hospital v2 stats tab structurally.
class VehicleStatsTabV2 extends StatelessWidget {
  final VehicleController controller;

  const VehicleStatsTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: VehicleStatsRow(controller: controller, expanded: true),
    );
  }
}
