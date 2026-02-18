import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_other_facilities_controller.dart';
import 'package:BlueEra/features/me/hospital/view/other_facilities/hospital_other_insurance_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';

class HospitalOtherFacilitiesScreen extends StatefulWidget {
  final String? hospitalId;
  const HospitalOtherFacilitiesScreen({super.key, this.hospitalId});
  @override
  State<HospitalOtherFacilitiesScreen> createState() => _HospitalOtherFacilitiesScreenState();
}

class _HospitalOtherFacilitiesScreenState extends State<HospitalOtherFacilitiesScreen> {
  late final HospitalOtherFacilitiesController controller;
  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalOtherFacilitiesController());
    controller.hospitalIdArg = widget.hospitalId;
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(title: "Other Facilities"),
      body: Obx(() {
        return SingleChildScrollView(
          // padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            children: [
              CommonCardWidget(
                padding: 5,
                child: Column(
                  children: [
                    InkWell(
                      onTap: (){
                        Get.to(() => const HospitalOtherInsuranceScreen());
                      },
                      child: MeMenuCardDesign(
                        title: "Cash Less Insurance",
                        icon: AppIconAssets.CashLessInsurance,
                        showToggleButton: false,
                        // onToggleChanged: (val) {
                        //   Get.to(() => const HospitalOtherInsuranceScreen());
                        // },
                      ),
                    ),
                    MeMenuCardDesign(
                      title: "Ambulance",
                      icon: AppIconAssets.Ambulance,
                      showToggleButton: true,
                      isToggleOn: controller.ambulance.value,
                      onToggleChanged: (v) {
                        controller.ambulance.value = v;
                        controller.updateToggle();
                      },
                    ),
                    MeMenuCardDesign(
                      title: "PM-Swasthya Bima Yojana",
                      icon: AppIconAssets.BloodBank,
                      showToggleButton: true,
                      isToggleOn: controller.pmSwasthyaBimaYojana.value,
                      onToggleChanged: (v) {
                        controller.pmSwasthyaBimaYojana.value = v;
                        controller.updateToggle();
                      },
                    ),
                    MeMenuCardDesign(
                      title: "Blood Bank",
                      icon: AppIconAssets.BloodBank,
                      showToggleButton: true,
                      isToggleOn: controller.bloodBank.value,
                      onToggleChanged: (v) {
                        controller.bloodBank.value = v;
                        controller.updateToggle();
                      },
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
