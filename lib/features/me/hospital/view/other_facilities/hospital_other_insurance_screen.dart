import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_other_facilities_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalOtherInsuranceScreen extends StatefulWidget {
  const HospitalOtherInsuranceScreen({super.key});

  @override
  State<HospitalOtherInsuranceScreen> createState() =>
      _HospitalOtherInsuranceScreenState();
}

class _HospitalOtherInsuranceScreenState
    extends State<HospitalOtherInsuranceScreen> {
  late final HospitalOtherFacilitiesController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalOtherFacilitiesController());
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(title: "Cash Less Insurance"),
      body: Obx(() {
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            children: [
              CommonCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonTextField(
                      textEditController: controller.insuranceInput,
                      hintText: "E.g. Star Health, RBC, WBC",
                    ),
                    SizedBox(height: SizeConfig.size10),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(child: SizedBox()),
                          SizedBox(
                            width: 90,
                            child: PositiveCustomBtn(
                              title: "Add",
                              onTap: () => controller.addInsurance(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.cashlessInsurance
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(e),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => controller.removeInsurance(e),
                                    child: const Icon(Icons.close, size: 16),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: SizeConfig.size20),
                    SizedBox(
                      width: double.infinity,
                      child: PositiveCustomBtn(
                        title: "Submit",
                        onTap: controller.save,
                        // onTap: controller.isFormValid.value && !controller.isSaving.value ? controller.save : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
