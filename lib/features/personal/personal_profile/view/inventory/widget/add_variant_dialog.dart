import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/color_selection_tile.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class AddVariantDialog extends StatefulWidget {
  final ProductController controller;

  const AddVariantDialog({super.key, required this.controller});

  @override
  State<AddVariantDialog> createState() => _AddVariantDialogState();
}

class _AddVariantDialogState extends State<AddVariantDialog> {
  final titleController = TextEditingController();
  final detailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Local temp list for color selection
  final RxList<SelectedColor> localSelectedColors = <SelectedColor>[].obs;

  bool get isColor => titleController.text.toLowerCase() == 'color';

  final RxList<String> newValues = <String>[].obs;
  String inputText = '';


  @override
  void initState() {
    super.initState();
    // If already editing color, copy current selections
    if (isColor) {
      localSelectedColors.addAll(widget.controller.selectedColors);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      'Add Variant',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.mainTextColor),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size15),

                // Variant Name Field
                CommonTextField(
                  title: 'Variant Name',
                  hintText: 'e.g. size, storage, material, color',
                  textEditController: titleController,
                  isValidate: true,
                  onChange: (_) => setState(() {}),
                ),
                SizedBox(height: SizeConfig.size20),

                // Details Section
                isColor
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorSelectionTile(
                      controller: widget.controller,
                      onSelectedColor: (color, colorName) {
                        SelectedColor selectedColor = SelectedColor(color, colorName);
                        if (!localSelectedColors.contains(selectedColor)) {
                          localSelectedColors.add(selectedColor);
                        }
                        return SelectedColor(color, colorName);
                      },
                    ),
                    const SizedBox(height: 8),
                    Obx(
                          () => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(localSelectedColors.length, (i) {
                          final selected = localSelectedColors[i];
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
                              localSelectedColors.remove(selected);
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
                                  selected.name,
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
                    ),
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input field
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        boxShadow: [AppShadows.textFieldShadow],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE5, width: 1),
                      ),
                      child: Row(
                        children: [
                          Image.asset("assets/icons/tag_icon.png"),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: detailController,
                              decoration: InputDecoration(
                                hintText: "Add ${titleController.text}",
                                hintStyle: TextStyle(color: AppColors.grey9B, fontSize: 14),
                                border: InputBorder.none,
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
                              key: ValueKey("add_${titleController.text}"),
                              onTap: () {
                                final val = inputText.trim();
                                if (val.isNotEmpty && !newValues.contains(val)) {
                                  setState(() {
                                    newValues.add(val);
                                    inputText = '';
                                    detailController.clear();
                                  });
                                }
                              },
                              child: LocalAssets(
                                imagePath: AppIconAssets.addBlueIcon,
                              ),
                            )
                                : SizedBox.shrink(key: ValueKey("empty_${titleController.text}")),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Chips display for only newly added values
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: newValues.map((val) {
                        return Chip(
                          label: Text(val),
                          backgroundColor: AppColors.lightBlue,
                          labelStyle: TextStyle(fontSize: 14, color: Colors.black87),
                          deleteIcon: const Icon(Icons.close, size: 20, color: AppColors.mainTextColor),
                          onDeleted: () => setState(() => newValues.remove(val)),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Save Button
                CustomBtn(
                  title: widget.controller.isAddUpdateProductVariantLoading.value
                      ? null
                      : 'Add Variant',
                    isLoading: widget.controller.isAddUpdateProductVariantLoading.value,
                    onTap: () async {
                    if (!formKey.currentState!.validate()) return;

                    final title = titleController.text.trim();
                    final details = detailController.text.trim();

                    if (widget.controller.dynamicAttributes.containsKey(title)) {
                      Get.snackbar(
                        'Error',
                        'This attribute already exists!',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    if (isColor) {
                      if (localSelectedColors.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please pick at least one color.',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      final List<SelectedColor> mergedColors = [
                        ...widget.controller.selectedColors.toList(),
                        ...localSelectedColors.where(
                              (c) => !widget.controller.selectedColors.contains(c),
                        ),
                      ];

                      final success = await widget.controller.addUpdateProductVariantApi(
                        allColors: mergedColors,
                        allDynamicAttributes: widget.controller.dynamicAttributes.map(
                              (key, value) => MapEntry(key, value.toList()),
                        ),
                      );

                      if (success) {
                        widget.controller.selectedColors.assignAll(mergedColors);

                        for (var color in mergedColors) {
                          widget.controller.selectVariantValue('color', color);
                        }
                        widget.controller.selectedColors.refresh();
                      }

                    } else {
                      if (details.isEmpty) return;

                      if (widget.controller.dynamicAttributes.containsKey(title)) {
                        Get.snackbar(
                          'Duplicate Attribute',
                          'The attribute "$title" already exists.',
                          snackPosition: SnackPosition.TOP,
                        );
                        return;
                      }

                      final Map<String, List<String>> dynamicAttributesCopy = widget.controller.dynamicAttributes.map(
                            (key, value) => MapEntry(key, value.toList()),
                      );

                      final List<String> mergedValues = [
                        ...?widget.controller.dynamicAttributes[title]?.toList(),
                        ...newValues, // newly added values
                      ];

                      dynamicAttributesCopy[title] = mergedValues;

                      final success = await widget.controller.addUpdateProductVariantApi(
                        allColors: widget.controller.selectedColors,
                        allDynamicAttributes: dynamicAttributesCopy,
                      );

                      if (success) {
                        widget.controller.dynamicAttributes[title] = mergedValues.obs;
                        widget.controller.selectVariantValue(title, details);
                        widget.controller.dynamicAttributes.refresh();
                      }
                    }

                    Get.back();
                  },
                  bgColor: AppColors.primaryColor,
                  textColor: AppColors.white,
                  height: 45,
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}



