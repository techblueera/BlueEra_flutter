import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/v2/lab_home_screen_v2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LaboratoryMain extends StatefulWidget {
  const LaboratoryMain({super.key});

  @override
  State<LaboratoryMain> createState() => _LaboratoryMainState();
}

class _LaboratoryMainState extends State<LaboratoryMain> with RouteAware {
  final labServiceAiController = getOrPut(() => LabServiceAiController());

  @override
  void initState() {
    super.initState();

    // Keep LabFullDetailsController registered for the V2 overview / contact
    // tabs that look it up via Get.find.
    LabFullDetailsController.to;

    labServiceAiController.refreshLabCreated();
  }

  @override
  Widget build(BuildContext context) {
    // Return the home screen directly (no wrapper Scaffold), mirroring
    // `grocery_screen.dart`. That keeps this screen out of the way of the
    // app-wide themeable background painted in `GetMaterialApp.builder`
    // (driven by [AppBackgroundController]) — a hardcoded wrapper Scaffold /
    // background would otherwise opt the lab screen out of that flow.
    return Obx(() {
      // Subscribe to the creation flag so this rebuilds when it flips.
      labServiceAiController.hasLabCreated.value;
      return LabHomeScreenV2();
    });
  }
}
