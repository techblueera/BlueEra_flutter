import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/v2/hospital_home_screen_v2.dart';
import 'package:flutter/material.dart';

class HospitalMain extends StatefulWidget {
  const HospitalMain({super.key});

  @override
  State<HospitalMain> createState() => _HospitalMainState();
}

class _HospitalMainState extends State<HospitalMain> {
  final hospitalServiceAiController =
      getOrPut(() => HospitalServiceAiController());

  @override
  void initState() {
    super.initState();
    hospitalServiceAiController.getHospitalFullDetailsController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: const HospitalHomeScreenV2(),
    );
  }
}
