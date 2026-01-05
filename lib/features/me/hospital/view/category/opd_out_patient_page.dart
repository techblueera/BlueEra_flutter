import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../auth/model/medical_lab_details.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../widget/general_medicine.dart';

class OpdOutPatientPage extends StatefulWidget {
  const OpdOutPatientPage({super.key,required this.children, required this.categoryId, required this.title});
  final List<MedicalLabDataListModel> children;
  final String categoryId;
  final String title;
  @override
  State<OpdOutPatientPage> createState() => _OpdOutPatientPageState();
}
class _OpdOutPatientPageState extends State<OpdOutPatientPage> {
  final Map<String, Widget Function()> opdPages = {
    "General Medicine": () => DoctorListView(),
    "General Surgery": () => DoctorListView(),
    "Orthopedics": () => DoctorListView(),
    "Obstetrics & Gynecology": () => DoctorListView(),
    "Pediatrics": () => DoctorListView(),
    "ENT (Ear, Nose, Throat)": () => DoctorListView(),
    "Ophthalmology (Eye)": () => DoctorListView(),
    "Dermatology (Skin)": () => DoctorListView(),
    "Psychiatry": () => DoctorListView(),
    "Dental OPD": () => DoctorListView(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: widget.title,
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...widget.children.map((title) {
            return InkWell(
              onTap: () {
                Get.toNamed(RouteHelper.getHospitalDoctorViewCategory(),
                );
              },
              child: MeMenuCardDesign(
                showToggleButton: true,
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
