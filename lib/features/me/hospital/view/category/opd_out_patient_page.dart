import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../widget/general_medicine.dart';

class OpdOutPatientPage extends StatefulWidget {
  const OpdOutPatientPage({super.key});

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
        title: "OPD (Out-Patient Departments)",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...opdPages.keys.map((title) {
            return InkWell(
              onTap: () {
                final pageBuilder = opdPages[title];
                if (pageBuilder != null) {
                  Get.to(pageBuilder);
                }
              },
              child: MeMenuCardDesign(count: "2",
                showCount: title=="General Medicine",
                title: title,
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
