import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_departments_controller.dart';
import 'package:BlueEra/features/me/hospital/model/department_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/features/me/hospital/view/opd/opd_doctor_list_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalOpdScreen extends StatefulWidget {
  const HospitalOpdScreen({super.key});

  @override
  State<HospitalOpdScreen> createState() => _HospitalOpdScreenState();
}

class _HospitalOpdScreenState extends State<HospitalOpdScreen> {
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
        title: AppStrings.opdTitle,
        isLeading: true,
        isShadowShow: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        final opd = controller.departments
            .where((e) => e.type.toUpperCase() == "OPD")
            .toList();

        if (opd.isEmpty) {
          return Center(child: CustomText(AppStrings.nodata));
        }
        return SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: 50,
              // right: SizeConfig.paddingM,
              // left: SizeConfig.paddingM,
              top: SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (opd.isNotEmpty) ...[
                ...opd.map((d) => _departmentCard(d)),
                SizedBox(height: SizeConfig.size15),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _departmentCard(Department d) {
    return InkWell(
      onTap: () {
        Get.to(() => OpdDoctorListScreen(
              departmentId: d.id,
              hospitalId: d.hospitalId,
            ));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
          color: AppColors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Row(
          children: [
            LocalAssets(
              imagePath: "assets/svg/${d.key}.svg",
            ),
            SizedBox(width: SizeConfig.size8),
            Flexible(
              child: CustomText(
                d.key,
                fontSize: SizeConfig.size18,
                color: AppColors.mainTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
