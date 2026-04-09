import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/facility_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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
                // --- Info Banner ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_hospital_outlined,
                          color: AppColors.primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomText(
                          AppStrings.labFacilityToggleInfo.tr,
                          color: AppColors.primaryColor,
                          fontSize: SizeConfig.small,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size14),

                // --- Core Facilities ---
                CommonCardWidget(
                  padding: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionIcon(
                          Icons.medical_services_outlined,
                          AppStrings.labCoreFacilities.tr,
                          AppStrings.labCoreFacilitiesSub.tr,
                        ),
                        const SizedBox(height: 16),
                        _buildSwitch(AppStrings.homeSampleCollection.tr,
                            controller.homeSampleCollection),
                        _buildSwitch(AppStrings.digitalReport.tr,
                            controller.digitalReport),
                        _buildSwitch(AppStrings.wheelchairAssistance.tr,
                            controller.wheelchairAssistance),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size14),

                // --- Consultation & Insurance ---
                CommonCardWidget(
                  padding: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionIcon(
                          Icons.health_and_safety_outlined,
                          AppStrings.labConsultationInsurance.tr,
                          AppStrings.labConsultationInsuranceSub.tr,
                        ),
                        const SizedBox(height: 16),
                        _buildSwitch(AppStrings.doctorConsultationTieUp.tr,
                            controller.doctorConsultationTieUp),
                        _buildSwitch(AppStrings.insuranceCashlessSupport.tr,
                            controller.insuranceCashlessSupport),
                        _buildSwitch(AppStrings.health_checkup_packages,
                            controller.healthPackage),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size14),

                // --- Payment Options ---
                CommonCardWidget(
                  padding: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionIcon(
                          Icons.payment_outlined,
                          AppStrings.labPaymentOptions.tr,
                          AppStrings.labPaymentOptionsSub.tr,
                        ),
                        const SizedBox(height: 16),
                        _buildSwitch(AppStrings.online_upi_payment,
                            controller.upiPayment),
                        _buildSwitch(AppStrings.credit_card_payment,
                            controller.cardPayment),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Save ---
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

  Widget _sectionIcon(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(title,
                  fontWeight: FontWeight.w600, fontSize: SizeConfig.medium),
              const SizedBox(height: 2),
              CustomText(subtitle,
                  color: AppColors.secondaryTextColor,
                  fontSize: SizeConfig.small),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String title, RxBool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomText(title, color: AppColors.mainTextColor),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value.value,
              onChanged: (val) {
                value.value = val;
                controller.validateForm();
              },
              activeColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
