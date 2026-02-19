import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_service_card_home_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class EmergencyCriticalCareView extends StatelessWidget {
  final controller = Get.find<HospitalServiceAiController>();

  // Example Data
  List<Map<String, String>> services = [];

  @override
  Widget build(BuildContext context) {
    services = [
      if (controller.hospitalDataResModel?.value.data?.emergencyCare
              ?.emergencyCasualty ??
          false)
        {
          "title": "Emergency / Casualty",
          "icon": "assets/svg/em_emergency.svg",
          "desc": "Gorem ipsum dolor sit amet, consectetur adipiscing elit..."
        },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare
          ?.traumaCare ??
          false)
      {
        "title": "Trauma Care",
        "icon": "assets/svg/em_trauma_care.svg",
        "desc": "Gorem ipsum dolor sit amet, consectetur adipiscing elit..."
      },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare
          ?.icu ??
          false)
      {
        "title": "ICU (Intensive Care Unit)",
        "icon": "assets/svg/em_icu.svg",
        "desc": "Gorem ipsum dolor sit amet, consectetur adipiscing elit..."
      },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare
          ?.ccu ??
          false)
      {
        "title": "CCU (Cardiac Care Unit)",
        "icon": "assets/svg/em_ccu.svg",
        "desc": "Gorem ipsum dolor sit amet, consectetur adipiscing elit..."
      },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare
          ?.nicu ??
          false)
      {
        "title": "NICU (Neonatal ICU)",
        "icon": "assets/svg/em_nicu.svg",
        "desc": "Gorem ipsum dolor sit amet, consectetur adipiscing elit..."
      },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare
          ?.picu ??
          false)
      {
        "title": "PICU (Pediatric ICU)",
        "icon": "assets/svg/em_picu.svg",
        "desc": "Gorem ipsum dolor sit amet, consectetur adipiscing elit..."
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            "Emergency & Critical Care",
   fontSize: 20, fontWeight: FontWeight.bold),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // If screen width is > 600 (Tablet/Landscape), use 2 columns

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return EmergencyServiceCard(
                    title: services[index]['title']!,
                    description: services[index]['desc']!,
                    icon: services[index]['icon']!,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
