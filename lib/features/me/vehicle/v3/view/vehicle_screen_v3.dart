import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/vehicle_home_screen_v3.dart';
import 'package:flutter/material.dart';

/// Me-tab entry point for a **Vehicle Sales** showroom, on the rebuilt
/// vehicle service (v3).
///
/// A thin host, like [GroceryScreen]: it resolves the signed-in business and
/// hands the dashboard to [VehicleHomeScreenV3].
///
/// Unlike grocery it does NOT pop the live-photo sheet on landing. The landing
/// tab here is Vehicles — the add surface — so the sheet that belongs to it is
/// the add-vehicle prompt; live photos are an Overview concern and are
/// prompted from that tab instead. See [VehicleHomeScreenV3].
class VehicleScreenV3 extends StatefulWidget {
  final bool? fromBottomNavBar;

  const VehicleScreenV3({super.key, this.fromBottomNavBar});

  @override
  State<VehicleScreenV3> createState() => _VehicleScreenV3State();
}

class _VehicleScreenV3State extends State<VehicleScreenV3> {
  // VehicleV3Controller is deliberately NOT deleted on dispose — same
  // reasoning as GroceryScreen. The bottom nav swaps its child rather than
  // stacking tabs, so leaving Me for Discover disposes this screen; tearing
  // the controller down with it would throw away the listings AND their
  // freshness stamp, and every return to Me would refetch from scratch.

  @override
  Widget build(BuildContext context) {
    return VehicleHomeScreenV3(businessId: userId);
  }
}
