import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/widgets/color_picker_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Step4Section extends StatefulWidget {
  final ManualListingScreenController controller;
  Step4Section({Key? key, required this.controller}) : super(key: key);

  @override
  State<Step4Section> createState() => _Step4SectionState();
}

class _Step4SectionState extends State<Step4Section> {
  late final ManualListingScreenController manualListingScreenController;

  // Store original values for restoration
  late List<SelectedColor> originalColors;
  late Map<String, List<String>> originalDynamicAttributes;

  @override
  void initState() {
    super.initState();
    manualListingScreenController = widget.controller;
    manualListingScreenController.variantSizes.keys.forEach((key) {
      manualListingScreenController.variantNameControllers[key] = TextEditingController(text: key);
    });

    // Store original values
    _storeOriginalValues();
  }

  void _storeOriginalValues() {
    // Deep copy of selected colors
    originalColors = List<SelectedColor>.from(
        manualListingScreenController.selectedColors.map((color) =>
            SelectedColor(color.color, color.name)
        )
    );

    // Deep copy of dynamic attributes
    originalDynamicAttributes = <String, List<String>>{};
    manualListingScreenController.dynamicAttributes.forEach((key, value) {
      originalDynamicAttributes[key] = List<String>.from(value);
    });
  }

  void _restoreOriginalValues() {
    // Restore colors
    manualListingScreenController.selectedColors.clear();
    manualListingScreenController.selectedColors.addAll(
        originalColors.map((color) => SelectedColor(color.color, color.name))
    );

    // Restore materials
    manualListingScreenController.materials.clear();
    manualListingScreenController.materialController.clear();

    // Restore dynamic attributes
    manualListingScreenController.dynamicAttributes.clear();
    originalDynamicAttributes.forEach((key, value) {
      manualListingScreenController.dynamicAttributes[key] = List<String>.from(value).obs;
    });

    // Clear dynamic controllers
    manualListingScreenController.dynamicControllers.forEach((key, controller) {
      controller.clear();
    });
  }

  Future<bool> _handleBackPress(BuildContext context) async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Do you really want to go back? Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () {
              // Restore original values when user cancels
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldPop ?? false) {
      _restoreOriginalValues();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _handleBackPress(context);
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteF3,
        appBar: CommonBackAppBar(
          title: 'Product Variant',
          onBackTap: () async {
            final shouldPop = await _handleBackPress(context);
            if (shouldPop) {
              Navigator.of(context).pop();
            }
          },
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
                      _buildColorSection(context),

                      // For dynamic attributes like size, style, etc.
                      if(widget.controller.dynamicAttributes.isNotEmpty)
                      ...[
                        SizedBox(height: SizeConfig.size15),
                        for (var key in widget.controller.dynamicAttributes.keys)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                            child: _buildDynamicAttributeSection(
                              widget.controller,
                              key,
                              'Enter $key...',
                            ),
                          ),
                      ],


                      SizedBox(height: SizeConfig.size30),

                      // Bottom Buttons
                      PositiveCustomBtn(
                        onTap: ()=> Get.back(),
                        // onTap: widget.controller.onNext,
                        title: 'Save',
                        bgColor: AppColors.primaryColor,
                        borderColor: AppColors.primaryColor,
                      ),
                    ],
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ColorPickerWidget(
        onColorSelected: (color, colorName) {
          widget.controller.addColor(color, colorName);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildColorSection(BuildContext context){
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Color',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size8),

          // Color Selection Container
          InkWell(
            onTap: () => _showColorPicker(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [AppShadows.textFieldShadow],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.greyE5,
                  )
              ),
              child: Row(
                children: [
                  LocalAssets(imagePath: AppIconAssets.colorTemplateIcon),
                  SizedBox(width: SizeConfig.size8),
                  CustomText(
                    'Select Color',
                    color: AppColors.grey9A,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                  Spacer(),
                  LocalAssets(
                      imagePath: AppIconAssets.addBlueIcon,
                      imgColor: AppColors.grey9A
                  ),
                ],
              ),
            ),
          ),

          Obx(() => Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(widget.controller.selectedColors.length, (i) {
                final selected = widget.controller.selectedColors[i];
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
                  onDeleted: () => widget.controller.removeColor(selected),
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
          ))
        ]
    );
  }

