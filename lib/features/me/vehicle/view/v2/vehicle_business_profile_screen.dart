import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/widgets/vehicle_showroom_overview.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standalone owner-side **business profile preview** for the vehicle
/// service (reference: `assets/dummy/s1..s5`).
///
/// Reached from the "Preview" (eye) button in [VehicleHomeScreenV2]'s top
/// bar, it shows the public-facing automotive showroom exactly as it
/// renders inside the Overview tab — both share the single
/// [VehicleShowroomOverview] body, so edits made here flow back through
/// the shared [VehicleController] and the dashboard stays in sync.
class VehicleBusinessProfileScreen extends StatefulWidget {
  const VehicleBusinessProfileScreen({super.key});

  @override
  State<VehicleBusinessProfileScreen> createState() =>
      _VehicleBusinessProfileScreenState();
}

class _VehicleBusinessProfileScreenState
    extends State<VehicleBusinessProfileScreen> {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);

  Future<void> _refreshAll() async {
    await Future.wait([
      _ctrl.fetchMyVehicles(showProgress: false),
      _ctrl.fetchMyFacilities(showProgress: false),
      _ctrl.fetchMyGallery(showProgress: false),
      _ctrl.fetchMyLivePhotos(showProgress: false),
      _ctrl.fetchMyContacts(showProgress: false),
      _ctrl.fetchReceivedTestimonials(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      appBar: CommonBackAppBar(title: AppStrings.businessProfileTitle.tr),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 12),
          child: VehicleShowroomOverview(controller: _ctrl),
        ),
      ),
    );
  }
}
