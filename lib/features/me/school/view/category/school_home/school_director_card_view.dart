import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';

class DirectorCard extends StatelessWidget {
  const DirectorCard({super.key, required this.schoolAboutUsController});

  final SchoolAboutUsController schoolAboutUsController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (schoolAboutUsController.schoolDetailsData?.value.aboutId
                      ?.principalMessage?.photo?.isNotEmpty ??
                  false)
                // 1. Director Image (Network)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    schoolAboutUsController.schoolDetailsData?.value.aboutId
                            ?.principalMessage?.photo ??
                        "", // Replace with your actual URL
                    width: 120,
                    height: 134,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 134,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person),
                    ),
                  ),
                ),
              const SizedBox(width: 10),

              // 2. Text Details
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
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    // Read More Button

                    const SizedBox(height: 12),

                    // Name and Designation with Blue Vertical Line
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 35,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                schoolAboutUsController.schoolDetailsData?.value
                                    .aboutId?.principalMessage?.name,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.blueGrey[900],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              CustomText(
                                schoolAboutUsController.schoolDetailsData?.value
                                        .aboutId?.principalMessage?.position ??
                                    "",
                                fontSize: 12,
                                color: Colors.grey,
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
        ),
      ),
    );
  }
}
