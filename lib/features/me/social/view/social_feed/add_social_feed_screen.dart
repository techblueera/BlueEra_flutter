import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/social/controller/social_feed_controller.dart';
import 'package:BlueEra/features/me/social/model/social_activity_feed_res_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddSocialFeedScreen extends StatefulWidget {
  final bool isEdit;
  final SocialActivityFeedData? departmentData;

  const AddSocialFeedScreen(
      {super.key, this.isEdit = false, this.departmentData});

  @override
  State<AddSocialFeedScreen> createState() => _AddSocialFeedScreenState();
}

class _AddSocialFeedScreenState extends State<AddSocialFeedScreen> {
  final controller = Get.find<SocialFeedController>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  @override
  void initState() {
    controller.selectedImages.clear();
    controller.networkImages.clear();
    controller.deptName.value = "";
    if (widget.isEdit && widget.departmentData != null) {
      controller
          .initEditData(widget.departmentData ?? SocialActivityFeedData());
      nameCtrl.text = controller.deptName.value;
      descCtrl.text = controller.description.value;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.isEdit
              ? AppStrings.editActivityFeed.tr
              : AppStrings.addActivityFeed.tr),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image Upload Section ---
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
                            child: Icon(Icons.photo_library_outlined,
                                color: AppColors.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(AppStrings.uploadImages,
                                    fontWeight: FontWeight.w600,
                                    fontSize: SizeConfig.medium),
                                const SizedBox(height: 2),
                                CustomText("Add up to 5 photos",
                                    color: AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.small),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildImagePicker(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size14),

              // --- Details Section ---
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
                            child: Icon(Icons.edit_note,
                                color: AppColors.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          CustomText("Activity Details",
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CommonTextField(
                        textEditController: nameCtrl,
                        title: AppStrings.title,
                        hintText: "Give your activity a title...",
                        onChange: (v) {
                          controller.deptName.value = v;
                          controller.validateForm(isEdit: widget.isEdit);
                        },
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      Obx(() {
                        return AiDescriptionField(
                          label: AppStrings.description,
                          hintText: "Describe your activity...",
                          controller: descCtrl,
                          rxValue: controller.description,
                          aiType: "Activity Feed",
                          aiData: {"title": controller.deptName.value},
                          onChanged: (val) {
                            controller.validateForm(
                                isEdit: widget.isEdit);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size30),

              // --- Submit Button ---
              Obx(() => CustomBtn(
                    title: widget.isEdit
                        ? AppStrings.update.tr
                        : AppStrings.add.tr,
                    isValidate: controller.isFormValid.value &&
                        !controller.isUploading.value,
                    isLoading: controller.isUploading.value,
                    onTap: controller.isFormValid.value
                        ? () => controller.submitDepartment(
                            isEdit: widget.isEdit,
                            deptId: widget.departmentData?.id ?? "")
                        : null,
                  )),
              SizedBox(height: SizeConfig.size20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...controller.networkImages
                .map((url) => _imageTile(url, isNetwork: true)),
            ...controller.selectedImages
                .map((file) => _imageTile(file.path, isNetwork: false)),
            if ((controller.networkImages.length +
                    controller.selectedImages.length) <
                5)
              GestureDetector(
                onTap: () async {
                  final selectedPath =
                      await CommonImageUploadTile.pickImage(
                          context: context);
                  if (selectedPath != null) {
                    controller.selectedImages.add(File(selectedPath));
                    controller.validateForm(isEdit: widget.isEdit);
                  }
                },
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.primaryColor,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primaryColor
                        .withValues(alpha: 0.05),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primaryColor, size: 24),
                      const SizedBox(height: 4),
                      CustomText("Add",
                          color: AppColors.primaryColor,
                          fontSize: 10),
                    ],
                  ),
                ),
              ),
          ],
        ));
  }

  Widget _imageTile(String path, {required bool isNetwork}) {
    return Stack(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: isNetwork
                ? Image.network(path, fit: BoxFit.cover)
                : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: InkWell(
            onTap: () {
              isNetwork
                  ? controller.networkImages.remove(path)
                  : controller.selectedImages
                      .removeWhere((element) => element.path == path);
              controller.validateForm(isEdit: widget.isEdit);
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
