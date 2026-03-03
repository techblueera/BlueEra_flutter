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

  const SchoolManagementSection({super.key, required this.managementData});

  @override
  Widget build(BuildContext context) {
    if (managementData?.isEmpty ?? false) return const SizedBox.shrink();
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
              ],
            ),
          ),

          Container(
            height: 200,
            padding: EdgeInsets.symmetric(horizontal: 5),
            // Height for the horizontal cards
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

  // Individual Card for the horizontal list (image_f29c49.jpg style)
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
            // Image
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
                errorBuilder: (context,error,stack){
                          return LocalAssets(imagePath: AppIconAssets.place_holder_image);
                },
                )
                    : SizedBox.shrink(),
              ),
            ),
            // Text Content
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
