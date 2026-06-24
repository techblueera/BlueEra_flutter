import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
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
    if (!Get.isRegistered<LabFullDetailsController>()) {
      Get.put(LabFullDetailsController(), permanent: true);
    }

    _bootstrapLabId();
  }

  Future<void> _bootstrapLabId() async {
    try {
      if (labIDGlobal.isEmpty) {
        final ResponseModel response =
            await LabServiceRepo().getLabFullDetailsByIdRepo();
        if (response.isSuccess) {
          final fetched =
              response.response?.data['data']?['profile']?['_id'] ?? '';
          labIDGlobal = fetched;
          await setLabID(fetched);
        } else {
          labIDGlobal = '';
          await setLabID('');
        }
      }
      await getLabID();
      labServiceAiController.hasLabCreated.value = labIDGlobal.isNotEmpty;
      if (mounted) setState(() {});
    } on Exception {
      // Silent failure — UI falls back to "no lab created" state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Obx(() {
        // Subscribe to the creation flag so this rebuilds when it flips.
        labServiceAiController.hasLabCreated.value;
        return SafeArea(
          child: LabHomeScreenV2(),
        );
      }),
    );
  }
}
