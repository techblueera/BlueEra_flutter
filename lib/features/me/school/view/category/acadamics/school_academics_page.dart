import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/academic_calender_screen.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/department_screen.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/faculty_details_screen.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/faculty_profile_list_screen.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/widgets/acadamic_cours_and_programs.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../laboratory/view/widgets/me_menu_card_design.dart';
class SchoolAcademicsPage extends StatefulWidget {
  const SchoolAcademicsPage({super.key});

  @override
  State<SchoolAcademicsPage> createState() => _SchoolAcademicsPageState();
}
class _SchoolAcademicsPageState extends State<SchoolAcademicsPage> {
  final List<ServiceMenuItem> academicMenus = [
    ServiceMenuItem(
      title: "Departments",
      icon: AppIconAssets.departments,
      page: () => DepartmentScreen(),
    ),
    ServiceMenuItem(
      title: "Courses / Programs",
      icon:AppIconAssets.courses_programs,
      page: () => CourseListScreen(),
      // page: () => AcadamicCoursAndPrograms(),
    ),
    ServiceMenuItem(
      title: "Faculty Details",
      icon:AppIconAssets.faculty_details,
      page: () => FacultyProfileListScreen(),
    ),
    ServiceMenuItem(
      title: "Academic Calendar",
      icon: AppIconAssets.academic_calendar,
      page: () => AcademicCalenderScreen(),
    ),
  ];


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
          ...academicMenus.map((item) {
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
