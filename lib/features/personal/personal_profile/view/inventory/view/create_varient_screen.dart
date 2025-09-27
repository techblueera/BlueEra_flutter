import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/add_variant_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/color_selection_tile.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/skip_variant_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/submit_varient_dialog.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// On next pop up we will ask to add image (up to 2)
/// Need to aad multiple images slider for product listing


class CreateVariantScreen extends StatefulWidget {
  final AddProductViaAiController controller;
  const CreateVariantScreen({super.key, required this.controller});

  @override
  State<CreateVariantScreen> createState() => _CreateVariantScreenState();
}

class _CreateVariantScreenState extends State<CreateVariantScreen> {
  final Map<int, int> _currentIndices = {};
  final Map<int, CarouselSliderController> _controllers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: 'Create Variant Combination ',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color section (if colors exist)
                  Obx(() {
                    if (widget.controller.selectedColors.isNotEmpty) {
                      return _buildColorSection();
                    }
                    return SizedBox.shrink();
                  }),
                      
                  // Dynamic attributes sections
                  Obx(() {
                    List<Widget> attributeWidgets = [];
                    widget.controller.dynamicAttributes.forEach((key, values) {
                      if (values.isNotEmpty) {
                        attributeWidgets.add(_buildAttributeSection(key, values));
                      }
                    });
                    return Column(children: attributeWidgets);
                  }),

                  // Add More Variant Button
                  _buildAddMoreVariantButton(),
                      
                  SizedBox(height: SizeConfig.size20), // Extra space for bottom buttons

