import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../widgets/common_box_shadow.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/hospital_model_controller.dart';
import '../../../hospital/view/category/emergency_and_critical_care.dart';
import '../../../hospital/view/category/ipd_in_patient_department_page.dart';
import '../../../hospital/view/category/opd_out_patient_page.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';

class CategoryListView extends StatelessWidget {
  CategoryListView({super.key});

  // final Map<String, Widget Function()> servicePages = {
  //   "OPD (Out-Patient Departments)": () => OpdOutPatientPage(),
  //   "IPD (In-Patient Departments /...": () => IpdInPatientDepartmentPage(),
  //   "Emergency & Critical Care": () => EmergencyAndCriticalCare(),
  //   "Diagnostic Departments": () => OpdOutPatientPage(),
  //   "Medical Store": () => OpdOutPatientPage(),
  //   "Other Facilities": () => OpdOutPatientPage(),
  //   "Careers": () => OpdOutPatientPage(),
  //   "Management": () => OpdOutPatientPage(),
  // };

  @override
  Widget build(BuildContext context) {
    final controller = getOrPutController<HospitalModelController>(
          () => HospitalModelController(),
    );

    return Obx(() {
      return Column(
        children: [
          SizedBox(height: 12),
          ...controller.hospitalCategoryDataList.map((title) {
            return InkWell(
              onTap: () {
                if(title.children?.isNotEmpty??false){
                  Get.toNamed(RouteHelper.getHospitalOptCategory(),
                      arguments: {
                        ApiKeys.medicalOtcChildren:title.children,
                        ApiKeys.categoryId:title.id,
                        ApiKeys.title:title.name,
                      });
                }

              },
              child: MeMenuCardDesign(showToggleButton: true,
                title: title.name??'',
                icon: 'assets/icons/service_icon.svg',
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      );
    });
  }
}