  Widget _buildMaterialSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Material (Other text format variant)',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
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
                  controller: controller.materialController,
                  onChanged: (_) => controller.update(["addMaterialIcon"]),
                  decoration: const InputDecoration(
                    hintText: 'E.g. Cotton, Leather, Metal, Plastic...',
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
                id: "addMaterialIcon",
                builder: (_) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: controller.materialController.text.isNotEmpty
                        ? InkWell(
                      key: const ValueKey("add"),
                      onTap: () {
                        controller.addMaterial();
                        controller.update(["addMaterialIcon"]);
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
          children: controller.materials.map((tag) {
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
              onDeleted: () => controller.removeMaterial(tag),
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

  Widget _buildDynamicAttributeSection(
      ManualListingScreenController controller,
      String attributeKey, // e.g., "size", "style"
      String hintText,
      ) {
    controller.dynamicControllers.putIfAbsent(attributeKey, () => TextEditingController());
    controller.dynamicAttributes.putIfAbsent(attributeKey, () => <String>[].obs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          '$attributeKey (Other variant)',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
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
                  controller: controller.dynamicControllers[attributeKey],
                  onChanged: (_) => controller.update([attributeKey]),
                  decoration: InputDecoration(
                    hintText: hintText,
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
                id: attributeKey,
                builder: (_) {
                  final text = controller.dynamicControllers[attributeKey]!.text;
                  return AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: text.isNotEmpty
                        ? InkWell(
                      key: ValueKey("add_$attributeKey"),
                      onTap: () {
                        controller.addDynamicValue(attributeKey, text);
                        unFocus();
                      },
                      child: LocalAssets(
                        imagePath: AppIconAssets.addBlueIcon,
                      ),
                    )
                        : SizedBox.shrink(key: ValueKey("empty_$attributeKey")),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 2,
          children: controller.dynamicAttributes[attributeKey]!
              .map((tag) => Chip(
            label: Text(tag),
            backgroundColor: AppColors.lightBlue,
            labelStyle: TextStyle(
                fontSize: SizeConfig.size14, color: Colors.black87),
            deleteIcon: Icon(Icons.close,
                size: 20, color: AppColors.mainTextColor),
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(8.0)),
            onDeleted: () =>
                controller.removeDynamicValue(attributeKey, tag),
            labelPadding: EdgeInsets.only(left: 12),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ))
              .toList(),
        )),
      ],
    );
  }
}

// class ProductVariant {
//   String? colorName;
//   String? colorCode;
//   Color? colorValue;
//   String? material;
//   Map<String, String> otherAttributes; // For size, style, etc.
//
//   ProductVariant({
//     this.colorName,
//     this.colorCode,
//     this.colorValue,
//     this.material,
//     this.otherAttributes = const {},
//   });
// }
//
// class Step4Section extends StatefulWidget {
//   final ManualListingScreenController controller;
//   Step4Section({Key? key, required this.controller}) : super(key: key);
//
//   @override
//   State<Step4Section> createState() => _Step4SectionState();
// }
//
// class _Step4SectionState extends State<Step4Section> {
//   late final ManualListingScreenController manualListingScreenController;
//
//   // Store original values for restoration
//   late List<SelectedColor> originalColors;
//   late List<String> originalMaterials;
//   late Map<String, List<String>> originalDynamicAttributes;
//
//   @override
//   void initState() {
//     super.initState();
//     manualListingScreenController = widget.controller;
//     manualListingScreenController.variantSizes.keys.forEach((key) {
//       manualListingScreenController.variantNameControllers[key] = TextEditingController(text: key);
//       manualListingScreenController.isEditingMap[key] = false;
//     });
//
//     // Store original values
//     _storeOriginalValues();
//   }
//
//   void _storeOriginalValues() {
//     // Deep copy of selected colors
//     originalColors = List<SelectedColor>.from(
//         manualListingScreenController.selectedColors.map((color) =>
//             SelectedColor(color.color, color.name)
//         )
//     );
//
//     // Deep copy of materials
//     originalMaterials = List<String>.from(manualListingScreenController.materials);
//
//     // Deep copy of dynamic attributes
//     originalDynamicAttributes = <String, List<String>>{};
//     manualListingScreenController.dynamicAttributes.forEach((key, value) {
//       originalDynamicAttributes[key] = List<String>.from(value);
//     });
//   }
//
//   void _restoreOriginalValues() {
//     // Restore colors
//     manualListingScreenController.selectedColors.clear();
//     manualListingScreenController.selectedColors.addAll(
//         originalColors.map((color) => SelectedColor(color.color, color.name))
//     );
//
//     // Restore materials
//     manualListingScreenController.materials.clear();
//     manualListingScreenController.materials.addAll(originalMaterials);
//     manualListingScreenController.materialController.clear();
//
//     // Restore dynamic attributes
//     manualListingScreenController.dynamicAttributes.clear();
//     originalDynamicAttributes.forEach((key, value) {
//       manualListingScreenController.dynamicAttributes[key] = List<String>.from(value).obs;
//     });
//
//     // Clear dynamic controllers
//     manualListingScreenController.dynamicControllers.forEach((key, controller) {
//       controller.clear();
//     });
//   }
//
//   Future<bool> _handleBackPress(BuildContext context) async {
//     final shouldPop = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Discard changes?'),
//         content: const Text('Do you really want to go back? Unsaved changes will be lost.'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               // Restore original values when user cancels
//               Navigator.of(context).pop(false);
//             },
//             child: const Text('No'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     );
//
//     if (shouldPop ?? false) {
//       _restoreOriginalValues();
//       return true;
//     }
//     return false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, result) async {
//         if (didPop) return;
//
//         final shouldPop = await _handleBackPress(context);
//         if (shouldPop) {
//           Navigator.of(context).pop();
//         }
//       },
//       child: Scaffold(
//         backgroundColor: AppColors.whiteF3,
//         appBar: CommonBackAppBar(
//           title: 'Product Variant',
//           onBackTap: () async {
//             final shouldPop = await _handleBackPress(context);
//             if (shouldPop) {
//               Navigator.of(context).pop();
//             }
//           },
//         ),
//         body: SingleChildScrollView(
//           padding: EdgeInsets.all(SizeConfig.size15),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               CustomFormCard(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildColorSection(context),
//                       SizedBox(height: SizeConfig.size15),
//                       _buildMaterialSection(widget.controller),
//
//                       // For dynamic attributes like size, style, etc.
//                       if(widget.controller.dynamicAttributes.isNotEmpty)
//                         ...[
//                           SizedBox(height: SizeConfig.size15),
//                           for (var key in widget.controller.dynamicAttributes.keys)
//                             Padding(
//                               padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
//                               child: _buildDynamicAttributeSection(
//                                 widget.controller,
//                                 key,
//                                 'Enter $key...',
//                               ),
//                             ),
//                         ],
//
//
//                       SizedBox(height: SizeConfig.size30),
//
//                       // Bottom Buttons
//                       PositiveCustomBtn(
//                         onTap: ()=> Get.back(),
//                         // onTap: widget.controller.onNext,
//                         title: 'Save',
//                         bgColor: AppColors.primaryColor,
//                         borderColor: AppColors.primaryColor,
//                       ),
//                     ],
//                   )
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Update your Step4Section to show variant cards
//   Widget _buildProductVariantCards() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomText(
//           'Product Variants',
//           fontSize: SizeConfig.medium,
//           fontWeight: FontWeight.w500,
//           color: AppColors.black,
//         ),
//         SizedBox(height: SizeConfig.size15),
//
//         // Display existing variants
//         Obx(() => Column(
//           children: List.generate(
//             widget.controller.productVariant.length,
//                 (index) => _buildVariantCard(
//                 widget.controller.productVariant[index],
//                 index
//             ),
//           ),
//         )),
//
//         SizedBox(height: SizeConfig.size15),
//
//         // Add More Variant Button
//         InkWell(
//           onTap: _showAddVariantDialog,
//           child: Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: SizeConfig.size16,
//               vertical: SizeConfig.size12,
//             ),
//             decoration: BoxDecoration(
//               color: AppColors.white,
//               border: Border.all(
//                 color: AppColors.primaryColor,
//                 width: 1.5,
//               ),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.add,
//                   color: AppColors.primaryColor,
//                   size: 20,
//                 ),
//                 SizedBox(width: SizeConfig.size8),
//                 CustomText(
//                   'Add More Variant',
//                   color: AppColors.primaryColor,
//                   fontWeight: FontWeight.w600,
//                   fontSize: SizeConfig.medium,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
// // Individual variant card widget
//   Widget _buildVariantCard(ProductVariant variant, int index) {
//     return Container(
//       margin: EdgeInsets.only(bottom: SizeConfig.size12),
//       padding: EdgeInsets.all(SizeConfig.size12),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppColors.greyE5),
//         boxShadow: [AppShadows.textFieldShadow],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header with delete button
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               CustomText(
//                 'Variant ${index + 1}',
//                 fontSize: SizeConfig.medium,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.black,
//               ),
//               InkWell(
//                 onTap: () => _removeVariant(index),
//                 child: Icon(
//                   Icons.delete_outline,
//                   color: AppColors.red,
//                   size: 20,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: SizeConfig.size8),
//
//           // Color section
//           if (variant.colorName != null && variant.colorValue != null)
//             Padding(
//               padding: EdgeInsets.only(bottom: SizeConfig.size8),
//               child: Row(
//                 children: [
//                   CustomText(
//                     'Color: ',
//                     fontSize: SizeConfig.small,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.secondaryTextColor,
//                   ),
//                   Container(
//                     width: 16,
//                     height: 16,
//                     margin: EdgeInsets.only(right: 8),
//                     decoration: BoxDecoration(
//                       color: variant.colorValue,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 1),
//                     ),
//                   ),
//                   CustomText(
//                     variant.colorName!,
//                     fontSize: SizeConfig.small,
//                     color: AppColors.secondaryTextColor,
//                   ),
//                 ],
//               ),
//             ),
//
//           // Material section
//           if (variant.material != null)
//             Padding(
//               padding: EdgeInsets.only(bottom: SizeConfig.size8),
//               child: Row(
//                 children: [
//                   CustomText(
//                     'Material: ',
//                     fontSize: SizeConfig.small,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.secondaryTextColor,
//                   ),
//                   CustomText(
//                     variant.material!,
//                     fontSize: SizeConfig.small,
//                     color: AppColors.secondaryTextColor,
//                   ),
//                 ],
//               ),
//             ),
//
//           // Other attributes
//           if (variant.otherAttributes.isNotEmpty)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: variant.otherAttributes.entries.map((entry) {
//                 return Padding(
//                   padding: EdgeInsets.only(bottom: SizeConfig.size4),
//                   child: Row(
//                     children: [
//                       CustomText(
//                         '${entry.key}: ',
//                         fontSize: SizeConfig.small,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.secondaryTextColor,
//                       ),
//                       CustomText(
//                         entry.value,
//                         fontSize: SizeConfig.small,
//                         color: AppColors.secondaryTextColor,
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void _showAddVariantDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Add New Variant'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CustomText(
//                   'Use the form below to add colors, materials, and other attributes for this variant.',
//                   fontSize: SizeConfig.small,
//                   color: AppColors.secondaryTextColor,
//                 ),
//                 SizedBox(height: SizeConfig.size16),
//
//                 // You can add form fields here for manual variant creation
//                 // or redirect to a new screen
//
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 // Navigate to variant creation screen or show bottom sheet
//                 _navigateToVariantCreation();
//               },
//               child: Text('Add Variant'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _navigateToVariantCreation() {
//     // Navigate to Step4Section or show a bottom sheet for creating new variants
//     Get.to(() => Step4Section(controller: widget.controller));
//   }
//
//   void _removeVariant(int index) {
//     widget.controller.productVariant.removeAt(index);
//   }
//
//
//   void _showColorPicker(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => ColorPickerWidget(
//         onColorSelected: (color, colorName) {
//           widget.controller.addColor(color, colorName);
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
//
//   Widget _buildColorSection(BuildContext context){
//     return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CustomText(
//             'Color',
//             fontSize: SizeConfig.medium,
//             fontWeight: FontWeight.w500,
//             color: AppColors.black,
//           ),
//           SizedBox(height: SizeConfig.size8),
//
//           // Color Selection Container
//           InkWell(
//             onTap: () => _showColorPicker(context),
//             child: Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: SizeConfig.size16,
//                 vertical: SizeConfig.size10,
//               ),
//               decoration: BoxDecoration(
//                   color: AppColors.white,
//                   boxShadow: [AppShadows.textFieldShadow],
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                     color: AppColors.greyE5,
//                   )
//               ),
//               child: Row(
//                 children: [
//                   LocalAssets(imagePath: AppIconAssets.colorTemplateIcon),
//                   SizedBox(width: SizeConfig.size8),
//                   CustomText(
//                     'Select Color',
//                     color: AppColors.grey9A,
//                     fontWeight: FontWeight.w400,
//                     fontSize: SizeConfig.large,
//                   ),
//                   Spacer(),
//                   LocalAssets(
//                       imagePath: AppIconAssets.addBlueIcon,
//                       imgColor: AppColors.grey9A
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           Obx(() => Padding(
//             padding: const EdgeInsets.only(top: 12.0),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: List.generate(widget.controller.selectedColors.length, (i) {
//                 final selected = widget.controller.selectedColors[i];
//                 return Chip(
//                   backgroundColor: AppColors.lightBlue,
//                   shape: RoundedRectangleBorder(
//                     side: BorderSide(color: Colors.transparent),
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   deleteIcon: const Icon(
//                     Icons.close,
//                     size: 18,
//                     color: AppColors.mainTextColor,
//                   ),
//                   onDeleted: () => widget.controller.removeColor(selected),
//                   label: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 16,
//                         height: 16,
//                         decoration: BoxDecoration(
//                           color: selected.color,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 1),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         '${selected.name}',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: AppColors.secondaryTextColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                   labelPadding: const EdgeInsets.only(left: 12),
//                   padding: EdgeInsets.zero,
//                   visualDensity: VisualDensity.compact,
//                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 );
//               }),
//             ),
//           ))
//         ]
//     );
//   }
//
//   Widget _buildMaterialSection(ManualListingScreenController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomText(
//           'Material (Other text format variant)',
//           fontSize: SizeConfig.medium,
//           fontWeight: FontWeight.w500,
//           color: AppColors.black,
//         ),
//         SizedBox(height: SizeConfig.size8),
//         Container(
//           padding: EdgeInsets.symmetric(
//             horizontal: SizeConfig.size16,
//             vertical: SizeConfig.size10,
//           ),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             boxShadow: [AppShadows.textFieldShadow],
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: AppColors.greyE5, width: 1),
//           ),
//           child: Row(
//             children: [
//               Image.asset("assets/icons/tag_icon.png"),
//               SizedBox(width: SizeConfig.size12),
//               Expanded(
//                 child: TextField(
//                   controller: controller.materialController,
//                   onChanged: (_) => controller.update(["addMaterialIcon"]),
//                   decoration: const InputDecoration(
//                     hintText: 'E.g. Cotton, Leather, Metal, Plastic...',
//                     hintStyle: TextStyle(
//                       color: AppColors.grey9B,
//                       fontSize: 14,
//                     ),
//                     border: InputBorder.none,
//                     enabledBorder: InputBorder.none,
//                     focusedBorder: InputBorder.none,
//                     contentPadding: EdgeInsets.zero,
//                     isDense: true,
//                   ),
//                 ),
//               ),
//               GetBuilder<ManualListingScreenController>(
//                 id: "addMaterialIcon",
//                 builder: (_) {
//                   return AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 200),
//                     transitionBuilder: (child, anim) =>
//                         ScaleTransition(scale: anim, child: child),
//                     child: controller.materialController.text.isNotEmpty
//                         ? InkWell(
//                       key: const ValueKey("add"),
//                       onTap: () {
//                         controller.addMaterial();
//                         controller.update(["addMaterialIcon"]);
//                         unFocus();
//                       },
//                       child: LocalAssets(
//                         imagePath: AppIconAssets.addBlueIcon,
//                         // imgColor: AppColors.grey9A
//                       ),
//                     )
//                         : const SizedBox.shrink(key: ValueKey("empty")),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         Obx(()=> Wrap(
//           spacing: 8,
//           runSpacing: 2,
//           children: controller.materials.map((tag) {
//             return Chip(
//               label: Text(tag),
//               backgroundColor: AppColors.lightBlue,
//               labelStyle: TextStyle(
//                   fontSize: SizeConfig.size14,
//                   color: Colors.black87
//               ),
//               deleteIcon: const Icon(Icons.close,
//                   size: 20, color: AppColors.mainTextColor),
//               shape: RoundedRectangleBorder(
//                   side: BorderSide(color: Colors.transparent),
//                   borderRadius: BorderRadius.circular(8.0)),
//               onDeleted: () => controller.removeMaterial(tag),
//               labelPadding: const EdgeInsets.only(left: 12),
//               padding: EdgeInsets.zero,
//               visualDensity: VisualDensity.compact,
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             );
//           }).toList(),
//         ))
//       ],
//     );
//   }
//
//   Widget _buildDynamicAttributeSection(
//       ManualListingScreenController controller,
//       String attributeKey, // e.g., "size", "style"
//       String hintText,
//       ) {
//     controller.dynamicControllers.putIfAbsent(attributeKey, () => TextEditingController());
//     controller.dynamicAttributes.putIfAbsent(attributeKey, () => <String>[].obs);
//
//     return Padding(
//       padding: EdgeInsets.only(bottom: SizeConfig.size15),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CustomText(
//             '$attributeKey (Other variant)',
//             fontSize: SizeConfig.medium,
//             fontWeight: FontWeight.w500,
//             color: AppColors.black,
//           ),
//           SizedBox(height: SizeConfig.size8),
//           Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: SizeConfig.size16,
//               vertical: SizeConfig.size10,
//             ),
//             decoration: BoxDecoration(
//               color: AppColors.white,
//               boxShadow: [AppShadows.textFieldShadow],
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: AppColors.greyE5, width: 1),
//             ),
//             child: Row(
//               children: [
//                 Image.asset("assets/icons/tag_icon.png"),
//                 SizedBox(width: SizeConfig.size12),
//                 Expanded(
//                   child: TextField(
//                     controller: controller.dynamicControllers[attributeKey],
//                     onChanged: (_) => controller.update([attributeKey]),
//                     decoration: InputDecoration(
//                       hintText: hintText,
//                       hintStyle: TextStyle(
//                         color: AppColors.grey9B,
//                         fontSize: 14,
//                       ),
//                       border: InputBorder.none,
//                       enabledBorder: InputBorder.none,
//                       focusedBorder: InputBorder.none,
//                       contentPadding: EdgeInsets.zero,
//                       isDense: true,
//                     ),
//                   ),
//                 ),
//                 GetBuilder<ManualListingScreenController>(
//                   id: attributeKey,
//                   builder: (_) {
//                     final text = controller.dynamicControllers[attributeKey]!.text;
//                     return AnimatedSwitcher(
//                       duration: Duration(milliseconds: 200),
//                       transitionBuilder: (child, anim) =>
//                           ScaleTransition(scale: anim, child: child),
//                       child: text.isNotEmpty
//                           ? InkWell(
//                         key: ValueKey("add_$attributeKey"),
//                         onTap: () {
//                           controller.addDynamicValue(attributeKey, text);
//                           unFocus();
//                         },
//                         child: LocalAssets(
//                           imagePath: AppIconAssets.addBlueIcon,
//                         ),
//                       )
//                           : SizedBox.shrink(key: ValueKey("empty_$attributeKey")),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 12),
//           Obx(() => Wrap(
//             spacing: 8,
//             runSpacing: 2,
//             children: controller.dynamicAttributes[attributeKey]!
//                 .map((tag) => Chip(
//               label: Text(tag),
//               backgroundColor: AppColors.lightBlue,
//               labelStyle: TextStyle(
//                   fontSize: SizeConfig.size14, color: Colors.black87),
//               deleteIcon: Icon(Icons.close,
//                   size: 20, color: AppColors.mainTextColor),
//               shape: RoundedRectangleBorder(
//                   side: BorderSide(color: Colors.transparent),
//                   borderRadius: BorderRadius.circular(8.0)),
//               onDeleted: () =>
//                   controller.removeDynamicValue(attributeKey, tag),
//               labelPadding: EdgeInsets.only(left: 12),
//               padding: EdgeInsets.zero,
//               visualDensity: VisualDensity.compact,
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ))
//                 .toList(),
//           )),
//         ],
//       ),
//     );
//   }
// }



