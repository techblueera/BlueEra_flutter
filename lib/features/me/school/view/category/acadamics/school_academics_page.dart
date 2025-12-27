import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/widgets/acadamic_cours_and_programs.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../widgets/custom_text_cm.dart';
import '../../../../laboratory/view/widgets/me_menu_card_design.dart';
class SchoolAcademicsPage extends StatefulWidget {
  const SchoolAcademicsPage({super.key});

  @override
  State<SchoolAcademicsPage> createState() => _SchoolAcademicsPageState();
}
class _SchoolAcademicsPageState extends State<SchoolAcademicsPage> {

  final Map<String, Widget Function()> servicePages = {
    "Departments": () => Container(),
    "Courses / Programs": () => AcadamicCoursAndPrograms(),
    "Faculty Details": () => Container(),
    "Academic Calendar": () => Container(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Academics",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...servicePages.keys.map((title) {
            return InkWell(
              onTap: () {
                final pageBuilder = servicePages[title];
                if (pageBuilder != null) {
                  Get.to(pageBuilder());
                }
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
