import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:BlueEra/core/constants/app_icon_assets.dart';

class Step3Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step3Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size20),
      child: Column(
        children: [
          Container(
            
            padding: EdgeInsets.all(SizeConfig.size20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                CustomText(
                  'Color',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: SizeConfig.size8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      // Open color picker dialog and add chosen color to the list
                      Color tempColor = controller.selectedColor.value;
                      final bool accepted = await ColorPicker(
                        color: controller.selectedColor.value,
                        onColorChanged: (c) {
                          tempColor = c;
                        },
                        pickersEnabled: const <ColorPickerType, bool>{
                          ColorPickerType.both: true,
                        },
                        heading: const Text('Select color'),
                        subheading: const Text('Select color shade'),
                        showColorName: true,
                        showColorCode: true,
                      ).showPickerDialog(
                        context,
                        constraints: const BoxConstraints(
                          minHeight: 460,
                          minWidth: 300,
                          maxWidth: 360,
                        ),
                        barrierDismissible: true,
                      );
                      if (accepted) {
                        controller.addOrUpdateSelectedColor(tempColor);
                      }
                    },
                    child: Container(
                      height: 45,
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppIconAssets.color_pallate_Icon,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          const CustomText(
                            'Select Color',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          const Spacer(),
                          const Icon(Icons.add, color: AppColors.black),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size12),
                Obx(() {
                  final items = controller.selectedColors;
                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Selected Colors',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Wrap(
                        spacing: SizeConfig.size8,
                        runSpacing: SizeConfig.size8,
                        children: [
                          for (int index = 0; index < items.length; index++)
                            _ColorChip(
                              color: items[index].color,
                              name: items[index].name,
                              hex: items[index].hex,
                              onRemove: () => controller.removeSelectedColorAt(index),
                            ),
                        ],
                      ),
                    ],
                  );
                }),
                
                SizedBox(height: SizeConfig.size12),
                
                // Variant Field
                CustomText(
                  'Material',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  textEditController: controller.variantController,
                  hintText: 'e.g. Cotton, Leather, Metal....',
                  validator: controller.validateVariant,
                  showLabel: false,
                ),
                 SizedBox(height: SizeConfig.size16),
                 Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 CustomText(
                   'Add More Details',
                   fontSize: SizeConfig.medium,
                  //  fontWeight: FontWeight.bold,
                   color: AppColors.black,
                 ),
                 GestureDetector(
                   onTap: controller.openMoreDetailsForStep2,
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
            ),
          ),
          SizedBox(height: SizeConfig.size10),
        Container(
          padding: EdgeInsets.all(SizeConfig.size20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Variant Field
                CustomText(
                  'Types & Variant',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomTextContainer(text: 'Micro',)
                     ,SizedBox(width: SizeConfig.size10),
                    Flexible(
                      child: CommonTextField(
                        textEditController: controller.microsizeController,
                        hintText: 'e.g. 5x7....',
                        validator: controller.validateVariant,
                        showLabel: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomTextContainer(text: 'Small'),
                    SizedBox(width: SizeConfig.size10),
                    Flexible(
                      child: CommonTextField(
                        textEditController: controller.smallsizeController,
                        hintText: 'e.g. 6x9....',
                        validator: controller.validateVariant,
                        showLabel: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomTextContainer(text: 'Medium'),
                    SizedBox(width: SizeConfig.size10),
                    Flexible(
                      child: CommonTextField(
                        textEditController: controller.mediumsizeController,
                        hintText: 'e.g. 8x10....',
                        validator: controller.validateVariant,
                        showLabel: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomTextContainer(text: 'Large'),
                    SizedBox(width: SizeConfig.size10),
                    Flexible(
                      child: CommonTextField(
                        textEditController: controller.largesizeController,
                        hintText: 'e.g. 10x12....',
                        validator: controller.validateVariant,
                        showLabel: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomTextContainer(text: 'Extra Large'),
                    SizedBox(width: SizeConfig.size10),
                    Flexible(
                      child: CommonTextField(
                        textEditController: controller.extralargesizeController,
                        hintText: 'e.g. 12x16....',
                        validator: controller.validateVariant,
                        showLabel: false,
                      ),
                    ),
                  ],
                ),
                 SizedBox(height: SizeConfig.size20),
                Row(
                            children: [
                              // Save as Draft Button
                              Expanded(
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.primaryColor, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: controller.saveAsDraft,
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Center(
                                        child: CustomText(
                                          'Save as draft',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: SizeConfig.size12),
                              // Post Product Button
                              Expanded(
                                  child: CustomBtn(
                                title: controller.currentStep.value ==
                                        ManualListingScreenController.totalSteps
                                    ? 'Submit'
                                    : 'Next',
                                onTap: controller.onNext,
                                bgColor: AppColors.primaryColor,
                                textColor: AppColors.white,
                                height: 45,
                              )),
                            ],
                          )
                 
              ],
            ),
        )
        ],
      ),
    );
  }
}

class CustomTextContainer extends StatelessWidget {
      const CustomTextContainer({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 110,
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12,vertical: SizeConfig.size8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.colorTextDarkGrey.withOpacity(0.4)),
      ),
      child:  CustomText(
                      text,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),);
  }
}

class _ColorChip extends StatelessWidget {
  final Color color;
  final String name;
  final String hex;
  final VoidCallback onRemove;

  const _ColorChip({required this.color, required this.name, required this.hex, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$name · $hex',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
}
