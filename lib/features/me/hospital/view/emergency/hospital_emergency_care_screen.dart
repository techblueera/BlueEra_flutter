import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_emergency_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../features/me/laboratory/view/widgets/me_menu_card_design.dart';

class HospitalEmergencyCareScreen extends StatefulWidget {
  final String? hospitalId;
  const HospitalEmergencyCareScreen({super.key, this.hospitalId});

  @override
  State<HospitalEmergencyCareScreen> createState() => _HospitalEmergencyCareScreenState();
}

class _HospitalEmergencyCareScreenState extends State<HospitalEmergencyCareScreen> {
  late final HospitalEmergencyController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalEmergencyController());
    controller.hospitalIdArg = widget.hospitalId;
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(title: "Emergency & Critical Care"),
      body: Obx(() {
        return SingleChildScrollView(
          // padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            children: [
              CommonCardWidget(
                padding: 5,
                child: Column(
                  children: [
                    MeMenuCardDesign(
                      title: "Emergency / Casualty",
                      icon: AppIconAssets.Casualty,
                      showToggleButton: true,
                      isToggleOn: controller.emergencyCasualty.value,
                      onToggleChanged: (v) {
                        controller.emergencyCasualty.value = v;
                        controller.updateToggle();
                      },
                    ),
                    MeMenuCardDesign(
                      title: "Trauma Care",
                      icon: AppIconAssets.TraumaCare,
                      showToggleButton: true,
                      isToggleOn: controller.traumaCare.value,
                      onToggleChanged: (v) {
                        controller.traumaCare.value = v;
                        controller.updateToggle();
                      },
                    ),
                    MeMenuCardDesign(
                      title: "ICU (Intensive Care Unit)",
                      icon: AppIconAssets.IntensiveCareUnit,
                      showToggleButton: true,
                      isToggleOn: controller.icu.value,
                      onToggleChanged: (v) {
                        controller.icu.value = v;
                        controller.updateToggle();
                      },
                    ),
                    MeMenuCardDesign(
                      title: "CCU (Cardiac Care Unit)",
                      icon: AppIconAssets.CardiacCareUnit,
                      showToggleButton: true,
                      isToggleOn: controller.ccu.value,
                      onToggleChanged: (v) {
                        controller.ccu.value = v;
                        controller.updateToggle();
                      },
                    ),
                    MeMenuCardDesign(
                      title: "NICU (Neonatal ICU)",
                      icon: AppIconAssets.Neonatal,
                      showToggleButton: true,
                      isToggleOn: controller.nicu.value,
                      onToggleChanged: (v) {
                        controller.nicu.value = v;
                        controller.updateToggle();
                      },
                    ),
                    MeMenuCardDesign(
                      title: "PICU (Pediatric ICU)",
                      icon: AppIconAssets.PICU,
                      showToggleButton: true,
                      isToggleOn: controller.picu.value,
                      onToggleChanged: (v) {
                        controller.picu.value = v;
                        controller.updateToggle();
                      },
                    ),
                    SizedBox(height: SizeConfig.size20),
                    PositiveCustomBtn(
                      // isValidate: controller.isFormValid.value,
                      title: "Submit",
                      // onTap: controller.isFormValid.value && !controller.isSaving.value ? controller.save : null,
                      onTap:  controller.save ,
                    )

                  ],
                ),
              ),
              if (controller.isLoading.value)
                Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size12),
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                ),
            ],
          ),
        );
      }),
    );
  }
}
