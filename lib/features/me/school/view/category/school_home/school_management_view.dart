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

  /// Overrides `CommonCardWidget`'s default 10px all-around margin.
  /// Pass 0 when the caller manages spacing externally.
  final double? cardMargin;

  const SchoolManagementSection(
      {super.key,
      required this.managementData,
      this.isEdit = false,
      this.cardMargin});

  @override
  Widget build(BuildContext context) {
    if (managementData == null || managementData!.isEmpty) {
      return CommonCardWidget(
        padding: 0,
        cardMargin: cardMargin,
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
                      onPressed: () => Get.to(() => ManagementAndTrust()),
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
                      onPressed: () => Get.to(() => ManagementAndTrust()),
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
      cardMargin: cardMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// MANAGEMENT LIST SECTION (Horizontal Scroll)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "Management",
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                ),
                InkWell(
                  onTap: () => Get.to(() => ManagementAndTrust()),
                  child: CustomText(
                    AppStrings.viewAll.tr,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Container(
            // Tight fit: image 130 + footer (padding 10 + title ~19 + gap 4
            // + position ~16 + padding 10) ≈ 189. Anything taller was
            // inflating the section relative to the empty-state Column,
            // widening the gap to the next section on the page.
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: (managementData?.length ?? 0) > 5
                  ? 5
                  : managementData?.length ?? 0,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final person = managementData?[index];
                return _buildManagementCard(person ?? Management());
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildManagementCard(Management person) {
    return SizedBox(
      width: 160,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: (person.photo?.isNotEmpty ?? false)
                  ? Image.network(
                      person.photo ?? "",
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 130,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: LocalAssets(
                            imagePath: AppIconAssets.place_holder_image),
                      ),
                    )
                  : Container(
                      // Match the network-image branch (130) so the footer
                      // sits at the same vertical position for both states.
                      height: 130,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: LocalAssets(
                          imagePath: AppIconAssets.place_holder_image),
                    ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Center(
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        person.name ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 4),
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
            ),
          ],
        ),
      ),
    );
  }
}
