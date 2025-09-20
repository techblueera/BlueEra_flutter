
import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/widgets/add_more_details_dialog.dart';
import 'package:BlueEra/widgets/color_picker_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
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


  @override
  void initState() {
    super.initState();
    manualListingScreenController = widget.controller;
    manualListingScreenController.variantSizes.keys.forEach((key) {
      manualListingScreenController.variantNameControllers[key] = TextEditingController(text: key);
      manualListingScreenController.isEditingMap[key] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SizeConfig.size15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          CustomFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _buildColorSection(context),

                  SizedBox(height: SizeConfig.size15),

                  _buildMaterialSection(widget.controller),

                ],
              )
          ),


          SizedBox(height: SizeConfig.size10),

          // Types & Variant Section
          _buildTypesAndVariant(context),


        ],
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

  Widget _buildTypesAndVariant(BuildContext context){
    return  Obx(()=> CustomFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Types & Variant',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
          SizedBox(height: 12),

          // Variant Name + Size
          ...widget.controller.variantSizes.keys.map((variant) {
            final nameController = widget.controller.variantNameControllers[variant]!;

            return Obx(() {
              final isEditing = widget.controller.isEditingMap[variant] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CommonTextField(
                        // key: ValueKey(variant), // 👈 forces correct binding
                        textEditController: nameController,
                        readOnly: !isEditing,
                        sIcon: InkWell(
                          onTap: () {
                            log('variant -- $variant');
                            log('nameController.text ${nameController.text}');
                            if (isEditing) {
                              widget.controller.updateVariantName(
                                variant,
                                nameController.text,
                              );
                            }
                            widget.controller.toggleEditing(variant);
                          },
                          child: Icon(
                            isEditing ? Icons.check : Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Variant Size Input
                    Expanded(
                      flex: 3,
                      child: CommonTextField(
                        // key: ValueKey('$variant-size'), // 👈 unique key for size field
                        onChange: (value) =>
                            widget.controller.updateVariantSize(variant, value),
                        hintText: 'E.g. 5x7"',
                        hintStyle: TextStyle(
                          color: AppColors.grey9B,
                          fontSize: 14,
                        ),
                        contentPadding: EdgeInsets.all(SizeConfig.size14),
                      ),
                    ),
                  ],
                ),
              );
            });
          }).toList(),



          // SizedBox(height: SizeConfig.size15),
          //
          // // Add More Details Section
          // InkWell(
          //   onTap: ()=> showAddMoreDetailsDialog(context),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       CustomText(
          //         'Add More variant',
          //         fontSize: SizeConfig.medium,
          //         fontWeight: FontWeight.bold,
          //         color: AppColors.black,
          //       ),
          //       GestureDetector(
          //
          //         child: Container(
          //           width: 32,
          //           height: 30,
          //           decoration: BoxDecoration(
          //             color: AppColors.primaryColor,
          //             borderRadius: BorderRadius.circular(6),
          //           ),
          //           child: const Icon(
          //             Icons.add,
          //             color: AppColors.white,
          //             size: 20,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          SizedBox(height: SizeConfig.size30),

          // Bottom Buttons
          Row(
            children: [
              Expanded(
                child: PositiveCustomBtn(
                  onTap: widget.controller.saveAsDraft,
                  title: 'Save as draft',
                  bgColor: AppColors.white,
                  borderColor: AppColors.primaryColor,
                  textColor: AppColors.primaryColor,
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: PositiveCustomBtn(
                  onTap: widget.controller.onNext,
                  title: 'Post Now',
                  bgColor: AppColors.primaryColor,
                  borderColor: AppColors.primaryColor,
                ),
              ),
            ],
          )

        ],
      ),
    ));
  }

  // void showAddMoreDetailsDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (_) => const AddMoreDetailsDialog(),
  //   );
  // }
}


