import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../listing_form_screen_controller.dart';

class Step1Section extends StatelessWidget {
  final ManualListingScreenController controller;

  const Step1Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.whiteF3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          margin: EdgeInsets.all(SizeConfig.size15),
          padding: EdgeInsets.all(SizeConfig.size15),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10.0),
            // boxShadow: [AppShadows.textFieldShadow],
          ),
          child: Form(
            key: controller.formKeyStep1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Product Images
                    _buildMediaUploadSection(controller),

                    SizedBox(height: SizeConfig.size15),

                    /// Product Name
                    CommonTextField(
                      textEditController: controller.productNameController,
                      hintText: 'E.g. Wireless Earbuds Boat Airdopes 161',
                      title: "Product Name",
                      validator: controller.validateProductName,
                      showLabel: true,
                      maxLength: 360,
                      isCounterVisible: true
                    ),
                    SizedBox(height: SizeConfig.size15),

                    /// category
                    CustomText(
                      'Category',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Obx(() => InkWell(
                          onTap: () =>
                              controller.openCategoryBottomSheet(context),
                          child: Container(
                            width: SizeConfig.screenWidth,
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                boxShadow: [AppShadows.textFieldShadow],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.greyE5,
                                )),
                            child: controller.selectedBreadcrumb.value != null
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.only(left: SizeConfig.size12),
                                      constraints: BoxConstraints(
                                        maxWidth: SizeConfig.screenWidth * 0.7,
                                      ),
                                      // width: SizeConfig.screenWidth * 0.5,
                                      child: Wrap(
                                          children: List.generate(
                                            controller.selectedBreadcrumb.value!.length,
                                            (i) {
                                              final item = controller.breadcrumb[i];

                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CustomText(
                                                    item['name'],
                                                      fontSize:  SizeConfig.medium,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.black
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          controller.selectedBreadcrumb.value = null;
                                        },
                                        icon: Icon(Icons.close,
                                    size: 20, color: AppColors.grey9A)
                                    )
                                  ],
                                )
                                : Container(
                                   padding: EdgeInsets.all(SizeConfig.size12),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CustomText(
                                          'Select a category',
                                          color: AppColors.grey9A,
                                          fontWeight: FontWeight.w400,
                                          fontSize: SizeConfig.large,
                                        ),
                                        const Icon(Icons.arrow_forward_ios,
                                            size: 16, color: AppColors.grey9A)
                                      ],
                                    ),
                                ),
                          ),
                        )),

                    // return Column(
                    //   children: List.generate(controller.categoryLevels.length, (i) {
                    //     final level = controller.categoryLevels[i];
                    //     final items = level.items.map((e) => e.name).toList();
                    //     return Padding(
                    //       padding: EdgeInsets.only(bottom: SizeConfig.size12),
                    //       child: _buildDropdownField(
                    //         label: i == 0 ? 'Category' : 'Subcategory $i',
                    //         hint: i == 0 ? 'Select a category' : 'Select a subcategory',
                    //         items: items,
                    //         validator: (value) => i == 0 && value == null ? 'Please select a category' : null,
                    //         onChanged: (val) => controller.onLevelChanged(i, val),
                    //         value: level.selectedName.isEmpty ? null : level.selectedName,
                    //       ),
                    //     );
                    //   }),
                    // );
                    // GestureDetector(
                    //   onTap: () {
                    //     Get.snackbar(
                    //       'Feature Coming Soon',
                    //       'New category creation will be available soon',
                    //       snackPosition: SnackPosition.BOTTOM,
                    //     );
                    //   },
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.end,
                    //     children: [
                    //       CustomText(
                    //         "New Category",
                    //         color: AppColors.primaryColor,
                    //       ),
                    //       SizedBox(width: SizeConfig.size4),
                    //       CustomText(
                    //         "+",
                    //         color: AppColors.primaryColor,
                    //         fontSize: SizeConfig.size30,
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    SizedBox(height: SizeConfig.size15),

                    /// Brand
                    CommonTextField(
                      textEditController: controller.brandController,
                      hintText: 'E.g. Samsung',
                      title: "Brand ( if any )",
                      validator: controller.validateBrandName,
                      showLabel: true,
                      maxLength: 30,
                      isCounterVisible: true
                    ),
                    SizedBox(height: SizeConfig.size15),

                    /// Tag Keywords
                    _buildTagsSection(controller),
                    SizedBox(height: SizeConfig.size15),

                    /// Product Description
                    CommonTextField(
                      textEditController: controller.shortDescriptionController,
                      hintText:
                          "Lorem ipsum dolor sit amet conseceter adisping...",
                      maxLine: 5,
                      title: 'Product Description',
                      validator: controller.validateProductDescription,
                      maxLength: 600,
                      isCounterVisible: true
                    )
                  ],
                ),

                SizedBox(height: SizeConfig.size30),

                CustomBtn(
                  title: 'Next',
                  onTap: controller.onNext,
                  bgColor: AppColors.primaryColor,
                  textColor: AppColors.white,
                  height: SizeConfig.size40,
                  radius: 10.0,
                ),

                // CustomFormCard(
                //   child: CommonTextField(
                //     textEditController: controller.productNameController,
                //     hintText: 'E.g. Samsung',
                //     title: "Brand ( if any )",
                //     validator: controller.validateProductName,
                //     showLabel: true,
                //   ),
                // ),
                // SizedBox(height: SizeConfig.size16),
                // CustomFormCard(
                //   child: _buildProductFeaturesSection(controller),
                // ),
                // SizedBox(height: SizeConfig.size16),
                // CustomFormCard(
                //   child: _buildDescriptionSection(controller),
                // ),
                // SizedBox(height: SizeConfig.size16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaUploadSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CustomText(
        //   'Upload product Video',
        //   fontSize: SizeConfig.medium,
        //   color: AppColors.black,
        // ),
        // SizedBox(height: SizeConfig.size8),
        // SizedBox(
        //   height: 80,
        //   child: ListView(
        //     scrollDirection: Axis.horizontal,
        //     children: [
        //       GestureDetector(
        //         key: const ValueKey('video'),
        //         onTap: () {
        //           final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
        //           if (hasVideo) {
        //             Get.snackbar(
        //               'Limit reached',
        //               'You can upload only one video. Remove the existing one to replace.',
        //               snackPosition: SnackPosition.BOTTOM,
        //             );
        //           } else {
        //             controller.pickVideo();
        //           }
        //         },
        //         onLongPress: () {
        //           final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
        //           if (hasVideo) {
        //             controller.videoLocalPath.value = null;
        //           }
        //         },
        //         child: Container(
        //           width: 80,
        //           decoration: BoxDecoration(
        //             color: AppColors.fillColor,
        //             borderRadius: BorderRadius.circular(8),
        //             border: Border.all(color: AppColors.greyE5, width: 1),
        //           ),
        //           clipBehavior: Clip.antiAlias,
        //           child: Obx(() {
        //             final hasVideo = controller.videoLocalPath.value != null && controller.videoLocalPath.value!.isNotEmpty;
        //             return Stack(
        //               fit: StackFit.expand,
        //               children: [
        //                 if (hasVideo)
        //                   Container(
        //                     color: Colors.black12,
        //                     child: Center(
        //                       child: Icon(Icons.videocam, color: AppColors.primaryColor.withOpacity(0.9)),
        //                     ),
        //                   )
        //                 else
        //                   Center(
        //                     child: Icon(
        //                       Icons.videocam,
        //                       color: AppColors.secondaryTextColor.withOpacity(0.3),
        //                     ),
        //                   ),
        //                 if (hasVideo)
        //                   Positioned(
        //                     top: 4,
        //                     right: 4,
        //                     child: GestureDetector(
        //                       onTap: () => controller.videoLocalPath.value = null,
        //                       child: Container(
        //                         width: 22,
        //                         height: 22,
        //                         decoration: const BoxDecoration(
        //                           color: Colors.black54,
        //                           shape: BoxShape.circle,
        //                         ),
        //                         child: const Icon(Icons.close, size: 14, color: Colors.white),
        //                       ),
        //                     ),
        //                   ),
        //                 Positioned(
        //                   right: 4,
        //                   bottom: 4,
        //                   child: Container(
        //                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        //                     decoration: BoxDecoration(
        //                       color: Colors.black54,
        //                       borderRadius: BorderRadius.circular(10),
        //                     ),
        //                     child: const Row(
        //                       mainAxisSize: MainAxisSize.min,
        //                       children: [
        //                         Icon(Icons.videocam, size: 12, color: Colors.white70),
        //                       ],
        //                     ),
        //                   ),
        //                 ),
        //               ],
        //             );
        //           }),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // SizedBox(height: SizeConfig.size16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              'Upload product Images',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
            SizedBox(width: SizeConfig.size8),
            CustomText(
              'Min-2 / Max-5',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size10),
        SizedBox(
          height: SizeConfig.size80,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              final imgIdx = index;
              return GestureDetector(
                key: ValueKey('img_$imgIdx'),
                onTap: () {
                  if (controller.imageLocalPaths.length >= 5) {
                    commonSnackBar(
                        message: 'Limit reached\nYou can upload up to 4 images only.',
                    );

                    // Get.snackbar(
                    //   'Limit reached',
                    //   'You can upload up to 4 images only.',
                    //   snackPosition: SnackPosition.BOTTOM,
                    // );
                  } else {
                    controller.pickImages(context);
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
                    color: AppColors.whiteFE,
                    borderRadius: BorderRadius.circular(6.0),
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
                              Icons.photo_outlined,
                              color:
                                  AppColors.secondaryTextColor.withValues(alpha: 0.3),
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
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        // Positioned(
                        //   right: 4,
                        //   bottom: 4,
                        //   child: Container(
                        //     padding: const EdgeInsets.symmetric(
                        //         horizontal: 6, vertical: 2),
                        //     decoration: BoxDecoration(
                        //       color: Colors.black54,
                        //       borderRadius: BorderRadius.circular(10),
                        //     ),
                        //     child: const Row(
                        //       mainAxisSize: MainAxisSize.min,
                        //       children: [
                        //         Icon(Icons.photo,
                        //             size: 12, color: Colors.white70),
                        //       ],
                        //     ),
                        //   ),
                        // ),
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
        CommonTextField(
          textEditController: controller.shortDescriptionController,
          hintText: "Lorem ipsum dolor sit amet conseceter adisping...",
          maxLine: 3,
          title: 'Short Description',
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
    final String? effectiveValue =
        (value != null && items.contains(value)) ? value : null;

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
                  onChanged: (_) => controller.update(["addIcon"]),
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
              GetBuilder<ManualListingScreenController>(
                id: "addIcon",
                builder: (_) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: controller.tagsController.text.isNotEmpty
                        ? InkWell(
                            key: const ValueKey("add"),
                            onTap: () {
                              controller.addTag();
                              controller.update(["addIcon"]);
                              unFocus();
                            },
                            child: LocalAssets(
                              imagePath: AppIconAssets.addBlueIcon,
                              // imgColor: AppColors.grey9A
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey("empty")),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(()=> Wrap(
          spacing: 8,
          runSpacing: 2,
          children: controller.tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: AppColors.lightBlue,
              labelStyle: TextStyle(
                  fontSize: SizeConfig.size14,
                  color: Colors.black87
              ),
              deleteIcon: const Icon(Icons.close,
                  size: 20, color: AppColors.mainTextColor),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(8.0)),
              onDeleted: () => controller.removeTag(tag),
              labelPadding: const EdgeInsets.only(left: 12),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ))

      ],
    );
  }

}
