import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../listing_form_screen_controller.dart';

import '../listing_form_screen_controller.dart';

class Step1Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step1Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMediaUploadSection(controller),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: controller.productNameController,
                  hintText: 'E.g. Wireless Earbuds Boat Airdopes 161',
                  title: "Product Name",
                  validator: controller.validateProductName,
                  showLabel: true,
                ),
                SizedBox(height: SizeConfig.size16),
                Obx(() {
                  return Column(
                    children: List.generate(controller.categoryLevels.length, (i) {
                      final level = controller.categoryLevels[i];
                      final items = level.items.map((e) => e.name).toList();
                      return Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size12),
                        child: _buildDropdownField(
                          label: i == 0 ? 'Category' : 'Subcategory $i',
                          hint: i == 0 ? 'Select a category' : 'Select a subcategory',
                          items: items,
                          validator: (value) => i == 0 && value == null ? 'Please select a category' : null,
                          onChanged: (val) => controller.onLevelChanged(i, val),
                          value: level.selectedName.isEmpty ? null : level.selectedName,
                        ),
                      );
                    }),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    Get.snackbar(
                      'Feature Coming Soon',
                      'New category creation will be available soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomText(
                        "New Category",
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        "+",
                        color: AppColors.primaryColor,
                        fontSize: SizeConfig.size30,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size16),
                _buildTagsSection(controller),
                SizedBox(height: SizeConfig.size16),
              ],
            ),
          ),
          CustomFormCard(
            child: CommonTextField(
              textEditController: controller.productNameController,
              hintText: 'E.g. Samsung',
              title: "Brand ( if any )",
              validator: controller.validateProductName,
              showLabel: true,
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomFormCard(
            child: _buildProductFeaturesSection(controller),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomFormCard(
            child: _buildDescriptionSection(controller),
          ),
          SizedBox(height: SizeConfig.size16),
        ],
      ),
    );
  }

  Widget _buildMediaUploadSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Upload product Video',
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                key: const ValueKey('video'),
                onTap: () {
                  final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
                  if (hasVideo) {
                    Get.snackbar(
                      'Limit reached',
                      'You can upload only one video. Remove the existing one to replace.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    controller.pickVideo();
                  }
                },
                onLongPress: () {
                  final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
                  if (hasVideo) {
                    controller.videoLocalPath.value = null;
                  }
                },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.fillColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.greyE5, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Obx(() {
                    final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasVideo)
                          Container(
                            color: Colors.black12,
                            child: Center(
                              child: Icon(Icons.videocam, color: AppColors.primaryColor.withOpacity(0.9)),
                            ),
                          )
                        else
                          Center(
                            child: Icon(
                              Icons.videocam,
                              color: AppColors.secondaryTextColor.withOpacity(0.3),
                            ),
                          ),
                        if (hasVideo)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => controller.videoLocalPath.value = null,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam, size: 12, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        CustomText(
          'Upload product Images',
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        SizedBox(
          height: 80,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 4, // up to 4 images
            itemBuilder: (context, index) {
              final imgIdx = index;
              return GestureDetector(
                key: ValueKey('img_$imgIdx'),
                onTap: () {
                  if (controller.imageLocalPaths.length >= 4) {
                    Get.snackbar(
                      'Limit reached',
                      'You can upload up to 4 images only.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    controller.pickImages();
                  }
                },
                onLongPress: () {
                  final hasImage = imgIdx < controller.imageLocalPaths.length;
                  if (hasImage) {
                    controller.removeImageAt(imgIdx);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.fillColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.greyE5, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Obx(() {
                    final hasImage = imgIdx < controller.imageLocalPaths.length;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          Image.file(
                            File(controller.imageLocalPaths[imgIdx]),
                            fit: BoxFit.cover,
                          )
                        else
                          Center(
                            child: Icon(
                              Icons.photo,
                              color: AppColors.secondaryTextColor.withOpacity(0.3),
                            ),
                          ),
                        if (hasImage)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => controller.removeImageAt(imgIdx),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo, size: 12, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Short Description',
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: controller.shortDescriptionController,
          hintText: "Lorem ipsum dolor sit amet conseceter adisping...",
          maxLine: 3,
        )
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required List<String> items,
    required String? Function(String?) validator,
    required void Function(String?) onChanged,
    String? value,
  }) {
    final String? effectiveValue = (value != null && items.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: effectiveValue,
              validator: validator,
              onChanged: onChanged,
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.grey9B,
                size: 20,
              ),
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              style: TextStyle(
                color: AppColors.black,
                fontSize: SizeConfig.medium,
              ),
              menuMaxHeight: 200,
              hint: CustomText(
                hint,
                color: AppColors.secondaryTextColor,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: SizeConfig.medium,
                      color: AppColors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Add Tags / Keywords',
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: Row(
            children: [
              Image.asset("assets/icons/tag_icon.png"),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: TextField(
                  controller: controller.tagsController,
                  decoration: const InputDecoration(
                    hintText: 'Tag people',
                    hintStyle: TextStyle(
                      color: AppColors.grey9B,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.addTag,
                  child: Image.asset("assets/icons/add_icon.png"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductFeaturesSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Add Product Features',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size16),
        Obx(() => Column(
          children: List.generate(controller.featureControllers.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CommonTextField(
                      title: 'Feature ${i + 1}',
                      hintText: 'E.g. Vorem ipsum dolor sit amet,',
                      textEditController: controller.featureControllers[i],
                      maxLine: 2,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  if (controller.featureControllers.length > 1)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.removeFeature(i),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.only(top: SizeConfig.size20),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.primaryColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        )),
        SizedBox(height: SizeConfig.size16),
        GestureDetector(
          onTap: controller.addFeature,
          child: Row(
            children: [
              Image.asset("assets/icons/add_icon.png",
                  color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              CustomText("Add More Option", color: AppColors.primaryColor),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        GestureDetector(
          onTap: controller.showLinkField.toggle,
          child: Row(
            children: [
              Image.asset("assets/icons/add_icon.png",
                  color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              CustomText("Add Link (Reference / Website)",
                  color: AppColors.primaryColor),
            ],
          ),
        ),
        Obx(() => controller.showLinkField.value
            ? Padding(
                padding: EdgeInsets.only(top: SizeConfig.size12),
                child: CommonTextField(
                  title: "Link (Reference / Website)",
                  hintText: "https://example.com",
                  textEditController: controller.linkController,
                ),
              )
            : const SizedBox.shrink()),
        SizedBox(height: SizeConfig.size20),
        CustomText(
          'Options',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size12),
        Obx(() => Column(
          children: List.generate(controller.optionAttributeControllers.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size12),
              child: Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      title: 'Attribute',
                      hintText: 'e.g. Color',
                      textEditController: controller.optionAttributeControllers[i],
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CommonTextField(
                      title: 'Value',
                      hintText: 'e.g. Black',
                      textEditController: controller.optionValueControllers[i],
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  if (controller.optionAttributeControllers.length > 1)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.removeOption(i),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(Icons.delete_outline, color: AppColors.primaryColor),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        )),
        SizedBox(height: SizeConfig.size8),
        GestureDetector(
          onTap: controller.addOption,
          child: Row(
            children: [
              Image.asset("assets/icons/add_icon.png",
                  color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              CustomText("Add Option", color: AppColors.primaryColor),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              'Add More Details',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            GestureDetector(
              onTap: controller.toggleMoreDetails,
              child: Container(
                width: 32,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
