import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/color_selection_tile.dart';
import 'package:BlueEra/widgets/color_picker_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Step4Section extends StatefulWidget {
  final AddProductViaAiController controller;
  Step4Section({Key? key, required this.controller}) : super(key: key);

  @override
  State<Step4Section> createState() => _Step4SectionState();
}

class _Step4SectionState extends State<Step4Section> {
  late final AddProductViaAiController controller;

  // Store original values for restoration
  late List<SelectedColor> originalColors;
  late Map<String, List<String>> originalDynamicAttributes;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    // controller.variantSizes.keys.forEach((key) {
    //   controller.variantNameControllers[key] = TextEditingController(text: key);
    // });

    // Store original values
    _storeOriginalValues();
  }

  void _storeOriginalValues() {
    // Deep copy of selected colors
    originalColors = List<SelectedColor>.from(
        controller.selectedColors.map((color) =>
            SelectedColor(color.color, color.name)
        )
    );

    // Deep copy of dynamic attributes
    originalDynamicAttributes = <String, List<String>>{};
    controller.dynamicAttributes.forEach((key, value) {
      originalDynamicAttributes[key] = List<String>.from(value);
    });
  }

  void _restoreOriginalValues() {
    // Restore colors
    controller.selectedColors.clear();
    controller.selectedColors.addAll(
        originalColors.map((color) => SelectedColor(color.color, color.name))
    );

    controller.materialController.clear();

    // Restore dynamic attributes
    controller.dynamicAttributes.clear();
    originalDynamicAttributes.forEach((key, value) {
      controller.dynamicAttributes[key] = List<String>.from(value).obs;
    });

    // Clear dynamic controllers
    controller.dynamicControllers.forEach((key, controller) {
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
          ColorSelectionTile(
              controller: controller,
              onSelectedColor: (color, colorName){
                controller.addColor(color, colorName);
             }
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

    Widget _buildDynamicAttributeSection(
        AddProductViaAiController controller,
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
                GetBuilder<AddProductViaAiController>(
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