                  // Bottom buttons (fixed at bottom)
                  Obx(() => Row(
                    children: [
                      // Show Skip only if nothing is selected

                      if(widget.controller.listedProducts.isEmpty)
                      if (widget.controller.selectedVariantValues.isEmpty)
                        Expanded(
                          child: PositiveCustomBtn(
                            title: 'Skip',
                            bgColor: AppColors.white,
                            borderColor: AppColors.primaryColor,
                            textColor: AppColors.primaryColor,
                            radius: 10.0,
                            onTap: () {
                              showDialog(
                                context: Get.context!,
                                builder: (context) => SkipVariantDialog(
                                  controller: widget.controller,
                                ),
                              );

                            },
                          ),
                        ),
                      if (widget.controller.selectedVariantValues.isEmpty)
                        SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: PositiveCustomBtn(
                          title: 'Next',
                          bgColor: widget.controller.isNextEnabled.value
                              ? AppColors.primaryColor
                              : AppColors.greyE5,
                          borderColor: widget.controller.isNextEnabled.value
                              ? AppColors.primaryColor
                              : Colors.grey,
                          radius: 10.0,
                          textColor: widget.controller.isNextEnabled.value
                              ? AppColors.white
                              : AppColors.primaryColor,
                          onTap: widget.controller.isNextEnabled.value
                              ? () {
                            showDialog(
                              context: Get.context!,
                              builder: (context) => SubmitVariantDialog(
                                controller: widget.controller,
                              ),
                            );
                          }
                              : () {
                            Get.snackbar(
                                'Error',
                                'Please select each variant to further proceed'
                            );
                          },
                        ),
                      ),
                    ],
                  ))

                ],
              ),
            ),

             Obx(()=>
             widget.controller.listedProducts.isNotEmpty ?
             CustomFormCard(
               margin: EdgeInsets.symmetric(vertical: SizeConfig.size20),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   CustomText(
                     'Listing',
                     fontWeight: FontWeight.bold,
                     fontSize: SizeConfig.large,
                     color: AppColors.mainTextColor,
                   ),
                   SizedBox(height: SizeConfig.size10),
                   ListView.builder(
                     shrinkWrap: true,
                     itemCount: widget.controller.listedProducts.length,
                     physics: NeverScrollableScrollPhysics(),
                     itemBuilder: (context, productIndex) {
                       final product = widget.controller.listedProducts[productIndex];

                       // init default values
                       _currentIndices.putIfAbsent(productIndex, () => 0);
                       _controllers.putIfAbsent(productIndex, () => CarouselSliderController());

                       return Container(
                         margin: EdgeInsets.only(bottom: 16),
                         decoration: BoxDecoration(
                             color: AppColors.whiteFE,
                             borderRadius: BorderRadius.circular(10),
                           border: Border.all(
                             color: AppColors.whiteE5,
                           )
                         ),
                         child: Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [

                             SizedBox(
                               width: 120,
                               height: 120,
                               child: Stack(
                                 children: [
                                   CarouselSlider.builder(
                                     carouselController: _controllers[productIndex],
                                     itemCount: product.image.length,
                                     options: CarouselOptions(
                                       height: 120, 
                                       viewportFraction: 1.0,
                                       enlargeCenterPage: false,
                                       enableInfiniteScroll: false,
                                       onPageChanged: (index, reason) {
                                         setState(() {
                                           _currentIndices[productIndex] = index;
                                         });
                                       },
                                     ),
                                     itemBuilder: (context, imgIndex, realIdx) {
                                       return ClipRRect(
                                         borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
                                         child: Image.file(
                                           File(product.image[imgIndex]),
                                           width: 120,
                                           height: 120,
                                           fit: BoxFit.cover,
                                         ),
                                       );
                                     },

                                   ),

                                   Positioned(
                                     bottom: 6,
                                     left: 0,
                                     right: 0,
                                     child: Row(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: List.generate(product.image.length, (dotIndex) {
                                         final isActive = _currentIndices[productIndex] == dotIndex;
                                         return AnimatedContainer(
                                           duration: const Duration(milliseconds: 300),
                                           margin: const EdgeInsets.symmetric(horizontal: 3.0),
                                           width: isActive ? 8 : 6,
                                           height: isActive ? 8 : 6,
                                           decoration: BoxDecoration(
                                             color: isActive ? AppColors.primaryColor : Colors.grey,
                                             shape: BoxShape.circle,
                                           ),
                                         );
                                       }),
                                     ),
                                   ),
                                 ],
                               ),
                             ),


                             // ClipRRect(
                             //   borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
                             //   child: Container(
                             //     color: AppColors.whiteF1,
                             //     child: Image.file(
                             //       File(product.image[0]),
                             //       width: 120,
                             //       height: 120,
                             //       fit: BoxFit.cover,
                             //     ),
                             //   ),
                             // ),

                             SizedBox(width: 12),
                             Flexible(
                               child: Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 8),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   mainAxisAlignment: MainAxisAlignment.start,
                                   children: [
                                     CustomText(
                                       product.name,
                                       fontWeight: FontWeight.bold,
                                       fontSize: SizeConfig.large,
                                       color: AppColors.mainTextColor,
                                     ),
                                     SizedBox(height: 8),

                                     Row(
                                       children: [
                                         CustomText(
                                           '₹${product.price}',
                                           fontWeight: FontWeight.bold,
                                           fontSize: SizeConfig.large,
                                           color: AppColors.mainTextColor,
                                         ),
                                         SizedBox(width: 8),
                                         CustomText(
                                           '₹${product.mrp}',
                                           fontWeight: FontWeight.bold,
                                           fontSize: SizeConfig.medium,
                                           color: AppColors.secondaryTextColor,
                                           decoration: TextDecoration.lineThrough,
                                         ),
                                         SizedBox(width: 8),
                                         CustomText(
                                           '${product.discount}% off',
                                           fontWeight: FontWeight.bold,
                                           fontSize: SizeConfig.medium,
                                           color: Colors.green,
                                         ),
                                       ],
                                     )

                                     // product.discount != null
                                     //     ? Row(
                                     //   children: [
                                     //     CustomText(
                                     //       '₹${product.price}',
                                     //       fontWeight: FontWeight.bold,
                                     //       fontSize: SizeConfig.large,
                                     //       color: AppColors.mainTextColor,
                                     //     ),
                                     //     SizedBox(width: 8),
                                     //     CustomText(
                                     //       '₹${product.mrp}',
                                     //       fontWeight: FontWeight.bold,
                                     //       fontSize: SizeConfig.medium,
                                     //       color: AppColors.secondaryTextColor,
                                     //       decoration: TextDecoration.lineThrough,
                                     //     ),
                                     //     SizedBox(width: 8),
                                     //     CustomText(
                                     //       '${product.discount}% off',
                                     //       fontWeight: FontWeight.bold,
                                     //       fontSize: SizeConfig.medium,
                                     //       color: Colors.green,
                                     //     ),
                                     //   ],
                                     // ) : Row(
                                     //   children: [
                                     //     CustomText(
                                     //       '₹${product.minPrice}-${product.maxPrice}',
                                     //       fontWeight: FontWeight.bold,
                                     //       fontSize: SizeConfig.large,
                                     //       color: AppColors.secondaryTextColor
                                     //     )
                                     //   ],
                                     // ),
                                   ],
                                 ),
                               ),
                             ),
                             Padding(
                               padding: EdgeInsets.only(top: 8.0),
                               child: PopupMenuButton<String>(
                                 padding: EdgeInsets.zero,
                                 offset: const Offset(-6, 36),
                                 color: AppColors.white,
                                 elevation: 8,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                 onSelected: (value) async {
                                   if (value == 'Delete Variant') {
                                     widget.controller.listedProducts.removeAt(productIndex);
                                   }
                                 },
                                 icon: Icon(Icons.more_vert, color: AppColors.black),
                                 itemBuilder: (context) => popupProductListedVariantMenuItems(),
                               ),
                             ),
                             SizedBox(width: 8),
                           ],
                         ),
                       );
                     },
                   ),

                   SizedBox(height: SizeConfig.size5),
                   CustomBtn(
                     title: widget.controller.isAddProductToInventoryLoading.value
                         ? null // hide text
                         : 'Go to Product Page',
                     bgColor: AppColors.primaryColor,
                     borderColor: AppColors.primaryColor,
                     radius: 10.0,
                     textColor: AppColors.white,
                     onTap: () {
                       widget.controller.addProductToInventory(
                           addProductViaAiController: widget.controller,
                           products: widget.controller.listedProducts
                       );


                       // Get.snackbar(
                       //     'Success',
                       //     'Variant added successfully'
                       // );
                     },
                     isLoading: widget.controller.isAddProductToInventoryLoading.value
                   )
                 ],
               ),
             )
                 : SizedBox()
             )


          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Color',
                style: TextStyle(
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              InkWell(
                onTap: () => _openColorDialog(context),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: AppColors.primaryColor,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add More',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),

          // Color grid
          Obx(
                () => Container(
              width: SizeConfig.screenWidth,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [AppShadows.textFieldShadow],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.whiteE5),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.controller.selectedColors.map((color) {
                  final isSelected = widget.controller.isValueSelected('color', color.name);

                  return InkWell(
                    onTap: () => widget.controller.selectVariantValue('color', color.name),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.lightBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        // border: Border.all(
                        //   color: isSelected ? AppColors.primaryColor : AppColors.grey9A,
                        //   width: 1.5,
                        // ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // ensures container wraps content
                        children: [
                          // Checkbox
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryColor : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primaryColor : AppColors.grey9A,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: isSelected
                                ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 11,
                            )
                                : null,
                          ),
                          SizedBox(width: 6),
                          // Color name
                          CustomText(
                            color.name,
                            fontSize: SizeConfig.medium,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w400,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: 6),
                          // Color indicator
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.greyE5, width: 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          )

        ],
      ),
    );
  }

  Widget _buildAttributeSection(String attributeKey, RxList<String> values) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                attributeKey,
                style: TextStyle(
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              InkWell(
                onTap: () => _openDynamicAttributeDialog(context, attributeKey),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: AppColors.primaryColor,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add More',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size16),

          // Attribute values grid
          Obx(
                () => Container(
                  width: SizeConfig.screenWidth,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [AppShadows.textFieldShadow],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.whiteE5),
                  ),
              child: Wrap(
                spacing: 12, // horizontal spacing
                runSpacing: 12, // vertical spacing
                children: values.map((value) {
                  final isSelected = widget.controller.isValueSelected(attributeKey, value);

                  return InkWell(
                    onTap: () => widget.controller.selectVariantValue(attributeKey, value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.lightBlue : AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // ensures container wraps content
                        children: [
                          // Animated checkbox
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryColor : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? AppColors.primaryColor : AppColors.grey9A,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: isSelected
                                ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 11,
                            )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          // Text value
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: SizeConfig.screenWidth / 3),
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.black,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          )


        ],
      ),
    );
  }

  Widget _buildAddMoreVariantButton() {
    return InkWell(
      onTap: () {
        showDialog(
          context: Get.context!,
          builder: (context) => AddVariantDialog(
            controller: widget.controller,
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.add,
            color: AppColors.primaryColor,
            size: 18,
          ),
          SizedBox(width: 8),
          CustomText(
            'Add More Variant',
            color: AppColors.primaryColor,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }


  void _openColorDialog(BuildContext context) {
    RxList<SelectedColor> selectedColors = <SelectedColor>[].obs;

    showDialog(
      context: context,
      barrierDismissible: true, // closes when tapping outside
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorSelectionTile(
                      controller: widget.controller,
                      onSelectedColor: (color, colorName){
                        if (!selectedColors.any((c) => c.color == color)) {
                          selectedColors.add(SelectedColor(color, colorName));
                        }
                      }
                  ),
                  Obx(() => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(selectedColors.length, (i) {
                        final selected = selectedColors[i];
                        return Chip(
                          backgroundColor: AppColors.lightBlue,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.mainTextColor,
                          ),
                          onDeleted: () {
                            selectedColors.remove(selected);
                          },
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: selected.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${selected.name}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          labelPadding: const EdgeInsets.only(left: 12),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }),
                    ),
                  )),
                  PositiveCustomBtn(
                    onTap: () {
                      for(var selectedColor in selectedColors){
                        widget.controller.addColor(selectedColor.color, selectedColor.name);
                       }
                      Get.back();
                     },
                    title: 'Save',
                    bgColor: AppColors.primaryColor,
                    borderColor: AppColors.primaryColor,
                    radius: 10.0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDynamicAttributeDialog(
      BuildContext context,
      String attributeKey,
      ) {
    // Local temp storage
    List<String> tempValues =
        widget.controller.dynamicAttributes[attributeKey]?.toList() ?? [];

    final textCtrl = TextEditingController();
    String inputText = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Add $attributeKey",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      const SizedBox(height: 12),

                      // Input field
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16,
                          vertical: SizeConfig.size10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          boxShadow: [AppShadows.textFieldShadow],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.greyE5, width: 1),
                        ),
                        child: Row(
                          children: [
                            Image.asset("assets/icons/tag_icon.png"),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(
                              child: TextField(
                                controller: textCtrl,
                                onChanged: (val) => setState(() => inputText = val),
                                decoration: InputDecoration(
                                  hintText: "Add $attributeKey",
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

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: inputText.isNotEmpty
                                  ? InkWell(
                                key: ValueKey("add_$attributeKey"),
                                onTap: () {
                                  if (!tempValues.contains(inputText)) {
                                    setState(() {
                                      tempValues.add(inputText);
                                      inputText = '';
                                      textCtrl.clear();
                                    });
                                  }
                                },
                                child: LocalAssets(
                                  imagePath: AppIconAssets.addBlueIcon,
                                ),
                              )
                                  : SizedBox.shrink(
                                  key: ValueKey("empty_$attributeKey")),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Chips display
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: tempValues.map((val) {
                          return Chip(
                            label: Text(val),
                            backgroundColor: AppColors.lightBlue,
                            labelStyle: TextStyle(
                              fontSize: SizeConfig.size14,
                              color: Colors.black87,
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppColors.mainTextColor,
                            ),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.transparent),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            onDeleted: () => setState(() => tempValues.remove(val)),
                            labelPadding: const EdgeInsets.only(left: 12),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Save button
                      PositiveCustomBtn(
                        onTap: () {
                          // Update main attributes
                          widget.controller.dynamicAttributes[attributeKey] = tempValues.obs;
                          setState(() {});
                          Navigator.pop(context);
                        },
                        title: 'Save',
                        bgColor: AppColors.primaryColor,
                        borderColor: AppColors.primaryColor,
                        radius: 10.0,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<PopupMenuEntry<String>> popupProductListedVariantMenuItems() {
    final items = <Map<String, dynamic>>[
      {'title': 'Delete Variant'},
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['title'],
          child: CustomText(
            items[i]['title'],
            fontSize: SizeConfig.medium,
            color: AppColors.black30,
          ),
        ),
      );

      if (i != items.length - 1) {
        entries.add(
          const PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            height: 1,
            child: Divider(
              indent: 10,
              endIndent: 10,
              height: 1,
              thickness: 0.2,
              color: AppColors.grey99,
            ),
          ),
        );
      }
    }

    return entries;
  }


}

