import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/facility_controller.dart';
import 'package:BlueEra/features/me/laboratory/widget/lab_switch_row.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/info_banner.dart';
import 'package:BlueEra/widgets/section_icon_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({super.key});

  @override
  State<FacilityScreen> createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  late final FacilityController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FacilityController>()) {
      controller = Get.put(FacilityController(), permanent: true);
    } else {
      controller = Get.find<FacilityController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.facilities),
      body: SafeArea(
        child: Obx(() {
          return SingleChildScrollView(
            padding: EdgeInsets.all(SizeConfig.size14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoBanner(
                  icon: Icons.local_hospital_outlined,
                  message: AppStrings.labFacilityToggleInfo.tr,
                ),
                SizedBox(height: SizeConfig.size14),

                // --- Core Facilities ---
                _facilityCard(
                  icon: Icons.medical_services_outlined,
                  title: AppStrings.labCoreFacilities.tr,
                  subtitle: AppStrings.labCoreFacilitiesSub.tr,
                  rows: [
                    LabSwitchRow(
                      title: AppStrings.homeSampleCollection.tr,
                      value: controller.homeSampleCollection,
                      onChanged: controller.validateForm,
                    ),
                    LabSwitchRow(
                      title: AppStrings.digitalReport.tr,
                      value: controller.digitalReport,
                      onChanged: controller.validateForm,
                    ),
                    LabSwitchRow(
                      title: AppStrings.wheelchairAssistance.tr,
                      value: controller.wheelchairAssistance,
                      onChanged: controller.validateForm,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size14),

                // --- Consultation & Insurance ---
                _facilityCard(
                  icon: Icons.health_and_safety_outlined,
                  title: AppStrings.labConsultationInsurance.tr,
                  subtitle: AppStrings.labConsultationInsuranceSub.tr,
                  rows: [
                    LabSwitchRow(
                      title: AppStrings.doctorConsultationTieUp.tr,
                      value: controller.doctorConsultationTieUp,
                      onChanged: controller.validateForm,
                    ),
                    LabSwitchRow(
                      title: AppStrings.insuranceCashlessSupport.tr,
                      value: controller.insuranceCashlessSupport,
                      onChanged: controller.validateForm,
                    ),
                    LabSwitchRow(
                      title: AppStrings.health_checkup_packages,
                      value: controller.healthPackage,
                      onChanged: controller.validateForm,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size14),

                // --- Payment Options ---
                _facilityCard(
                  icon: Icons.payment_outlined,
                  title: AppStrings.labPaymentOptions.tr,
                  subtitle: AppStrings.labPaymentOptionsSub.tr,
                  rows: [
                    LabSwitchRow(
                      title: AppStrings.online_upi_payment,
                      value: controller.upiPayment,
                      onChanged: controller.validateForm,
                    ),
                    LabSwitchRow(
                      title: AppStrings.credit_card_payment,
                      value: controller.cardPayment,
                      onChanged: controller.validateForm,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                CustomBtn(
                  title: AppStrings.save,
                  isValidate: controller.isValid.value,
                  isLoading: controller.isLoading.value,
                  onTap: controller.isValid.value
                      ? () async {
                          final ok = await controller.saveFacilities();
                          if (ok) Get.back();
                        }
                      : null,
                ),
                SizedBox(height: SizeConfig.size20),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _facilityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> rows,
  }) {
    return CommonCardWidget(
      padding: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionIconHeader(icon: icon, title: title, subtitle: subtitle),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }
}
