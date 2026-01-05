import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/view/category/otc_items_page.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../auth/controller/hospital_model_controller.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../category/emergency_and_critical_care.dart';
import '../category/ipd_in_patient_department_page.dart';
import '../category/opd_out_patient_page.dart';

class AddHospitalService extends StatefulWidget {
  const AddHospitalService({super.key});

  @override
  State<AddHospitalService> createState() => _AddHospitalServiceState();
}
class _AddHospitalServiceState extends State<AddHospitalService> {

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
  final controller = getOrPutController<HospitalModelController>(
        () => HospitalModelController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add Hospital Service",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...controller.hospitalCategoryDataList.map((title) {
            return InkWell(
              onTap: () {
                Get.toNamed(RouteHelper.getHospitalOptCategory(),
                    arguments: {
                      ApiKeys.medicalOtcChildren:title.children,
                      ApiKeys.categoryId:title.id
                    });
              },
              child: MeMenuCardDesign(
                title: title.name??'',
                icon: 'assets/icons/service_icon.svg',
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}
