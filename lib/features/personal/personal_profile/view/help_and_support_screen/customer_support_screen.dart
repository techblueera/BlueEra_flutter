import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/help_and_support_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerSupportScreen extends StatelessWidget {
  CustomerSupportScreen({super.key});

  final controller = Get.find<HelpAndSupportController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.contactUs,),
      body: Container(
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size10, horizontal: SizeConfig.size10),
        margin: EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              AppStrings.contactUs,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              AppStrings.contactDescription,
              fontSize: SizeConfig.small,
              color: Colors.grey[600],
            ),
            SizedBox(height: SizeConfig.size16),

            // Phone Number Input with Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16,
                      vertical: SizeConfig.size12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Obx(() => CustomText(
                          controller.phoneNumber.value,
                          fontSize: SizeConfig.medium,
                          color: Colors.black87,
                        )),
                  ),
                ),
                SizedBox(width: SizeConfig.size12),

                // Call Button
                GestureDetector(
                  onTap: controller.makePhoneCall,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size8),

                // Copy Button
                GestureDetector(
                  onTap: controller.copyPhoneNumber,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
