import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../listing_form_screen_controller.dart';

class Step2Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step2Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding:   EdgeInsets.only(top: SizeConfig.size20,bottom: SizeConfig.size20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

             CustomFormCard(
                padding: EdgeInsets.all(SizeConfig.size16),
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              CustomText('${controller.productNameController.text}',
              fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                
                ),
                    SizedBox(height: SizeConfig.size8),
              CustomText(
                '${controller.selectedCategory.value}',
                fontSize: SizeConfig.small,
                // fontWeight: FontWeight.bold,
                color: AppColors.black,
              
              ),
             ],),),
             CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size16),
            child: _buildProductFeaturesSection(controller),
          ),

          CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.size16),
            child: Column(
              children: [
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
                Obx(() {
                  if (controller.moreDetailsStep1.isEmpty)
                    return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CustomText(
                      //   'More Details',
                      //   fontSize: SizeConfig.medium,
                      //   fontWeight: FontWeight.w600,
                      //   color: AppColors.black,
                      // ),
                      SizedBox(height: SizeConfig.size8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.moreDetailsStep1.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: SizeConfig.size8),
                        itemBuilder: (context, index) {
                          final item = controller.moreDetailsStep1[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                item['title'] ?? '',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                              SizedBox(height: SizeConfig.size4),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.secondaryTextColor
                                          .withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.all(SizeConfig.size12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomText(
                                            item['details'] ?? '',
                                            color: AppColors.secondaryTextColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove',
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                      onPressed: () => controller
                                          .removeMoreDetailAtStep1(index),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                }),
             
              ],
            ),
          ),
         
                Container(

                         padding:   EdgeInsets.all(SizeConfig.size4),
      margin:   EdgeInsets.symmetric(vertical: SizeConfig.size5,horizontal: SizeConfig.size20),
                        child: Row(
                            children: [
                              // Create Button (only button before creation)
                              Expanded(
                                child: CustomBtn(
                                  title: 'Create',
                                  onTap: controller.markCreated,
                                  bgColor: AppColors.primaryColor,
                                  textColor: AppColors.white,
                                  height: 45,
                                   radius: 14,
                                ),
                              ),
                            ],
                          ),
                      ),
         
           ],
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
              color: AppColors.black,
            ),
            CustomText(
              'Min-2 / Max-5',
              fontSize: SizeConfig.medium,
              color: AppColors.black,
            ),
          ],
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
            itemCount: 5, // up to 4 images
            itemBuilder: (context, index) {
              final imgIdx = index;
              return GestureDetector(
                key: ValueKey('img_$imgIdx'),
                onTap: () {
                   if(controller.imageLocalPaths.length < 2){
                    Get.snackbar(
                      'Limit reached',
                      'You must upload at least 2 images only.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } 
                  else if (controller.imageLocalPaths.length >= 5) {
                    Get.snackbar(
                      'Limit reached',
                      'You can upload up to 5 images only.',
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
              padding: EdgeInsets.only(bottom: SizeConfig.size10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        //TODO:  here in textfiled for feature i want to make charator limit to max 140 charactors 
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CommonTextField(
                              title: 'Feature ${i + 1}',
                              hintText: 'E.g. Vorem ipsum dolor sit amet,',
                              textEditController: controller.featureControllers[i],
                              maxLine: 2,
                              maxLength: 140,
                            ),
                           Obx(() => CustomText(
                              '${controller.featureCharCounts[i].value}/140',
                              fontSize: SizeConfig.medium,
                              color: AppColors.black,
                            )),
                          ],
                        ),
                      ),
                      // if (controller.featureControllers.length > 2) SizedBox(width: SizeConfig.size8),
                      // if (controller.featureControllers.length > 2)
                      //   Material(
                      //     color: Colors.transparent,
                      //     child: InkWell(
                      //       onTap: () => controller.removeFeature(i),
                      //       borderRadius: BorderRadius.circular(8),
                      //       child: Icon(
                      //         Icons.delete_outline,
                      //         color: AppColors.primaryColor,
                      //         size: 22,
                      //       ),
                      //     ),
                      //   ),
                    ],
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
              CustomText("Add More Feature", color: AppColors.primaryColor),
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
        // CustomText(
        //   'Options',
        //   fontSize: SizeConfig.medium,
        //   fontWeight: FontWeight.bold,
        //   color: AppColors.black,
        // ),
        // SizedBox(height: SizeConfig.size12),
        // Obx(() => Column(
        //   children: List.generate(controller.optionAttributeControllers.length, (i) {
        //     return Padding(
        //       padding: EdgeInsets.only(bottom: SizeConfig.size12),
        //       child: Row(
        //         children: [
        //           Expanded(
        //             child: CommonTextField(
        //               title: 'Attribute',
        //               hintText: 'e.g. Color',
        //               textEditController: controller.optionAttributeControllers[i],
        //             ),
        //           ),
        //           SizedBox(width: SizeConfig.size8),
        //           Expanded(
        //             child: CommonTextField(
        //               title: 'Value',
        //               hintText: 'e.g. Black',
        //               textEditController: controller.optionValueControllers[i],
        //             ),
        //           ),
        //           SizedBox(width: SizeConfig.size8),
        //           if (controller.optionAttributeControllers.length > 1)
        //             Material(
        //               color: Colors.transparent,
        //               child: InkWell(
        //                 onTap: () => controller.removeOption(i),
        //                 borderRadius: BorderRadius.circular(8),
        //                 child: Padding(
        //                   padding: const EdgeInsets.all(8.0),
        //                   child: const Icon(Icons.delete_outline, color: AppColors.primaryColor),
        //                 ),
        //               ),
        //             ),
        //         ],
        //       ),
        //     );
        //   }),
        // )),
        // SizedBox(height: SizeConfig.size8),
        // GestureDetector(
        //   onTap: controller.addOption,
        //   child: Row(
        //     children: [
        //       Image.asset("assets/icons/add_icon.png",
        //           color: AppColors.primaryColor),
        //       SizedBox(width: SizeConfig.size10),
        //       CustomText("Add Option", color: AppColors.primaryColor),
        //     ],
        //   ),
        // ),
        
      ],
    );
  }
}