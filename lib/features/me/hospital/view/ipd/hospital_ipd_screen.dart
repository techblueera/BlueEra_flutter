import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_departments_controller.dart';
import 'package:BlueEra/features/me/hospital/model/department_model.dart';
import 'package:BlueEra/features/me/hospital/view/ipd/ipd_ward_list_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalIpdScreen extends StatefulWidget {
  const HospitalIpdScreen({super.key});

  @override
  State<HospitalIpdScreen> createState() => _HospitalIpdScreenState();
}

class _HospitalIpdScreenState extends State<HospitalIpdScreen> {
  late final HospitalDepartmentsController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalDepartmentsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.ipdTitle),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        final ipd = controller.departments
            .where((e) => e.type.toUpperCase() == "IPD")
            .toList();
        if (ipd.isEmpty) {
          return Center(child: CustomText(AppStrings.nodata));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 50, top: SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...ipd.map(_departmentCard),
              SizedBox(height: SizeConfig.size15),
            ],
          ),
        );
      }),
    );
  }

  Widget _departmentCard(Department d) {
    return InkWell(
      onTap: () => Get.to(
        () => IpdWardListScreen(
          departmentId: d.id,
          hospitalId: d.hospitalId,
        ),
      ),
      child: MeMenuCardDesign(
        title: d.key,
        icon: "assets/svg/${d.key}.svg",
      ),
    );
  }
}
