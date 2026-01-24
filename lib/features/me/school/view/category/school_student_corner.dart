import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/student_corder_controller.dart';
import 'package:BlueEra/features/me/school/view/category/student_corder/common_student_corner_screen.dart';
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
  final controller = Get.put(StudentCornerController());
  final List<ServiceMenuItem> studentExamMenus = [
    ServiceMenuItem(
      title: "Time Table",
      icon: AppIconAssets.time_table,
      page: () => CommonStudentCornerScreen(
        title: "Time Table",
        screenName: timeTable,
      ),
    ),
    ServiceMenuItem(
      title: "Syllabus",
      icon: AppIconAssets.syllabus,
      page: () => CommonStudentCornerScreen(
        title: 'Syllabus',
        screenName: syllabus,
      ),
    ),
    ServiceMenuItem(
      title: "Exam Schedule",
      icon: AppIconAssets.exam_schedule,
      page: () => CommonStudentCornerScreen(
        title: 'Exam Schedule',
        screenName: examSchedule,
      ),
    ),
    ServiceMenuItem(
      title: "Results",
      icon: AppIconAssets.result,
      page: () => CommonStudentCornerScreen(
        title: 'Results',
        screenName: results,
      ),
    ),
    ServiceMenuItem(
      title: "Downloads",
      icon: AppIconAssets.downloads_new,
      page: () => CommonStudentCornerScreen(
        title: 'Downloads',
        screenName: downloads,
      ),
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
