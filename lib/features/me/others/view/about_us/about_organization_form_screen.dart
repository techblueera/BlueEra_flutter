import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/others/controller/about_organisation_controller.dart';
import 'package:BlueEra/features/me/others/model/about_organisation_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutOrganizationFormScreen extends StatefulWidget {
  final AboutOrganisationData? item;

  const AboutOrganizationFormScreen({super.key, this.item});

  @override
  State<AboutOrganizationFormScreen> createState() =>
      _AboutOrganizationFormScreenState();
}

class _AboutOrganizationFormScreenState
    extends State<AboutOrganizationFormScreen> {
  final controller = Get.find<AboutOrganisationController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.title.value = "";
    controller.description.value = "";
    if (widget.item != null) {
      controller.setFormData(widget.item ?? AboutOrganisationData());
    } else {
      controller.clearForm();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.item == null ? "Add Organization" : "Edit Organization",
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Image Upload
              CustomText(AppStrings.uploadPhotos,
                  fontSize: SizeConfig.medium, fontWeight: FontWeight.w500),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => controller.pickImage(),
                child: Obx(() {
                  return Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.whiteE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: controller.selectedImage.value != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        controller.selectedImage.value!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : (widget.item?.imageUrl != null &&
                        widget.item!.imageUrl!.isNotEmpty)
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.item?.imageUrl ?? "",
                        fit: BoxFit.cover,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LocalAssets(
                            imagePath: AppIconAssets.uploadIcon,
                            height: 24,
                            width: 24),
                        const SizedBox(height: 8),
                        CustomText(
                          "Upload Photo",
                          fontSize: 16,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Title
              CustomText(
                "Title",
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              const SizedBox(height: 8),
              CommonTextField(
                textEditController: controller.titleController,
                hintText: "Enter Title",
                onChange: (val) {
                  controller.title.value = val;
                },
              ),
              const SizedBox(height: 16),
              Obx(() {
                return AiDescriptionField(
                  label: AppStrings.description,
                  hintText: "Tell us more about the organization...",
                  controller: controller.descriptionController,
                  rxValue: controller.description,
                  // Your RX variable from the controller
                  aiType:"Organization",
                  aiData: {
                    "title": controller.title.value,
                  },
                );
              }),


              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.item == null) {
                      controller.createAboutOrganisation();
                    } else {
                      controller.updateAboutOrganisation(widget.item?.sId ?? "",
                          existingImageUrl: widget.item?.imageUrl);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: CustomText(
                    widget.item == null ? "Create" : "Update",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16), // Padding for bottom safe area
            ],
          ),
        ),
      ),
    );
  }
}
