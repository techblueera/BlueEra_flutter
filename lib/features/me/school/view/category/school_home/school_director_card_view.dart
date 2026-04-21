import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/principal_message_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DirectorCard extends StatelessWidget {
  const DirectorCard(
      {super.key, required this.schoolAboutUsController, this.isEdit = false});

  final SchoolAboutUsController schoolAboutUsController;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final pm = schoolAboutUsController
        .schoolDetailsData?.value.aboutId?.principalMessage;
    final isEmpty = pm == null ||
        ((pm.name?.isEmpty ?? true) &&
            (pm.message?.isEmpty ?? true) &&
            (pm.photo?.isEmpty ?? true));

    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ServiceHomeTitleWidget(title: AppStrings.principalMessage),
                    if (isEdit)
                      IconButton(
                        onPressed: () => Get.to(PrincipalMessageScreen()),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_outline,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      CustomText(
                        AppStrings.noDataFound.tr,
                        color: AppColors.secondaryTextColor,
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Get.to(PrincipalMessageScreen()),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Add"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: BorderSide(color: AppColors.primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEdit)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ServiceHomeTitleWidget(title: AppStrings.principalMessage),
                    IconButton(
                      onPressed: () => Get.to(PrincipalMessageScreen()),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  ],
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (schoolAboutUsController.schoolDetailsData?.value.aboutId
                          ?.principalMessage?.photo?.isNotEmpty ??
                      false)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        schoolAboutUsController.schoolDetailsData?.value.aboutId
                                ?.principalMessage?.photo ??
                            "",
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpandableText(
                          text: schoolAboutUsController.schoolDetailsData?.value
                                  .aboutId?.principalMessage?.message ??
                              "",
                          trimLines: 1,
                          isReadMoreNewLine: false,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 35,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    schoolAboutUsController.schoolDetailsData
                                        ?.value.aboutId?.principalMessage?.name,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey[900],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  CustomText(
                                    schoolAboutUsController
                                            .schoolDetailsData
                                            ?.value
                                            .aboutId
                                            ?.principalMessage
                                            ?.position ??
                                        "",
                                    fontSize: 12,
                                    color: AppColors.secondaryTextColor,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
