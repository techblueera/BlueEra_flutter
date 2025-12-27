import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
class SchoolStudentCorner extends StatefulWidget {
  const SchoolStudentCorner({super.key});

  @override
  State<SchoolStudentCorner> createState() => _SchoolStudentCornerState();
}
class _SchoolStudentCornerState extends State<SchoolStudentCorner> {

  final Map<String, Widget Function()> servicePages = {
    "Time Table": () => Container(),
    "Syllabus": () => Container(),
    "Exam Schedule": () => Container(),
    "Results": () => Container(),
    "Downloads": () => Container(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Student Corner",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...servicePages.keys.map((title) {
            return InkWell(
              onTap: () {
                // final pageBuilder = servicePages[title];
                // if (pageBuilder != null) {
                //   Get.to(() => pageBuilder());
                // }
              },
              child: MeMenuCardDesign(
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
