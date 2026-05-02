import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_full_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/features/me/laboratory/view/facility_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Facilities tab — surfaces facility chips (wheelchair assistance,
/// digital report, etc.) backed by `Facility`. Empty-state mirrors the
/// medical/hospital greyed placeholder so the user can jump straight
/// into the facility-edit flow.
class LabFacilitiesTabV2 extends StatelessWidget {
  final LabFullDetailsController controller;

  const LabFacilitiesTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final facility = controller.details.value?.facility;
      final isEmpty = _isFacilityEmpty(facility);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
            child: CommonCardWidget(
              padding: 10,
              cardMargin: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(AppStrings.facility.tr,
                          fontWeight: FontWeight.w700),
                      InkWell(
                        onTap: () => Get.to(() => FacilityScreen())
                            ?.then((_) => controller.fetchFullDetails()),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 14, color: AppColors.primaryColor),
                              const SizedBox(width: 4),
                              CustomText(
                                AppStrings.edit.tr,
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size12),
                  if (isEmpty)
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_gallery.png',
                      ctaLabel: AppStrings.labAddFacilityDetails.tr,
                      ctaIcon: Icons.local_hospital_outlined,
                      onTap: () => Get.to(() => FacilityScreen())
                          ?.then((_) => controller.fetchFullDetails()),
                    )
                  else
                    _FacilityChipWrap(facility: facility!),
                ],
              ),
            ),
          ),
          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }

  bool _isFacilityEmpty(Facility? facility) {
    if (facility == null) return true;
    return facility.wheelchairAssistance != true &&
        facility.doctorConsultationTieUp != true &&
        facility.insuranceCashlessSupport != true &&
        facility.homeSampleCollection != true &&
        facility.digitalReport != true &&
        (facility.other?.isEmpty ?? true);
  }
}

class _FacilityChipWrap extends StatelessWidget {
  final Facility facility;
  const _FacilityChipWrap({required this.facility});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (facility.wheelchairAssistance == true) {
      chips.add('wheelchair_assistance'.tr);
    }
    if (facility.doctorConsultationTieUp == true) {
      chips.add('doctor_consultation_tie_up'.tr);
    }
    if (facility.insuranceCashlessSupport == true) {
      chips.add('insurance_cashless_support'.tr);
    }
    if (facility.homeSampleCollection == true) {
      chips.add('home_sample_collection'.tr);
    }
    if (facility.digitalReport == true) chips.add('digital_report'.tr);
    final other = (facility.other ?? [])
        .map((e) => e.label ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...chips.map(_chip),
        ...other.map(_chip),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: CustomText(text, fontSize: SizeConfig.small),
    );
  }
}
