import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/others/controller/management_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagementFormScreen extends StatelessWidget {

  final controller = Get.find<ManagementController>();

  ManagementFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: controller.editingId == null ? AppStrings.otherAddMember.tr : AppStrings.otherEditMember.tr,
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
                          onChange: (val) {
                            controller.name.value = val;
                          },
                        ),
                        SizedBox(height: SizeConfig.size15),
                        CommonTextField(
                          title: AppStrings.otherFieldPosition.tr,
                          textEditController: controller.positionController,
                          hintText: AppStrings.otherHintPositionFounder.tr,
                          onChange: (val) {
                            controller.position.value = val;
                          },
                        ),
                        SizedBox(height: SizeConfig.size15),
                        CommonTextField(
                          title: AppStrings.otherFieldQualification.tr,
                          textEditController:
                              controller.qualificationController,
                          hintText: AppStrings.otherHintQualificationPhd.tr,
                          onChange: (val) {
                            controller.qualification.value = val;
                          },
                        ),
                        SizedBox(height: SizeConfig.size15),
                        AiDescriptionField(
                          label: AppStrings.otherFieldMessage.tr,
                          hintText: AppStrings.otherTellAboutManagement.tr,
                          controller: controller.messageController,
                          rxValue: controller.description,
                          // Your RX variable from the controller
                          aiType: "Service Management",
                          aiData: {
                            "name": controller.name.value,
                            "position": controller.position.value,
                            "qualification":
                                controller.qualification.value,
                          },
                        ),
                        SizedBox(height: SizeConfig.size30),
                      ],
                    );
                  }),
                ),
              ),
            ),
            // Keep the button at the bottom for better UX on a full screen
            Obx(() => SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35.0,right: 20,left: 20,top: 10),
                child: CustomBtn(
                      onTap: () {
                        if (!controller.isUploading.value) {
                          controller.saveManagement();
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
