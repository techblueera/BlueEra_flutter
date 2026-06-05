import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PricingEngagementScreen extends StatefulWidget {
  PricingEngagementScreen({super.key});

  @override
  State<PricingEngagementScreen> createState() =>
      _PricingEngagementScreenState();
}

class _PricingEngagementScreenState
    extends State<PricingEngagementScreen> {
  final controller = Get.find<AiProfessionalsController>();

  @override
  void initState() {
    controller.clearPricing();
    ProfessionalPricing? pricing =
        controller.getProfessionalServiceRes?.value.data?.pricing;
    controller.feeTypeController.text = pricing?.type ?? "";
    controller.feeAmountController.text =
        pricing?.amount.toString() ?? "";
    controller.minBookingController.text =
        pricing?.amount.toString() ?? "";
    controller.selectedConsultationMode.value =
        pricing?.consultationMode.toString() ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.proConsultPricingEngagementModel.tr),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size14),
          child: Column(
            children: [
              // --- Consultation Fee ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionIcon(Icons.currency_rupee,
                          AppStrings.proConsultConsultationFee.tr, AppStrings.proConsultSetFeeStructure.tr),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: CommonTextField(
                              title: AppStrings.proConsultFeeType.tr,
                              textEditController:
                                  controller.feeTypeController,
                              hintText: AppStrings.proConsultEgHourly.tr,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              keyBoardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: CommonTextField(
                              title: AppStrings.proConsultAmount.tr,
                              textEditController:
                                  controller.feeAmountController,
                              hintText: AppStrings.proConsultEgFee600.tr,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              keyBoardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CommonTextField(
                        title: AppStrings.minimumBookingAmount.tr,
                        textEditController:
                            controller.minBookingController,
                        hintText: AppStrings.proConsultEgMinFee600.tr,
                        keyBoardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size14),

              // --- Consultation Mode ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionIcon(Icons.videocam_outlined,
                          AppStrings.consultationMode.tr, AppStrings.proConsultHowDoYouConsult.tr),
                      const SizedBox(height: 16),
                      Obx(() => CommonDropdownDialog<String>(
                            title: AppStrings.selectMode.tr,
                            hintText: AppStrings.egOnline.tr,
                            items: controller.consultationModes,
                            selectedValue: controller
                                    .selectedConsultationMode
                                    .value
                                    .isEmpty
                                ? null
                                : controller
                                    .selectedConsultationMode.value,
                            displayValue: (mode) => mode,
                            onChanged: (value) {
                              if (value != null) {
                                controller
                                    .selectedConsultationMode
                                    .value = value;
                              }
                            },
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- Save ---
              Obx(() => CustomBtn(
                    title: AppStrings.save.tr,
                    isValidate: controller.isPricingValid.value,
                    onTap: controller.isPricingValid.value
                        ? () => controller.savePricingModel()
                        : null,
                  )),
              SizedBox(height: SizeConfig.size20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionIcon(
      IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(icon, color: AppColors.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(title,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.medium),
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
}
