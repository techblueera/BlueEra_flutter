import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
 

class Step2Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step2Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size8),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            CustomText(
              'Title',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: SizeConfig.size8),
            CommonTextField(
              textEditController: controller.titleController,
              hintText: 'e.g. Size',
              validator: controller.validateTitle,
              showLabel: false,
            ),
            
            SizedBox(height: SizeConfig.size20),
            
            // Variant Field
            CustomText(
              'Details',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            SizedBox(height: SizeConfig.size8),
            CommonTextField(
              textEditController: controller.variantController,
              hintText: 'e.g. Wireless Earbuds Bo....',
              validator: controller.validateVariant,
              showLabel: false,
            ),
            
            SizedBox(height: SizeConfig.size16),
           
         
          ],
        ),
      ),
    );
  }
}
