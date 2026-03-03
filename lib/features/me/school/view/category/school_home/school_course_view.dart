import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/widgets/acadamic_cours_and_programs.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_details_res_model.dart';

class SchoolCourseSection extends StatelessWidget {
  final List<Courses> courses;
  final bool isEdit;

   SchoolCourseSection({super.key, required this.courses, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return CommonCardWidget(
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "View All"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ServiceHomeTitleWidget(
                  title: AppStrings.coursesPrograms,
                ),
                if (courses.length > 5)
                  InkWell(
                    onTap: () {
                      Get.to(CourseListScreen(isEdit: isEdit,));
                    },
                    child: const CustomText(
                      AppStrings.viewAll,
                      color: AppColors.primaryColor,
                    ),
                  ),
              ],
            ),
          ),

          // Horizontal List of Course Cards
          SizedBox(
            height: 160, // Adjusted for the badges and pricing
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: courses.length > 5 ? 5 : courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildCourseCard(course);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Courses course) {
    return Container(
      width: 280, // Card width based on image_02899d.jpg
      child: Card(
        elevation: 0,
        margin: EdgeInsets.only(bottom: 10, right: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Course Thumbnail (Using a placeholder or a static image from your project)

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Course Name
                  CustomText(
                    course.name ?? "N/A",
                    fontWeight: FontWeight.bold,
                    // fontSize: 16,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 3. Short Description

                  ExpandableText(
                    text: course.description ?? "",
                    trimLines: 4,
                    isReadMoreNewLine: false,
                    expandMode: ExpandMode.dialog,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppConstants.OpenSans,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Badges (Eligibility & Duration)
                  Row(
                    children: [
                      _buildBadge(course.eligibility ?? "N/A",
                          Colors.orange.shade50, Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Flexible(
                          child: _buildBadge(
                              "${AppStrings.courseDuration.tr}: ${course.duration} ${AppStrings.years.tr}",
                              Colors.green.shade50,
                              Colors.green.shade800)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5. Pricing
                  CustomText(
                      "₹${formatNumber(course.courseFees?.yearly ?? 0)}/${AppStrings.years.tr}",
                      fontWeight: FontWeight.bold,
                     ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomText(text,
          color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}
