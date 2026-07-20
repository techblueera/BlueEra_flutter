import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/principal_message_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../widgets/local_assets.dart';

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
      return Card(
        elevation: 0,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      );
    }

    final photo = pm.photo ?? '';
    final message = pm.message ?? '';
    final name = pm.name ?? '';
    final position = pm.position ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (photo.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photo,
                    width: 105,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 105,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person),
                    ),
                  ),
                ),
              if (photo.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpandableText(
                      text: message,
                      trimLines: 3,
                      isReadMoreNewLine: false,
                      expandMode: ExpandMode.dialog,
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                name,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.black,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              CustomText(
                                position,
                                fontSize: 12,
                                color: AppColors.secondaryTextColor,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        if (isEdit)
                          InkWell(
                            onTap: () => Get.to(PrincipalMessageScreen()),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: LocalAssets(
                                imagePath: AppIconAssets.editIcon,
                                imgColor: AppColors.primaryColor,
                                height: 14,
                                width: 14,
                              ),
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
