import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_departments_controller.dart';
import 'package:BlueEra/features/me/hospital/model/department_model.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/features/me/hospital/view/ipd/ipd_ward_list_screen.dart';
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
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.ipdTitle,
        isLeading: true,
        isShadowShow: true,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 0.0),
          child: GestureDetector(
            onTap: () {
              controller.startCreate();
              controller.selectedType.value = "IPD";
              // Get.to(() => const HospitalDepartmentFormScreen(type: "IPD"))
              //     ?.then((_) => controller.loadDepartments());
            },
            child: Container(
              height: 36,
              width: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                AppStrings.addNew,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        final ipd = controller.departments
            .where((e) => e.type.toUpperCase() == "IPD")
            .toList();
        if (ipd.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bed_outlined, size: 48, color: AppColors.greyA5),
                SizedBox(height: SizeConfig.size12),
                CustomText(AppStrings.noDataFound, color: AppColors.greyA5),
                SizedBox(height: SizeConfig.size12),
                GestureDetector(
                  onTap: () {
                    controller.startCreate();
                    controller.selectedType.value = "IPD";

                    // Get.to(() =>
                    //         const HospitalDepartmentFormScreen(type: "IPD"))
                    //     ?.then((_) => controller.loadDepartments());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomText(
                      "Add IPD Department",
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 50, top: SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...ipd.map((d) => _departmentCard(d)),
              SizedBox(height: SizeConfig.size15),
            ],
          ),
        );
      }),
    );
  }

  Widget _departmentCard(Department d) {
    return InkWell(
      onTap: () {
        Get.to(() => IpdWardListScreen(
              departmentId: d.id,
              hospitalId: d.hospitalId,
            ));
      },
      child: MeMenuCardDesign(
        title: d.key,
        icon: "assets/svg/${d.key}.svg",
      ),
    );
  }
}
