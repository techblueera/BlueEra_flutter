import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/others/controller/other_news_controller.dart';
import 'package:BlueEra/features/me/others/model/other_news_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherNewsFormScreen extends StatefulWidget {
  final OtherNewsData? item;

  const OtherNewsFormScreen({super.key, this.item});

  @override
  State<OtherNewsFormScreen> createState() =>
      _OtherNewsFormScreenState();
}

class _OtherNewsFormScreenState
    extends State<OtherNewsFormScreen> {
  final controller = Get.find<OtherNewsController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.title.value = "";
    controller.description.value = "";
    if (widget.item != null) {
      controller.setFormData(widget.item ?? OtherNewsData());
    } else {
      controller.clearForm();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.item == null ? "Add News" : "Edit News",
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
                onTap: () => controller.pickImage(context),
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
                  label: "News",
                  hintText: "Tell us more about the News...",
                  controller: controller.descriptionController,
                  rxValue: controller.description,
                  // Your RX variable from the controller
                  aiType: "News",
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
                      controller.createNewsRepo();
                    } else {
                      controller.updateNewsRepo(widget.item?.sId ?? "",
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
