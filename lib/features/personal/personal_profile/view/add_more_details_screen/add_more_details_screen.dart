import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'add_more_details_controller.dart';

class AddMoreDetailsScreen extends StatelessWidget {
  const AddMoreDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddMoreDetailsController());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: "Add More Details",),
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: Padding(
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
                  child: Form(
                    key: controller.formKey,
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
                        
                        // Spacer to push buttons to bottom
                        const Spacer(),
                        
                        // Action Buttons
                        Row(
                          children: [
                            // Cancel Button
                            Expanded(
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primaryColor, width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: controller.cancel,
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Center(
                                      child: CustomText(
                                        'Cancel',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(width: SizeConfig.size12),
                            
                            // Save Button
                            Expanded(
                              child: Obx(() => CustomBtn(
                                title: 'Save',
                                onTap: controller.isLoading.value ? null : controller.saveDetails,
                                bgColor: AppColors.primaryColor,
                                textColor: AppColors.white,
                                height: 45,
                              )),
                            ),
                          ],
                        ),
                      ],
                    ),
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