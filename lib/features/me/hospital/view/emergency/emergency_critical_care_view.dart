import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/emergency_service_card_home_view.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/hospital_emergency_care_screen.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
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

  /// Read every (title, icon) flagged on by the hospital's emergencyCare /
  /// otherFacilities sub-models. Chain access is hoisted once into [emergency]
  /// and [facilities] so the per-item rows stay readable.
  List<_ServiceItem> _buildServices() {
    final data = controller.hospitalDataResModel?.value.data;
    final emergency = data?.emergencyCare;
    final facilities = data?.otherFacilities;

    return [
      if (emergency?.emergencyCasualty ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewEmergencyCasualty.tr,
          icon: "assets/svg/em_emergency.svg",
        ),
      if (emergency?.traumaCare ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewTraumaCare.tr,
          icon: "assets/svg/em_trauma_care.svg",
        ),
      if (emergency?.icu ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewIcu.tr,
          icon: "assets/svg/em_icu.svg",
        ),
      if (emergency?.ccu ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewCcu.tr,
          icon: "assets/svg/em_ccu.svg",
        ),
      if (emergency?.nicu ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewNicu.tr,
          icon: "assets/svg/em_nicu.svg",
        ),
      if (emergency?.picu ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewPicu.tr,
          icon: "assets/svg/em_picu.svg",
        ),
      if (facilities?.ambulance ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewAmbulance.tr,
          icon: AppIconAssets.Ambulance,
        ),
      if (facilities?.bloodBank ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewBloodBank.tr,
          icon: AppIconAssets.BloodBank,
        ),
      if (facilities?.diagnosticDepartments ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewDiagnosticDepartments.tr,
          icon: AppIconAssets.diag_dept_view,
        ),
      if (facilities?.medicalStore ?? false)
        _ServiceItem(
          title: AppStrings.medicalStore.tr,
          icon: AppIconAssets.medical_view,
        ),
      if (facilities?.pmSwasthyaBimaYojana ?? false)
        _ServiceItem(
          title: AppStrings.hospitalViewPmSwasthyaBimaYojana.tr,
          icon: AppIconAssets.PMYojana,
        ),
    ];
  }

  void _openEdit() => Get.to(() => const HospitalEmergencyCareScreen());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final services = _buildServices();

      if (services.isEmpty && widget.isReadOnly) return const SizedBox.shrink();

      final hasMore = services.length > _maxVisibleItems;
      final displayItems =
          _isExpanded ? services : services.take(_maxVisibleItems).toList();

      return CommonCardWidget(
        bgColor: const Color(0xff0085FE).withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ServiceHomeTitleWidget(title: AppStrings.otherFacilities),
                if (!widget.isReadOnly)
                  IconButton(
                    onPressed: _openEdit,
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
            if (services.isEmpty)
              EmptySectionPlaceholder(
                imageAsset: 'assets/images/other_gallery.png',
                ctaLabel: AppStrings.hospitalViewAddFacilities.tr,
                ctaIcon: Icons.local_hospital_outlined,
                onTap: _openEdit,
              )
            else
              GridView.builder(
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
                  final item = displayItems[index];
                  return VerticalEmergencyServiceCard(
                    title: item.title,
                    icon: item.icon,
                  );
                },
              ),
            if (hasMore && services.isNotEmpty)
              _buildExpandToggle(services.length - _maxVisibleItems),
          ],
        ),
      );
    });
  }

  Widget _buildExpandToggle(int extraCount) {
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.paddingS),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              _isExpanded
                  ? AppStrings.hospitalViewViewLess.tr
                  : AppStrings.hospitalViewViewMoreCount
                      .trParams({'count': '$extraCount'}),
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
    );
  }
}

class _ServiceItem {
  final String title;
  final String icon;
  const _ServiceItem({required this.title, required this.icon});
}
