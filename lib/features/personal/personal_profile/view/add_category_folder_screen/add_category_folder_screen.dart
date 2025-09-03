import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_category_folder_screen/add_category_folder_screen_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCategoryFolderScreen extends StatelessWidget {
  const AddCategoryFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(AddCategoryFolderScreenController());
    
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
              color: AppColors.white,
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.black,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size6),
                  // Title
                  Expanded(
                    child: CustomText(
                      'Add Category',
                      fontSize: SizeConfig.medium15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(SizeConfig.size16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.greyE5, width: 1),
                  ),
                  padding: EdgeInsets.all(SizeConfig.size20),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Name
                        CustomText(
                          'Category Name',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
                          decoration: BoxDecoration(
                            color: AppColors.fillColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.greyE5, width: 1),
                          ),
                          child: TextFormField(
                            controller: controller.categoryNameController,
                            validator: controller.validateCategoryName,
                            decoration: const InputDecoration(
                              hintText: "e.g. Wireless Earbuds Boat Airdop....",
                              hintStyle: TextStyle(
                                color: AppColors.grey9B,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        SizedBox(height: SizeConfig.size20),

                        // Category Description
                        CustomText(
                          'Category Description',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: 120,
                            maxHeight: 200,
                          ),
                          padding: EdgeInsets.all(SizeConfig.size12),
                          decoration: BoxDecoration(
                            color: AppColors.fillColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.greyE5, width: 1),
                          ),
                          child: TextFormField(
                            controller: controller.categoryDescriptionController,
                            validator: controller.validateCategoryDescription,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              hintText: "Sorem ipsum dolor sit amet, consectetur adipiscing e...",
                              hintStyle: TextStyle(
                                color: AppColors.grey9B,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        SizedBox(height: SizeConfig.size20),

                        // Upload Image
                        CustomText(
                          'Upload Image',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Obx(() => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              print('Upload container tapped');
                              controller.uploadImage();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size16, vertical: SizeConfig.size12),
                              decoration: BoxDecoration(
                                color: AppColors.fillColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.greyE5, width: 1),
                              ),
                              child: controller.selectedImagePath.value.isNotEmpty
                                  ? Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.greyE5, width: 1),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              File(controller.selectedImagePath.value),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: AppColors.greyE5,
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: AppColors.grey9B,
                                                    size: 30,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: SizeConfig.size12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CustomText(
                                                'Image Selected',
                                                fontSize: SizeConfig.medium,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.black,
                                              ),
                                              CustomText(
                                                'Tap to change image',
                                                fontSize: SizeConfig.small,
                                                color: AppColors.grey9B,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.edit,
                                          color: AppColors.primaryColor,
                                          size: 20,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.grey9B,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: AppColors.white,
                                            size: 16,
                                          ),
                                        ),
                                        SizedBox(width: SizeConfig.size12),
                                        CustomText(
                                          'Upload Category Image',
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.grey9B,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        )),

                        SizedBox(height: SizeConfig.size40),

                        // Action Buttons
                        Row(
                          children: [
                            // Cancel Button
                            Expanded(
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.primaryColor, width: 1),
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
                                title: controller.isLoading.value ? 'Saving...' : 'Save',
                                onTap: controller.isLoading.value ? null : controller.saveCategory,
                                bgColor: AppColors.primaryColor,
                                textColor: AppColors.white,
                                height: 45,
                              )),
                            ),
                          ],
                        ),

                        // Extra padding at bottom for keyboard
                        SizedBox(height: SizeConfig.size20),
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