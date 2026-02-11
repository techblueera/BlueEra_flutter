
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social_vision_mission_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialVisionMissionScreen extends StatelessWidget {
  final controller = Get.put(SocialVisionMissionController());

  @override
  Widget build(BuildContext context) {
    // Ensure SizeConfig is initialized
    // SizeConfig.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: "Mission & Vision",
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiDescriptionField(
                label: "Our Vision & Mission",
                hintText: "Tell us more about the Our Vision & Mission...",
                controller: controller.descriptionController,
                rxValue: controller.description,
                // Your RX variable from the controller
                aiType: "vision mission",
                aiData: {
                  "for": "social profile vision mission",
                },
              ),
              SizedBox(height: SizeConfig.paddingL),

              CustomText(
                "Upload Image",
                fontSize: SizeConfig.medium,
              ),
              SizedBox(height: SizeConfig.paddingXS),

              // Image Picker Area
              Center(
                child: InkWell(
                  onTap: controller.pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: _getImageProvider(),
                    ),
                    child: _buildImagePlaceholder(),
                  ),
                ),
              ),

              if (controller.selectedImage.value != null ||
                  controller.serverImageUrl.value != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: controller.removeImage,
                      child: CustomText("Remove Image",
                          color: AppColors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              SizedBox(height: SizeConfig.paddingXL),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value ? null : controller.save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isSaving.value
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : CustomText(
                          "Save Changes",
                          color: Colors.white,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.bold,
                        ),
                ),
              ),
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
              size: 48, color: Colors.grey),
          SizedBox(height: 8),
          CustomText("Tap to upload image",
              color: AppColors.secondaryTextColor),
        ],
      );
    }
    return null;
  }
}
