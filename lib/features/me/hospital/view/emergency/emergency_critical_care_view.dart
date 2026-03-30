import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_service_card_home_view.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/hospital_emergency_care_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmergencyCriticalCareView extends StatefulWidget {
  final bool isReadOnly;

  const EmergencyCriticalCareView({super.key, this.isReadOnly = true});

  @override
  State<EmergencyCriticalCareView> createState() =>
      _EmergencyCriticalCareViewState();
}

class _EmergencyCriticalCareViewState extends State<EmergencyCriticalCareView> {
  final controller = Get.find<HospitalServiceAiController>();
  static const int _maxVisibleItems = 4;
  bool _isExpanded = false;

  List<Map<String, String>> _buildServices() {
    return [
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
          "icon": AppIconAssets.diag_dept_view,
          "desc": ""
        },
      if (controller.hospitalDataResModel?.value.data?.otherFacilities
              ?.medicalStore ??
          false)
        {
          "title": "Medical Store",
          "icon": AppIconAssets.medical_view,
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
  }

  @override
  Widget build(BuildContext context) {
    final services = _buildServices();

    if (services.isEmpty && widget.isReadOnly) return const SizedBox.shrink();

    final bool hasMore = services.length > _maxVisibleItems;
    final displayItems =
        _isExpanded ? services : services.take(_maxVisibleItems).toList();

    return CommonCardWidget(
      bgColor: const Color(0xff0085FE).withOpacity(0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ServiceHomeTitleWidget(
                title: AppStrings.otherFacilities,
              ),
              if (!widget.isReadOnly)
                IconButton(
                  onPressed: () => Get.to(const HospitalEmergencyCareScreen()),
                  icon: Icon(
                    services.isEmpty
                        ? Icons.add_circle_outline
                        : Icons.edit_outlined,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          services.isEmpty
              ? GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Get.to(const HospitalEmergencyCareScreen()),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: index == 0
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      color: Colors.grey[400], size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Facilities',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  },
                )
              : GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    return VerticalEmergencyServiceCard(
                      title: displayItems[index]['title']!,
                      description: displayItems[index]['desc']!,
                      icon: displayItems[index]['icon']!,
                    );
                  },
                ),
          if (hasMore && services.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: SizeConfig.paddingS),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      _isExpanded
                          ? "View Less"
                          : "View More (${services.length - _maxVisibleItems})",
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium,
                    ),
                    SizedBox(width: SizeConfig.paddingXSmall),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryColor,
                      size: SizeConfig.size20,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
