import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/others/controller/staff_controller.dart';
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

  final controller = Get.find<StaffController>();

  StaffFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: controller.editingId == null ? "Add Staff" : "Edit Staff",
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
                            dialogTitle: "Upload Picture",
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
                          title: "Name",
                          textEditController: controller.nameController,
                          hintText: "Enter name",
                        ),
                        SizedBox(height: SizeConfig.size15),
                        CommonTextField(
                          title: "Position",
                          textEditController: controller.positionController,
                          hintText: "Enter position (e.g. Designer)",
                        ),
                        SizedBox(height: SizeConfig.size15),
                        CommonTextField(
                          title: "Qualification",
                          textEditController:
                              controller.qualificationController,
                          hintText: "Enter qualification (e.g. Diploma)",
                        ),
                        SizedBox(height: SizeConfig.size15),
                        
                        // Joining Date (From)
                        CustomText(
                          "Joining Date",
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
                              "Present",
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor,
                            ),
                          ],
                        ),
                        
                        // Ending Date (To) - Conditional
                        if (!controller.isPresent.value) ...[
                          SizedBox(height: SizeConfig.size15),
                          CustomText(
                            "Ending Date",
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
                      title: controller.editingId == null ? "Add" : "Update",
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
