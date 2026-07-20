import 'package:BlueEra/core/api/model/school_course_res_model.dart'
    as course_res;
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/controller/course_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/add_more_course_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    Get.to(AddMoreCourseScreen())?.then((_) => _refreshAfterEdit());
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
    Get.to(AddMoreCourseScreen(isEdit: true, courseData: data))
        ?.then((_) => _refreshAfterEdit());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.schoolDetailsData?.value;
      final courses = data?.courses ?? const <Courses>[];

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: Column(
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

            if (courses.isEmpty)
              _EmptyCoursesCard(onAdd: _openAdd)
            else
              ...courses.map((c) => Padding(
                    padding: EdgeInsets.only(bottom: SizeConfig.size10),
                    child: _CourseCard(
                      course: c,
                      onEdit: () => _openEdit(c),
                      onDelete: () => _confirmDelete(context, c),
                    ),
                  )),

            SizedBox(height: kBottomNavigationBarHeight + 10),
          ],
        ),
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

class _EmptyCoursesCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCoursesCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      padding: 24,
      cardMargin: 0,
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          CustomText(
            "No courses yet",
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Add Course"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: BorderSide(color: AppColors.primaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Courses course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final img = (course.image ?? '').trim();
    final yearly = course.courseFees?.yearly ?? 0;
    final monthly = course.courseFees?.monthly ?? 0;
    final feeLabel = monthly > 0
        ? '₹${formatNumber(monthly)}/${AppStrings.monthly.tr}'
        : '₹${formatNumber(yearly)}/${AppStrings.years.tr}';

    return Container(
      height: 185,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 115,
              height: 169,
              child: img.isNotEmpty
                  ? Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _bannerFallback(),
                    )
                  : _bannerFallback(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 0, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              course.name ?? 'N/A',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            CustomText(
                              feeLabel,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                      _CardMenu(onEdit: onEdit, onDelete: onDelete),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ExpandableText(
                    text: course.description ?? '',
                    trimLines: 2,
                    isReadMoreNewLine: false,
                    expandMode: ExpandMode.dialog,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if ((course.eligibility ?? '').trim().isNotEmpty)
                        _MiniChip(
                          icon: Icons.verified_user_outlined,
                          label: course.eligibility!,
                        ),
                      if ((course.duration ?? '').trim().isNotEmpty)
                        _MiniChip(
                          icon: Icons.access_time,
                          label: course.duration!,
                        ),
                    ],
                  ),
                  if ((course.admissionProcess ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xff2E7D32),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: CustomText(
                        course.admissionProcess!,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerFallback() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child:
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
      );
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondaryTextColor),
          const SizedBox(width: 4),
          CustomText(
            label,
            fontSize: 11,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CardMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon:
          Icon(Icons.more_vert, size: 18, color: AppColors.secondaryTextColor),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}
