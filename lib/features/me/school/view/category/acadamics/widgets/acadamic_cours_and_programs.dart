import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/add_more_course_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';

class AcadamicCoursAndPrograms extends StatefulWidget {
  const AcadamicCoursAndPrograms({super.key});

  @override
  State<AcadamicCoursAndPrograms> createState() =>
      _AcadamicCoursAndProgramsState();
}

class _AcadamicCoursAndProgramsState extends State<AcadamicCoursAndPrograms> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Courses / Programs",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// Course Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.whiteE5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomText(
                        "Course:",
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                      CustomText(
                        "NEET Foundation",
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size6),

                  _courseRow("Admission", "Direct"),
                  _courseRow("Eligibility", "10th Pass"),
                  _courseRow("Course Fee", "90,000/Year"),
                  _courseRow("Course Duration", "2 Years"),

                  SizedBox(height: SizeConfig.size6),

                  CustomText(
                    "Description: Lorem Ipsum Dolor Amet set "
                    "Lorem Ipsum Dolor Amet set...",
                    fontSize: 16,
                    color: AppColors.secondaryTextColor,
                  ),

                  SizedBox(height: SizeConfig.size16),

                  /// Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: null, // disabled like screenshot
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryTextColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: CustomText(
                        "Apply",
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Add More Course Button
            AddMoreIconButton(onTapEvent: () {
              Get.to(AddMoreCourseScreen());
            },buttonName: "Add More Course",),
            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }

  /// Reusable Row Widget
  Widget _courseRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: "$title: ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
