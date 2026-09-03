import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_blogs_controller.dart';
import 'package:BlueEra/features/me/others/model/other_blogs_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherBlogsFormScreen extends StatefulWidget {
  final OtherBlogsData? item;

  const OtherBlogsFormScreen({super.key, this.item});

  @override
  State<OtherBlogsFormScreen> createState() => _OtherBlogsFormScreenState();
}

class _OtherBlogsFormScreenState extends State<OtherBlogsFormScreen> {
  final controller = Get.find<AutomotiveBlogsController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.title.value = "";
    controller.description.value = "";
    if (widget.item != null) {
      controller.setFormData(widget.item ?? OtherBlogsData());
    } else {
      controller.clearForm();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.item == null
            ? AppStrings.otherAddBlogs.tr
            : AppStrings.otherEditBlogs.tr,
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
                      color: AppColors.whiteF3,
                      border: Border.all(color: AppColors.whiteE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: controller.selectedImage.value != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              controller.selectedImage.value!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : (widget.item?.imageUrl != null &&
                                widget.item!.imageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.item?.imageUrl ?? "",
                                  fit: BoxFit.contain,
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
                                    AppStrings.otherUploadPhoto.tr,
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
                AppStrings.title.tr,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              const SizedBox(height: 8),
              CommonTextField(
                textEditController: controller.titleController,
                hintText: AppStrings.enterTitle.tr,
                onChange: (val) {
                  controller.title.value = val;
                },
              ),
              const SizedBox(height: 16),
              Obx(() {
                return AiDescriptionField(
                  label: AppStrings.otherBlogLabel.tr,
                  hintText: AppStrings.otherTellAboutBlogs.tr,
                  controller: controller.descriptionController,
                  rxValue: controller.description,
                  // Your RX variable from the controller
                  aiType: "Blog",
                  aiData: {
                    "for": "Add Blogs",
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
                      controller.createBlogRepo();
                    } else {
                      controller.updateBlogRepo(widget.item?.sId ?? "",
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
                    widget.item == null
                        ? AppStrings.create.tr
                        : AppStrings.update.tr,
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
