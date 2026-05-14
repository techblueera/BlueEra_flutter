import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_emergency_controller.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalEmergencyCareScreen extends StatefulWidget {
  final String? hospitalId;
  const HospitalEmergencyCareScreen({super.key, this.hospitalId});

  @override
  State<HospitalEmergencyCareScreen> createState() =>
      _HospitalEmergencyCareScreenState();
}

class _HospitalEmergencyCareScreenState
    extends State<HospitalEmergencyCareScreen> {
  late final HospitalEmergencyController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalEmergencyController());
    controller.hospitalIdArg = widget.hospitalId;
    controller.load();
  }

  /// One row per RxBool toggle on the controller. Order here defines the
  /// on-screen order. Adding a new toggle = one line.
  List<({String title, String icon, RxBool rx})> _toggleSpecs() {
    return [
      (
        title: AppStrings.hospitalViewEmergencyCasualty.tr,
        icon: AppIconAssets.Casualty,
        rx: controller.emergencyCasualty,
      ),
      (
        title: AppStrings.hospitalViewTraumaCare.tr,
        icon: AppIconAssets.TraumaCare,
        rx: controller.traumaCare,
      ),
      (
        title: AppStrings.hospitalViewIcu.tr,
        icon: AppIconAssets.IntensiveCareUnit,
        rx: controller.icu,
      ),
      (
        title: AppStrings.hospitalViewCcu.tr,
        icon: AppIconAssets.CardiacCareUnit,
        rx: controller.ccu,
      ),
      (
        title: AppStrings.hospitalViewNicu.tr,
        icon: AppIconAssets.Neonatal,
        rx: controller.nicu,
      ),
      (
        title: AppStrings.hospitalViewPicu.tr,
        icon: AppIconAssets.PICU,
        rx: controller.picu,
      ),
    ];
  }

  Widget _toggleRow({
    required String title,
    required String icon,
    required RxBool rx,
  }) {
    return MeMenuCardDesign(
      title: title,
      icon: icon,
      showToggleButton: true,
      isToggleOn: rx.value,
      onToggleChanged: (v) {
        rx.value = v;
        controller.updateToggle();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.hospitalViewEmergencyCriticalCare.tr,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          child: Column(
            children: [
              CommonCardWidget(
                padding: 5,
                child: Column(
                  children: [
                    ..._toggleSpecs().map(
                      (t) =>
                          _toggleRow(title: t.title, icon: t.icon, rx: t.rx),
                    ),
                    SizedBox(height: SizeConfig.size20),
                    PositiveCustomBtn(
                      title: AppStrings.submit,
                      onTap: controller.save,
                    ),
                  ],
                ),
              ),
              if (controller.isLoading.value)
                Padding(
                  padding: EdgeInsets.only(top: SizeConfig.size12),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
