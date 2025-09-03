import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'select_listing_type_controller.dart';

class SelectListingTypeScreen extends StatelessWidget {
  const SelectListingTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SelectListingTypeController());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar:  CommonBackAppBar(
        title: "Select listing type",
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size16),
                child: Column(
                  children: [
                    // Listing Type Options
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.listingTypes.length,
                        itemBuilder: (context, index) {
                          final listingType = controller.listingTypes[index];
                          return Obx(() => _buildListingTypeCard(
                            controller: controller,
                            index: index,
                            title: listingType['title'],
                            description: listingType['description'],
                            icon: listingType['icon'],
                            isSelected: controller.selectedIndex.value == index,
                          ));
                        },
                      ),
                    ),
                    
                    // Start Listing Button
                    SizedBox(height: SizeConfig.size24),
                    CustomBtn(
                      title: 'Start Listing',
                      onTap: controller.startListing,
                      bgColor: AppColors.primaryColor,
                      textColor: AppColors.white,
                      height: 40,
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

  Widget _buildListingTypeCard({
    required SelectListingTypeController controller,
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size16),
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.selectListingType(index),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            
            SizedBox(width: SizeConfig.size16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    description,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey9B,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 