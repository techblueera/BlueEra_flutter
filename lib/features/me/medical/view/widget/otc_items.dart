import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/routes/route_helper.dart';

import '../../../hospital/controller/hospital_model_controller.dart';
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
  bool isToggleAvailable(String title){
    return title == "OPT (Out-Patient Department)" ||
        title == "IPD (In-Patient Department)"||
        title == "Emergency And Critical Care"||
        title == "Diagnostic Departments"||
        title == "Medical Store"
    ;
  }
  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => HospitalModelController());

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
              child: MeMenuCardDesign(
                onToggleChanged: (val){
                 Map<String,dynamic> params ={
                   ApiKeys.isActive: val
                };
                 controller.updateEnableStatus(title.id??'',params);
                },
                isToggleOn: title.isActive??false,
                showToggleButton: isToggleAvailable(title.name??''),
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