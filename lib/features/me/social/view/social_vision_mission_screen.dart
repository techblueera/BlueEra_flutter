import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social_vision_mission_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialVisionMissionScreen extends StatelessWidget {
  final controller = Get.put(SocialVisionMissionController());

  SocialVisionMissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.visionMission.tr),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Info Banner ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          AppColors.primaryColor.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: AppColors.primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        AppStrings.socialVisionMissionBanner.tr,
                        color: AppColors.primaryColor,
                        fontSize: SizeConfig.small,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.paddingL),

              // --- Description Section ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.description_outlined,
                                color: AppColors.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(AppStrings.visionMission.tr,
                                    fontWeight: FontWeight.w600,
                                    fontSize: SizeConfig.medium),
                                const SizedBox(height: 2),
                                CustomText(
                                    AppStrings.socialDescribeYourAim.tr,
                                    color: AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.small),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AiDescriptionField(
                        label: "",
                        hintText: AppStrings.socialVisionMissionHint.tr,
                        controller: controller.descriptionController,
                        rxValue: controller.description,
                        aiType: "vision mission",
                        aiData: {
                          "for": "social profile vision mission",
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.paddingL),

              // --- Image Section ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(AppStrings.uploadImages.tr,
                                    fontWeight: FontWeight.w600,
                                    fontSize: SizeConfig.medium),
                                const SizedBox(height: 2),
                                CustomText(
                                    AppStrings.socialVisionImageHint.tr,
                                    color: AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.small),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: InkWell(
                          onTap: controller.pickImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade300),
                              image: _getImageProvider(),
                            ),
                            child: _buildImagePlaceholder(),
                          ),
                        ),
                      ),
                      if (controller.selectedImage.value != null ||
                          controller.serverImageUrl.value != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: controller.removeImage,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: AppColors.red, size: 16),
                                  const SizedBox(width: 4),
                                  CustomText(AppStrings.remove.tr,
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: SizeConfig.small),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.paddingXL),

              // --- Save Button ---
              Obx(() => CustomBtn(
                    onTap:
                        controller.isSaving.value ? null : controller.save,
                    isValidate: !controller.isSaving.value,
                    isLoading: controller.isSaving.value,
                    title: AppStrings.save.tr,
                  )),
              SizedBox(height: SizeConfig.size20),
            ],
          ),
        );
      }),
    );
  }

  DecorationImage? _getImageProvider() {
    if (controller.selectedImage.value != null) {
      return DecorationImage(
        image: FileImage(controller.selectedImage.value!),
        fit: BoxFit.cover,
      );
    } else if (controller.serverImageUrl.value != null &&
        controller.serverImageUrl.value!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(controller.serverImageUrl.value!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget? _buildImagePlaceholder() {
    if (controller.selectedImage.value == null &&
        controller.serverImageUrl.value == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          CustomText(AppStrings.tapToUploadImage.tr,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small),
        ],
      );
    }
    return null;
  }
}
