// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/me/school/controller/about_us_controller.dart';
// import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
//
// import '../../../../../core/constants/app_colors.dart';
// import '../../../../../widgets/custom_text_cm.dart';
// import '../../../laboratory/view/widgets/me_menu_card_design.dart';
// import '../category/about_school/school_about_us.dart';
// import '../category/acadamics/school_academics_page.dart';
// import '../category/campus_life/school_compus_life.dart';
// import '../category/school_contact_us.dart';
// import '../category/school_gallery.dart';
// import '../category/school_notice_and_news.dart';
// import '../category/school_student_corner.dart';
//
// class AddSchoolService extends StatefulWidget {
//   const AddSchoolService({super.key});
//
//   @override
//   State<AddSchoolService> createState() => _AddSchoolServiceState();
// }
//
// class _AddSchoolServiceState extends State<AddSchoolService> {
//
//   final Map<String, Widget Function()> servicePages = {
//     "About Us": () => SchoolAboutUs(),
//     "Academics": () => SchoolAcademicsPage(),
//     "Student Corner": () => SchoolStudentCorner(),
//     "Campus Life": () => CampusLifePage(),
//     "Notices & News": () => SchoolNoticeAndNews(),
//     "Gallery": () => SchoolGallery(),
//     "Career / Jobs": () => Container(),
//     "Contact Us": () => SchoolContactUs(),
//   };
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonBackAppBar(
//         showRightTextButton: true,
//         isShowMoreInfoIcon: true,
//         title: "Add Hospital Service",
//         isShadowShow: false,
//       ),
//       body: Column(
//         children: [
//           SizedBox(height: 12),
//           ...servicePages.keys.map((title) {
//             return InkWell(
//               onTap: () {
//                 final pageBuilder = servicePages[title];
//                 if (pageBuilder != null) {
//                   Get.to(() => pageBuilder());
//                 }
//               },
//               child: MeMenuCardDesign(
//                 title: title,
//                 icon: 'assets/icons/service_icon.svg',
//               ),
//             );
//           }).toList(),
//           SizedBox(height: SizeConfig.size14),
//           AddMoreIconButton(
//             onTapEvent: () {},
//           )
//         ],
//       ),
//     );
//   }
// }
