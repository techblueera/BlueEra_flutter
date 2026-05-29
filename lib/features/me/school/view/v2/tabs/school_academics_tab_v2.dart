import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/school_academics_page.dart';
import 'package:BlueEra/features/me/school/view/category/career_jobs/school_job_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/notice_news/notice_news_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_course_view.dart';
import 'package:BlueEra/features/me/school/view/category/school_student_corner.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Academics tab — surfaces courses + the four academics sub-sections
/// (Academics, Student Corner, Notices & News, Job Vacancy) as titled
/// cards. Each section uses the shared b&w `EmptySectionPlaceholder`
/// so the user gets a consistent "tap to open / add" affordance.
class SchoolAcademicsTabV2 extends StatelessWidget {
  final SchoolAboutUsController controller;

  const SchoolAcademicsTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = controller.schoolDetailsData?.value;
      final courses = data?.courses ?? const [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),

          // ── Courses ──
          if (courses.isEmpty)
            _SectionEmptyCard(
              title: AppStrings.coursesLabel.tr,
              ctaLabel: AppStrings.addCoursesCta.tr,
              ctaIcon: Icons.menu_book_outlined,
              onTap: () => Get.to(SchoolAcademicsPage(isEdit: true))
                  ?.then((_) => controller.getSchoolByIdController()),
            )
          else
            SchoolCourseSection(courses: courses, isEdit: true),

          SizedBox(height: SizeConfig.size10),

          // ── Academics ──
          _SectionEmptyCard(
            title: AppStrings.academics.tr,
            ctaLabel: AppStrings.academics.tr,
            ctaIcon: Icons.school_outlined,
            onTap: () =>
                Get.to(SchoolAcademicsPage(isEdit: true))?.then((_) => controller.getSchoolByIdController()),
          ),

          // ── Student Corner ──
          _SectionEmptyCard(
            title: AppStrings.studentCorner.tr,
            ctaLabel: AppStrings.studentCorner.tr,
            ctaIcon: Icons.person_outline,
            onTap: () =>
                Get.to(SchoolStudentCorner(isEdit: true))?.then((_) => controller.getSchoolByIdController()),
          ),

          // ── Notices & News ──
          _SectionEmptyCard(
            title: AppStrings.noticesNews.tr,
            ctaLabel: AppStrings.noticesNews.tr,
            ctaIcon: Icons.campaign_outlined,
            onTap: () =>
                Get.to(NoticeNewsScreen(isEdit: true))?.then((_) => controller.getSchoolByIdController()),
          ),

          // ── Job Vacancy ──
          _SectionEmptyCard(
            title: AppStrings.jobVacancy.tr,
            ctaLabel: AppStrings.jobVacancy.tr,
            ctaIcon: Icons.work_outline,
            onTap: () => Get.to(SchoolJobListingScreen(isEdit: true))
                ?.then((_) => controller.getSchoolByIdController()),
          ),

          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      );
    });
  }
}

/// Titled card for each academics section — section heading + add pill
/// on the right, then the shared greyscale placeholder image with a
/// tap-to-open CTA underneath.
class _SectionEmptyCard extends StatelessWidget {
  final String title;
  final String ctaLabel;
  final IconData ctaIcon;
  final VoidCallback onTap;

  const _SectionEmptyCard({
    required this.title,
    required this.ctaLabel,
    required this.onTap,
    this.ctaIcon = Icons.add_photo_alternate_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size4),
      child: CommonCardWidget(
        padding: 10,
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(title, fontWeight: FontWeight.w700),
                _EditPill(label: AppStrings.add.tr, onTap: onTap),
              ],
            ),
            SizedBox(height: SizeConfig.size8),
            EmptySectionPlaceholder(
              imageAsset: 'assets/images/other_gallery.png',
              ctaLabel: ctaLabel,
              ctaIcon: ctaIcon,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _EditPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(label, fontSize: 12, color: AppColors.primaryColor, fontWeight: FontWeight.w600),
          ],
        ),
      ),
    );
  }
}
