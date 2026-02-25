import 'package:BlueEra/core/api/model/school_course_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/controller/course_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/add_more_course_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../../widgets/custom_text_cm.dart';

class CourseListScreen extends StatefulWidget {
  CourseListScreen({super.key, required this.isEdit});

  final bool isEdit;

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final controller = Get.put(CourseController());

  final scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        controller.loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Courses"),
      bottomNavigationBar: widget.isEdit
          ? Padding(
              padding:
                  EdgeInsets.only(left: 15, right: 15, bottom: 30, top: 10),
              child: AddMoreIconButton(
                onTapEvent: () {
                  Get.to(AddMoreCourseScreen());
                },
                buttonName: "Add More Course",
              ),
            )
          : null,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value)
            return Center(child: CircularProgressIndicator());
          if (controller.coursesList.isEmpty)
            return Center(child: CustomText("No Course Found Yet.."));
          return RefreshIndicator(
            onRefresh: () => controller.fetchCourses(isRefresh: true),
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(12),
              itemCount: controller.coursesList.length,
              itemBuilder: (context, index) =>
                  CourseCard(data: controller.coursesList[index], isEdit: widget.isEdit,),
            ),
          );
        }),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final SchoolCourseData data;
  final bool isEdit;

  CourseCard({required this.data, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText("Course: ${data.name}",
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (isEdit) _buildPopupMenu(context),
            ],
          ),
          SizedBox(height: 8),
          _infoRow("Admission: ", data.admissionProcess ?? "N/A"),
          _infoRow("Eligibility: ", data.eligibility ?? "N/A"),
          if ((data.courseFees?.yearly ?? 0) > 0)
            _infoRow("Course Fee: ",
                "₹${formatNumber(data.courseFees?.yearly ?? 0)}/Year"),
          if ((data.courseFees?.monthly ?? 0) > 0)
            _infoRow("Course Fee: ",
                "₹${formatNumber(data.courseFees?.monthly ?? 0)}/Monthly"),
          _infoRow("Course Duration: ", data.duration ?? "N/A"),
          SizedBox(height: 4),
          CustomText("Description: ${data.description}",
              color: Colors.grey, fontSize: 13, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
  ) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) async {
        if (value == 'edit') {
          Get.to(() => AddMoreCourseScreen(isEdit: true, courseData: data));
        } else {
          await showCommonDialog(
              context: context,
              text: 'Are you sure you want to delete this notice?',
              confirmCallback: () async {
                final controller = Get.find<CourseController>();

                controller.deleteSchoolDepartmentController(
                    courseID: data.id ?? "");
              },
              cancelCallback: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              confirmText: AppStrings.yes,
              cancelText: AppStrings.no);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text("Edit")),
        PopupMenuItem(
            value: 'delete',
            child: Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
                text: label, style: TextStyle(color: Colors.grey.shade600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
