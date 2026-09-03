import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/automotive_service/controller/staff_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StaffFormScreen extends StatelessWidget {

  final controller = Get.find<AutomotiveStaffController>();

  StaffFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: controller.editingId == null ? AppStrings.otherAddStaff.tr : AppStrings.otherEditStaff.tr,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CommonCardWidget(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Obx(() {
                    // Determine image path for display
                    String? imagePath;
                    if (controller.selectedImage.value != null) {
                      imagePath = controller.selectedImage.value!.path;
                    } else {
                      imagePath = controller.currentImageUrl;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: SizeConfig.size20),
                        Center(
                          child: CommonProfileImage(
                            imagePath: imagePath,
                            dialogTitle: AppStrings.otherUploadPicture.tr,
                            onImageUpdate: (path) {
                              controller.selectedImage.value = File(path);
                            },
                            isOwnProfile: true,
                            showProfileBorder: true,
                            borderColor: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: SizeConfig.size30),
                        CommonTextField(
                          title: AppStrings.otherFieldName.tr,
                          textEditController: controller.nameController,
                          hintText: AppStrings.otherEnterName.tr,
                        ),
                        SizedBox(height: SizeConfig.size15),
                        CommonTextField(
                          title: AppStrings.otherFieldPosition.tr,
                          textEditController: controller.positionController,
                          hintText: AppStrings.otherHintPositionDesigner.tr,
                        ),
                        SizedBox(height: SizeConfig.size15),
                        CommonTextField(
                          title: AppStrings.otherFieldQualification.tr,
                          textEditController:
                              controller.qualificationController,
                          hintText: AppStrings.otherHintQualificationDiploma.tr,
                        ),
                        SizedBox(height: SizeConfig.size15),
                        
                        // Joining Date (From)
                        CustomText(
                          AppStrings.otherJoiningDate.tr,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        NewDatePicker(
                          selectedDay: controller.fromDay.value,
                          selectedMonth: controller.fromMonth.value,
                          selectedYear: controller.fromYear.value,
                          isAgeValidation15: false,
                          isFutureYear: false,
                          onDayChanged: (value) {
                            controller.fromDay.value = value;
                          },
                          onMonthChanged: (value) {
                            controller.fromMonth.value = value;
                          },
                          onYearChanged: (value) {
                            controller.fromYear.value = value;
                          },
                        ),
                        
                        SizedBox(height: SizeConfig.size15),
                        
                        // Present Checkbox
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: controller.isPresent.value,
                                onChanged: (val) {
                                  controller.isPresent.value = val ?? false;
                                },
                                activeColor: AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            CustomText(
                              AppStrings.present.tr,
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor,
                            ),
                          ],
                        ),
                        
                        // Ending Date (To) - Conditional
                        if (!controller.isPresent.value) ...[
                          SizedBox(height: SizeConfig.size15),
                          CustomText(
                            AppStrings.otherEndingDate.tr,
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor,
                          ),
                          SizedBox(height: SizeConfig.size10),
                          NewDatePicker(
                            selectedDay: controller.toDay.value,
                            selectedMonth: controller.toMonth.value,
                            selectedYear: controller.toYear.value,
                            isAgeValidation15: false,
                            isFutureYear: false,
                            onDayChanged: (value) {
                              controller.toDay.value = value;
                            },
                            onMonthChanged: (value) {
                              controller.toMonth.value = value;
                            },
                            onYearChanged: (value) {
                              controller.toYear.value = value;
                            },
                          ),
                        ],
                        
                        SizedBox(height: SizeConfig.size30),
                      ],
                    );
                  }),
                ),
              ),
            ),
            // Button
            Obx(() => SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35.0,right: 20,left: 20,top: 10),
                child: CustomBtn(
                      onTap: () {
                        if (!controller.isUploading.value) {
                          controller.saveStaff();
                        }
                      },
                      title: controller.editingId == null ? AppStrings.add.tr : AppStrings.update.tr,
                      bgColor: AppColors.primaryColor,
                      textColor: AppColors.white,
                      isLoading: controller.isUploading.value,
                    ),
              ),
            )),
            SizedBox(height: SizeConfig.size20),
          ],
        ),
      ),
    );
  }
}
