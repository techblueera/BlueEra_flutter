import 'package:BlueEra/core/constants/app_colors.dart';
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

class _PricingEngagementScreenState extends State<PricingEngagementScreen> {
  final controller = Get.find<AiProfessionalsController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.clearPricing();

    ProfessionalPricing? pricing =
        controller.getProfessionalServiceRes?.value.data?.pricing;

    controller.feeTypeController.text = pricing?.type ?? "";

    controller.feeAmountController.text = pricing?.amount.toString() ?? "";

    controller.minBookingController.text = pricing?.amount.toString() ?? "";

    controller.selectedConsultationMode.value = pricing?.consultationMode.toString() ?? "";

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Pricing / Engagement Model"),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText("Consultation Fee", fontWeight: FontWeight.w500),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: CommonTextField(
                      textEditController: controller.feeTypeController,
                      hintText: "E.g. Hourly",
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3)
                      ],
                      keyBoardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: CommonTextField(
                      textEditController: controller.feeAmountController,
                      hintText: "₹600",
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10)
                      ],
                      // Prefix or suffix icon can be added if your CommonTextField supports it
                      keyBoardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CommonTextField(
                title: "Minimum Booking Amount",
                textEditController: controller.minBookingController,
                hintText: "E.g. ₹600",
                keyBoardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10)
                ],
              ),
              const SizedBox(height: 20),
              const CustomText("Consultation Mode",
                  color: AppColors.mainTextColor),
              const SizedBox(height: 10),
              Obx(() => CommonDropdownDialog<String>(
                    title: "Select Mode",
                    hintText: "E.g. Online",
                    items: controller.consultationModes,
                    selectedValue:
                        controller.selectedConsultationMode.value.isEmpty
                            ? null
                            : controller.selectedConsultationMode.value,
                    displayValue: (mode) => mode,
                    onChanged: (value) {
                      if (value != null)
                        controller.selectedConsultationMode.value = value;
                    },
                  )),
              const SizedBox(height: 40),
              Obx(() => CustomBtn(
                    title: "Save",
                    isValidate: controller.isPricingValid.value,
                    onTap: controller.isPricingValid.value
                        ? () => controller.savePricingModel()
                        : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
