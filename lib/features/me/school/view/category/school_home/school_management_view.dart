import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/management_and_trust.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/model/school_about_us_model.dart';

class SchoolManagementSection extends StatelessWidget {
  final List<Management>? managementData;
  final bool isEdit;

  const SchoolManagementSection(
      {super.key, required this.managementData, this.isEdit = false});

  @override
  Widget build(BuildContext context) {
    if (managementData == null || managementData!.isEmpty) {
      return CommonCardWidget(
        padding: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ServiceHomeTitleWidget(title: AppStrings.managementTrust),
                  if (isEdit)
                    IconButton(
                      onPressed: () => Get.to(ManagementAndTrust()),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                ],
              ),
            ),
            Center(
              child: Column(
                children: [
                  Icon(Icons.groups_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  CustomText(
                    AppStrings.noDataFound.tr,
                    color: AppColors.secondaryTextColor,
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Get.to(ManagementAndTrust()),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return CommonCardWidget(
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// MANAGEMENT LIST SECTION (Horizontal Scroll)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ServiceHomeTitleWidget(
                  title: AppStrings.managementTrust,
                ),
                Row(
                  children: [
                    if ((managementData?.length ?? 0) > 5)
                      InkWell(
                        onTap: () {
                          Get.to(ManagementAndTrust());
                        },
                        child: const CustomText(
                          AppStrings.viewAll,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (isEdit)
                      IconButton(
                        onPressed: () => Get.to(ManagementAndTrust()),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: (managementData?.length ?? 0) > 5
                  ? 5
                  : managementData?.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final person = managementData?[index];
                return _buildManagementCard(person ?? Management());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(Management person) {
    return Container(
      width: 160,
      margin: const EdgeInsets.all(4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: (person.photo?.isNotEmpty ?? false)
                    ? Image.network(
                        person.photo ?? "",
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return LocalAssets(
                              imagePath: AppIconAssets.place_holder_image);
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      person.name ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      person.position ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
