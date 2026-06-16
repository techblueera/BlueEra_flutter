import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/widgets/vehicle_showroom_overview.dart';
import 'package:flutter/material.dart';

/// Overview tab for the vehicle "me" profile — renders the automotive
/// showroom storefront (reference: `assets/dummy/s1..s5`) via the shared
/// [VehicleShowroomOverview] body, so the dashboard tab and the
/// standalone preview stay visually identical.
class VehicleOverviewTabV2 extends StatelessWidget {
  final VehicleController controller;

  const VehicleOverviewTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return VehicleShowroomOverview(controller: controller);
  }
}
