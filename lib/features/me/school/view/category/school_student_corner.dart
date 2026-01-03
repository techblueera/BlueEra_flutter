import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';

class SchoolStudentCorner extends StatefulWidget {
  const SchoolStudentCorner({super.key});

  @override
  State<SchoolStudentCorner> createState() => _SchoolStudentCornerState();
}

class _SchoolStudentCornerState extends State<SchoolStudentCorner> {
  final List<ServiceMenuItem> studentExamMenus = [
    ServiceMenuItem(
      title: "Time Table",
      icon: AppIconAssets.time_table,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Syllabus",
      icon: AppIconAssets.syllabus,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Exam Schedule",
      icon: AppIconAssets.exam_schedule,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Results",
      icon: AppIconAssets.result,
      page: () => ComingSoon(),
    ),
    ServiceMenuItem(
      title: "Downloads",
      icon: AppIconAssets.downloads_new,
      page: () => ComingSoon(),
    ),
  ];

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
          ...studentExamMenus.map((item) {
            return InkWell(
              onTap: () {
                Get.to(item.page); // 👈 recommended GetX syntax
              },
              child: MeMenuCardDesign(
                title: item.title,
                icon: item.icon,
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
        ],
      ),
    );
  }
}
