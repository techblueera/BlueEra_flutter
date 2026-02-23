import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_service_card_home_view.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
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
          "desc": ""
        },
      if (controller
              .hospitalDataResModel?.value.data?.emergencyCare?.traumaCare ??
          false)
        {
          "title": "Trauma Care",
          "icon": "assets/svg/em_trauma_care.svg",
          "desc": ""
        },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare?.icu ??
          false)
        {
          "title": "ICU (Intensive Care Unit)",
          "icon": "assets/svg/em_icu.svg",
          "desc": ""
        },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare?.ccu ??
          false)
        {
          "title": "CCU (Cardiac Care Unit)",
          "icon": "assets/svg/em_ccu.svg",
          "desc": ""
        },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare?.nicu ??
          false)
        {
          "title": "NICU (Neonatal ICU)",
          "icon": "assets/svg/em_nicu.svg",
          "desc": ""
        },
      if (controller.hospitalDataResModel?.value.data?.emergencyCare?.picu ??
          false)
        {
          "title": "PICU (Pediatric ICU)",
          "icon": "assets/svg/em_picu.svg",
          "desc": ""
        },
      if (controller
              .hospitalDataResModel?.value.data?.otherFacilities?.ambulance ??
          false)
        {"title": "Ambulance", "icon": AppIconAssets.Ambulance, "desc": ""},
      if (controller
              .hospitalDataResModel?.value.data?.otherFacilities?.bloodBank ??
          false)
        {"title": "Blood Bank", "icon": AppIconAssets.BloodBank, "desc": ""},
      if (controller.hospitalDataResModel?.value.data?.otherFacilities
              ?.diagnosticDepartments ??
          false)
        {
          "title": "Diagnostic Departments",
          "icon": AppIconAssets.diag_dept,
          "desc": ""
        },
      if (controller.hospitalDataResModel?.value.data?.otherFacilities
              ?.diagnosticDepartments ??
          false)
        {
          "title": "Diagnostic Departments",
          "icon": AppIconAssets.diag_dept,
          "desc": ""
        },
      if (controller.hospitalDataResModel?.value.data?.otherFacilities
              ?.medicalStore ??
          false)
        {
          "title": "Medical Store",
          "icon": AppIconAssets.medical_store,
          "desc": ""
        },
      if (controller.hospitalDataResModel?.value.data?.otherFacilities
              ?.pmSwasthyaBimaYojana ??
          false)
        {
          "title": "PM Swasthya Bima Yojana",
          "icon": AppIconAssets.PMYojana,
          "desc": ""
        },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(
            title: "Our Facility",
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (services.length.isEven)
                // If screen width is > 600 (Tablet/Landscape), use 2 columns
                return GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Number of columns
                    crossAxisSpacing: 8, // Horizontal space between cards
                    mainAxisSpacing: 8, // Vertical space between cards
                    childAspectRatio:
                        1.2, // Ratio of width to height (1.0 = square)
                  ),
                  itemBuilder: (context, index) {
                    return VerticalEmergencyServiceCard(
                      title: services[index]['title']!,
                      description: services[index]['desc']!,
                      icon: services[index]['icon']!,
                    );
                  },
                );
              if (services.length.isOdd)
                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
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
              return SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
