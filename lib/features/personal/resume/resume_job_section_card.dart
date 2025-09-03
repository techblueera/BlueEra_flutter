import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/current_job_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/resume_common_delete_widget.dart';
import 'package:BlueEra/features/personal/resume/resume_common_edit_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

String formatMonthYear(dynamic month, dynamic year) {
  if (month == null || year == null) return '';
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  int m = 0;
  try {
    m = int.parse(month.toString());
  } catch (_) {}
  String labelMonth = m > 0 && m < months.length ? months[m] : '';
  return (labelMonth != '' && year != null) ? '$labelMonth, $year' : '';
}

class ResumeJobSectionCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final VoidCallback? onAddPressed;
  final void Function(int index)? itemsEditCallback;
  final void Function(int index)? itemsDeleteCallback;

  ResumeJobSectionCard({
    required this.title,
    required this.items,
    this.onAddPressed,
    this.itemsEditCallback,
    this.itemsDeleteCallback,
  });

  ProfilePicController profilePicController = Get.find<ProfilePicController>();

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            color: AppColors.grey72,
            fontSize: SizeConfig.medium,
          ),
          SizedBox(height: SizeConfig.size15),
          ...items.asMap().entries.map((entry) {
            logs("entry $entry");
            final index = entry.key;
            final item = entry.value;

            return Container(
              width: SizeConfig.screenWidth,
              padding: EdgeInsets.all(SizeConfig.size10),
              margin: EdgeInsets.only(bottom: SizeConfig.size15),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey99, width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: profilePicController
                          .getResumeData.value.currentJob?.experience
                          ?.toLowerCase() ==
                      "fresher"
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: CustomText(
                                profilePicController
                                    .getResumeData.value.currentJob?.experience,
                                color: AppColors.black28,
                                fontWeight: FontWeight.w700,
                                fontSize: SizeConfig.large,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ResumeCommonEditWidget(
                              imgColor: AppColors.grey72,
                              voidCallback: itemsEditCallback != null
                                  ? () => itemsEditCallback!(index)
                                  : () {},
                            ),
                            SizedBox(width: SizeConfig.size14),
                            ResumeCommonDeleteWidget(
                              voidCallback: itemsDeleteCallback != null
                                  ? () => itemsDeleteCallback!(index)
                                  : () {},
                            ),
                          ],
                        ),
                        CustomText(profilePicController
                            .getResumeData.value.currentJob?.description),
                      ],
                    )
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Timeline: start date, vertical line, end date
                          Column(
                            children: [
                              CustomText(
                                item['startLabel'] ?? "",
                                color: AppColors.black28,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w400,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Transform.translate(
                                offset: Offset(-SizeConfig.size5, 0),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: SizeConfig.size2),
                                  child: LocalAssets(
                                    imagePath: AppIconAssets.line,
                                    height: SizeConfig.size170,
                                    imgColor: AppColors.grey72,
                                  ),
                                ),
                              ),
                              CustomText(
                                item['endLabel'] ?? "",
                                color: (item['endLabel'] == 'Present')
                                    ? AppColors.grey72
                                    : AppColors.black28,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w400,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          SizedBox(width: SizeConfig.size8),
                          // Details column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: designation and edit/delete icons
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: CustomText(
                                        item['designation'] ?? "",
                                        color: AppColors.black28,
                                        fontWeight: FontWeight.w400,
                                        fontSize: SizeConfig.large,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ResumeCommonEditWidget(
                                      imgColor: AppColors.grey72,
                                      voidCallback: itemsEditCallback != null
                                          ? () => itemsEditCallback!(index)
                                          : () {},
                                    ),
                                    SizedBox(width: SizeConfig.size14),
                                    ResumeCommonDeleteWidget(
                                      voidCallback: itemsDeleteCallback != null
                                          ? () => itemsDeleteCallback!(index)
                                          : () {},
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size5),
                                // Company row (if present)
                                Transform.translate(
                                  offset: Offset(-SizeConfig.size30, 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (item['companyRow'] != null)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: SizeConfig.size5,
                                            bottom: SizeConfig.size2,
                                          ),
                                          child: CustomText(
                                            item['companyRow'] ?? "",
                                            color: AppColors.grey72,
                                            fontSize: SizeConfig.large,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),

                                      SizedBox(height: SizeConfig.size10),
                                      // Location row (if present)
                                      if (item['locationRow'] != null)
                                        Padding(
                                          padding: EdgeInsets.only(),
                                          child: CustomText(
                                            item['locationRow'] ?? "",
                                            color: AppColors.grey72,
                                            fontSize: SizeConfig.large,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      SizedBox(height: SizeConfig.size10),
                                      // Description field (if present)
                                      if (item['description'] != null &&
                                          item['description']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                          item['description'] ?? "",
                                          style: TextStyle(
                                            color: AppColors.grey72,
                                            fontSize: SizeConfig.large,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          maxLines: 4, // or your desired limit
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          }).toList(),
          if (onAddPressed != null)
            InkWell(
              onTap: onAddPressed,
              child: Row(
                children: [
                  // Replace with your preferred icon widget
                  Icon(Icons.add, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size4),
                  CustomText(
                    "Add $title",
                    color: AppColors.primaryColor,
                    fontSize: SizeConfig.large,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
