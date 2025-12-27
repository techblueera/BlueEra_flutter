import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../widgets/custom_text_cm.dart';
class SchoolContactUs extends StatefulWidget {
  const SchoolContactUs({super.key});

  @override
  State<SchoolContactUs> createState() => _SchoolContactUsState();
}
class _SchoolContactUsState extends State<SchoolContactUs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Contact Us",
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CustomText(
                            "Branch:",
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                          CustomText(
                            "DPS Dehradun",
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                      LocalAssets(imagePath: AppIconAssets.pen_line
                        ,height: 13,width: 13,),
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
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Add course action
                },
                icon: const Icon(Icons.add_circle_outline, size: 20,color: AppColors.primaryColor),
                label: CustomText(
                    "Add More Course",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
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
