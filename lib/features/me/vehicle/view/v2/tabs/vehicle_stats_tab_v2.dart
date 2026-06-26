import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/constants/shared_preference_utils.dart';
import '../../../../../common/statistics/view/profile_statistics_screen.dart';

/// Stats tab — the same KPI tiles surfaced in the Overview header, in an
/// expanded layout. Mirrors the hospital v2 stats tab structurally.
class VehicleStatsTabV2 extends StatelessWidget {
  final VehicleController controller;

  const VehicleStatsTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ProfileStatisticsScreen(userId: userId);
  }
}
