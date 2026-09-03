import 'package:BlueEra/core/api/model/school_course_res_model.dart'
    as course_res;
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/course_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/add_more_course_screen.dart';
import 'package:BlueEra/features/me/school/widget/school_course_list_item_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../widgets/local_assets.dart';

/// Academics tab — shows the school's course catalog as a vertical list
/// of banner-left / detail-right cards, with a header "All Courses" and
/// a "+ Add Course" pill. Add/edit/delete flow goes straight to
/// [AddMoreCourseScreen] with no intermediate menu screens.
class SchoolAcademicsTabV2 extends StatelessWidget {
  final SchoolAboutUsController controller;

  const SchoolAcademicsTabV2({super.key, required this.controller});

  void _refreshAfterEdit() {
    controller.getSchoolByIdController();
    if (Get.isRegistered<CourseController>()) {
      Get.find<CourseController>().fetchCourses(isRefresh: true);
    }
  }

  void _openAdd() {
    Get.to(() => AddMoreCourseScreen())?.then((_) => _refreshAfterEdit());
  }

  void _openEdit(Courses course) {
    // AddMoreCourseScreen expects SchoolCourseData — translate on the fly.
    final data = course_res.SchoolCourseData(
      id: course.id,
      name: course.name,
      admissionProcess: course.admissionProcess,
      eligibility: course.eligibility,
      duration: course.duration,
      description: course.description,
      image: course.image,
      courseFees: course.courseFees == null
          ? null
          : course_res.CourseFees(
              monthly: course.courseFees?.monthly,
              yearly: course.courseFees?.yearly,
            ),
    );
    Get.to(() => AddMoreCourseScreen(isEdit: true, courseData: data))
        ?.then((_) => _refreshAfterEdit());
  }

  @override
  Widget build(BuildContext context) {
    // Column so the deck sits above both states the Obx can return — the
    // empty placeholder and the populated course list alike.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size12),
        // Contribution / Bank / Refer deck. No catalog card here: this tab IS
        // the add surface and carries its own add masthead, so a card pointing
        // at the screen you are already on would be noise.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
          child: OrderActionsCarousel(),
        ),
        _coursesSection(context),
      ],
    );
  }

  Widget _coursesSection(BuildContext context) {
    return Obx(() {
      final data = controller.schoolDetailsData?.value;
      final courses = data?.courses ?? const <Courses>[];

      // Empty state: a single centered icon + Add pill. No header row,
      // no wrapping card — just the two elements in the middle of the
      // tab so the tap target is obvious when there's nothing yet.
      // No background color here so the scaffold's theme background
      // shows through — otherwise a 70%-tall white block dominates the
      // whole screen and hides the intended surface color.
      if (courses.isEmpty) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.emptyIcon,
                ),
                SizedBox(height: SizeConfig.size16),
                CustomText(
                  "No Courses Available",
                  fontSize: 13,
                  color: AppColors.secondaryTextColor,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                SizedBox(height: SizeConfig.size14),
                _AddCoursePill(onTap: _openAdd),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),

          // ── Header: All Courses + Add Course ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "All Courses",
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                ),
                _AddCoursePill(onTap: _openAdd),
              ],
            ),
          ),

          SizedBox(height: SizeConfig.size12),

          ...courses.map((c) => Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size10),
                child: SchoolCourseListItemCard(
                  course: c,
                  onEdit: () => _openEdit(c),
                  onDelete: () => _confirmDelete(context, c),
                ),
              )),

        ],
      );
    });
  }

  void _confirmDelete(BuildContext context, Courses course) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete course'),
        content: Text('Remove "${course.name ?? ''}" from your catalog?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final id = course.id;
              if (id == null || id.isEmpty) return;
              final ctrl = Get.isRegistered<CourseController>()
                  ? Get.find<CourseController>()
                  : Get.put(CourseController());
              await ctrl.deleteSchoolDepartmentController(courseID: id);
              _refreshAfterEdit();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }
}

class _AddCoursePill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCoursePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              "Add Course",
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ],
        ),
      ),
    );
  }
}

