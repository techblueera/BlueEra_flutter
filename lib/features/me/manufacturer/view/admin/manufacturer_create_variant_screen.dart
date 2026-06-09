import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_add_variant_dialog.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_color_selection_tile.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_skip_variant_dialog.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_submit_variant_dialog.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManufacturerCreateVariantScreen extends StatefulWidget {
  final ManufacturerProductController controller;
  final String id;
  final ProviderType providerType;
  const ManufacturerCreateVariantScreen(
      {super.key,
      required this.controller,
      required this.id,
      required this.providerType});

  @override
  State<ManufacturerCreateVariantScreen> createState() =>
      _ManufacturerCreateVariantScreenState();
}

class _ManufacturerCreateVariantScreenState
    extends State<ManufacturerCreateVariantScreen> {
  final Map<int, int> _currentIndices = {};
  final Map<int, CarouselSliderController> _controllers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.createVariantCombination,
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

                  // Dynamic attributes sections. "Color" + "ColorCode" are
                  // rendered as a single section (swatch + name) instead of two.
                  Obx(() {
                    final attrs = widget.controller.dynamicAttributes;
                    String? colorKey;
                    String? colorCodeKey;
                    attrs.forEach((k, v) {
                      if (k.toLowerCase() == 'color') colorKey = k;
                      if (k.toLowerCase() == 'colorcode') colorCodeKey = k;
                    });
                    final cKey = colorKey;
                    final ccKey = colorCodeKey;
                    final hasColorCombo = cKey != null && ccKey != null;

                    List<Widget> attributeWidgets = [];
                    attrs.forEach((key, values) {
                      if (values.isEmpty) return;
                      // ColorCode is merged into the Color section — skip it.
                      if (hasColorCombo && key == ccKey) return;
                      if (hasColorCombo && key == cKey) {
                        attributeWidgets.add(_buildColorComboSection(
                          cKey,
                          values,
                          ccKey,
                          attrs[ccKey]!,
                        ));
                      } else {
                        attributeWidgets
                            .add(_buildAttributeSection(key, values));
                      }
                    });
                    return Column(children: attributeWidgets);
                  }),

                  // Add More Variant Button
                  _buildAddMoreVariantButton(),

                  SizedBox(height: SizeConfig.size20),

                  // Bottom buttons (fixed at bottom)
                  Obx(() {
                    final selectedEmpty =
                        widget.controller.selectedVariantValues.isEmpty;
                    return Row(
                      children: [
                        if (widget.controller.listedProducts.isEmpty)
                          if (selectedEmpty)
                            Expanded(
                              child: PositiveCustomBtn(
                                title: AppStrings.skip,
                                bgColor: AppColors.white,
                                borderColor: AppColors.primaryColor,
                                textColor: AppColors.primaryColor,
                                radius: 10.0,
                                onTap: () {
                                  showDialog(
                                    context: Get.context!,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                        ManufacturerSkipVariantDialog(
                                      controller: widget.controller,
                                    ),
                                  );
                                },
                              ),
                            ),
                        if (selectedEmpty) SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: PositiveCustomBtn(
                            title: AppStrings.next,
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
                                      barrierDismissible: false,
                                      builder: (context) =>
                                          ManufacturerSubmitVariantDialog(
                                        controller: widget.controller,
                                      ),
                                    );
                                  }
                                : () {
                                    Get.snackbar(
                                      AppStrings.error.tr,
                                      AppStrings.selectVariantPrompt.tr,
                                    );
                                  },
                          ),
                        ),
                      ],
                    );
                  })
                ],
              ),
            ),
            Obx(() => (widget.controller.listedProducts.isNotEmpty)
                ? CustomFormCard(
                    margin: EdgeInsets.symmetric(vertical: SizeConfig.size20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          AppStrings.listing,
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.large,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(height: SizeConfig.size10),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.controller.listedProducts.length,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, productIndex) {
                            final product =
                                widget.controller.listedProducts[productIndex];

                            // init default values
                            _currentIndices.putIfAbsent(productIndex, () => 0);
                            _controllers.putIfAbsent(
                                productIndex, () => CarouselSliderController());

                            return Container(
                              margin:
                                  EdgeInsets.only(bottom: SizeConfig.size15),
                              decoration: BoxDecoration(
                                  color: AppColors.whiteFE,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.whiteE5,
                                  )),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Stack(
                                      children: [
                                        CarouselSlider.builder(
                                          carouselController:
                                              _controllers[productIndex],
                                          itemCount: product.image.length,
                                          options: CarouselOptions(
                                            height: 120,
                                            viewportFraction: 1.0,
                                            enlargeCenterPage: false,
                                            enableInfiniteScroll: false,
                                            onPageChanged: (index, reason) {
                                              setState(() {
                                                _currentIndices[productIndex] =
                                                    index;
                                              });
                                            },
                                          ),
                                          itemBuilder:
                                              (context, imgIndex, realIdx) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.horizontal(
                                                      left: Radius.circular(10)),
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
                                          child: product.image.length > 1
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: List.generate(
                                                      product.image.length,
                                                      (dotIndex) {
                                                    final isActive =
                                                        _currentIndices[
                                                                productIndex] ==
                                                            dotIndex;
                                                    return AnimatedContainer(
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 3.0),
                                                      width: isActive ? 8 : 6,
                                                      height: isActive ? 8 : 6,
                                                      decoration: BoxDecoration(
                                                        color: isActive
                                                            ? AppColors
                                                                .primaryColor
                                                            : Colors.grey,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    );
                                                  }),
                                                )
                                              : SizedBox(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
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
                                                color: AppColors
                                                    .secondaryTextColor,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: CustomText(
                                                  '${product.discount}% off',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: SizeConfig.medium,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          )
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
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      onSelected: (value) async {
                                        if (value == 'deleteVariant') {
                                          widget.controller.listedProducts
                                              .removeAt(productIndex);
                                        }
                                      },
                                      icon: Icon(Icons.more_vert,
                                          color: AppColors.black),
                                      itemBuilder: (context) =>
                                          popupProductListedVariantMenuItems(),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: SizeConfig.size10),
                        CustomBtn(
                            title: widget
                                    .controller.isAddProductToInventoryLoading.value
                                ? null // hide text
                                : AppStrings.goToProductPage,
                            bgColor: AppColors.primaryColor,
                            borderColor: AppColors.primaryColor,
                            radius: 10.0,
                            textColor: AppColors.white,
                            onTap: () {
                              widget.controller.addProductToInventory(
                                id: widget.id,
                                providerType: widget.providerType,
                                addProductViaAiController: widget.controller,
                                products: widget.controller.listedProducts,
                              );
                            },
                            isLoading: widget.controller
                                .isAddProductToInventoryLoading.value)
                      ],
                    ),
                  )
                : SizedBox())
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
              CustomText(
                AppStrings.color,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
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
                    CustomText(
                      AppStrings.addMoreTitle,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
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
                  final isSelected = widget.controller.isValueSelected(
                    'color',
                    ManufacturerSelectedColor(color.color, color.name),
                  );

                  return InkWell(
                    onTap: () =>
                        widget.controller.selectVariantValue('color', color),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.lightBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Checkbox
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.grey9A,
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
                              border: Border.all(
                                  color: AppColors.greyE5, width: 1.0),
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
                    CustomText(
                      AppStrings.addMoreTitle,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
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
                spacing: 12,
                runSpacing: 12,
                children: values.map((value) {
                  final isSelected =
                      widget.controller.isValueSelected(attributeKey, value);

                  return InkWell(
                    onTap: () => widget.controller
                        .selectVariantValue(attributeKey, value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.lightBlue : AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated checkbox
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.grey9A,
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
                            constraints: BoxConstraints(
                                maxWidth: SizeConfig.screenWidth / 3),
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

  /// Color + ColorCode rendered together: each entry shows the color name and
  /// a swatch filled from the paired ColorCode hex. Selecting an entry sets
  /// BOTH the Color and the matching ColorCode so the variant combination
  /// carries both attributes.
  Widget _buildColorComboSection(
    String colorKey,
    RxList<String> colorValues,
    String colorCodeKey,
    RxList<String> colorCodeValues,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.color,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              InkWell(
                onTap: () =>
                    _openColorComboDialog(context, colorKey, colorCodeKey),
                child: Row(
                  children: [
                    Icon(Icons.add, color: AppColors.primaryColor, size: 16),
                    SizedBox(width: 4),
                    CustomText(
                      AppStrings.addMoreTitle,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size16),
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
                children: List.generate(colorValues.length, (i) {
                  final name = colorValues[i];
                  final code =
                      i < colorCodeValues.length ? colorCodeValues[i] : '';
                  final isSelected =
                      widget.controller.isValueSelected(colorKey, name);

                  return InkWell(
                    onTap: () {
                      final wasSelected =
                          widget.controller.isValueSelected(colorKey, name);
                      // Toggle the color name.
                      widget.controller.selectVariantValue(colorKey, name);
                      // Keep the paired ColorCode in sync with the color.
                      if (code.isNotEmpty) {
                        final codeSelected = widget.controller
                            .isValueSelected(colorCodeKey, code);
                        if (wasSelected) {
                          if (codeSelected) {
                            widget.controller
                                .selectVariantValue(colorCodeKey, code);
                          }
                        } else if (!codeSelected) {
                          widget.controller
                              .selectVariantValue(colorCodeKey, code);
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.lightBlue : AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.grey9A,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 11)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          // Color name
                          ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: SizeConfig.screenWidth / 3),
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.black,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (code.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            // Color swatch from the paired ColorCode hex
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: hexToColor(code),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.greyE5, width: 1.0),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
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
          builder: (context) => ManufacturerAddVariantDialog(
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
            AppStrings.addMoreVariant,
            color: AppColors.primaryColor,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  void _openColorDialog(BuildContext context) {
    // Clone existing selected colors
    final existingColors = widget.controller.selectedColors.toList();
    final newColors = <ManufacturerSelectedColor>[].obs; // Only new picks

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
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ManufacturerColorSelectionTile(
                    controller: widget.controller,
                    onSelectedColor: (color, colorName) {
                      // Only add if not already in existing or new
                      if (!existingColors.any((c) => c.color == color) &&
                          !newColors.any((c) => c.color == color)) {
                        newColors
                            .add(ManufacturerSelectedColor(color, colorName));
                      }
                    },
                  ),
                  Obx(() => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Existing colors (non-deletable)
                            ...existingColors.map((c) => Chip(
                                  backgroundColor:
                                      AppColors.grey5B.withValues(alpha: 0.3),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: c.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),

                            // New colors (deletable)
                            ...newColors.map((c) => Chip(
                                  backgroundColor: AppColors.lightBlue,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: c.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: AppColors.mainTextColor,
                                  ),
                                  onDeleted: () => newColors.remove(c),
                                )),
                          ],
                        ),
                      )),
                  CustomBtn(
                    onTap: () async {
                      final allColors = [
                        ...existingColors,
                        ...newColors,
                      ];

                      final success =
                          await widget.controller.addUpdateProductVariantApi(
                              allColors: allColors,
                              allDynamicAttributes:
                                  widget.controller.dynamicAttributes.map(
                                (key, value) => MapEntry(key, value.toList()),
                              ));

                      if (success) {
                        widget.controller.selectedColors.assignAll(allColors);
                        Get.back();
                      }
                    },
                    title: widget
                            .controller.isAddUpdateProductVariantLoading.value
                        ? null
                        : AppStrings.save,
                    isLoading: widget
                        .controller.isAddUpdateProductVariantLoading.value,
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

  /// Add-color flow for the combined Color section: opens a color picker
  /// (swatch + name). On save each picked color is sent as ONE variant entry
  /// carrying both the color name and its hex code.
  void _openColorComboDialog(
    BuildContext context,
    String colorKey,
    String colorCodeKey,
  ) {
    final newColors = <ManufacturerSelectedColor>[].obs;

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
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    AppStrings.color,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  ManufacturerColorSelectionTile(
                    controller: widget.controller,
                    onSelectedColor: (color, colorName) {
                      if (!newColors.any((c) => c.color == color)) {
                        newColors
                            .add(ManufacturerSelectedColor(color, colorName));
                      }
                    },
                  ),
                  Obx(() => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: newColors
                              .map((c) => Chip(
                                    backgroundColor: AppColors.lightBlue,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: c.color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 1),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: AppColors.mainTextColor,
                                    ),
                                    onDeleted: () => newColors.remove(c),
                                  ))
                              .toList(),
                        ),
                      )),
                  Obx(() => CustomBtn(
                        onTap: () async {
                          if (newColors.isEmpty) {
                            Get.snackbar(
                              AppStrings.error.tr,
                              AppStrings.pickAtLeastOneColor.tr,
                              snackPosition: SnackPosition.TOP,
                            );
                            return;
                          }
                          final colors = newColors
                              .map((c) => {
                                    'name': c.name,
                                    'code': colorToHex(c.color),
                                  })
                              .toList();
                          final success =
                              await widget.controller.addColorComboVariantApi(
                            colorKey: colorKey,
                            colorCodeKey: colorCodeKey,
                            colors: colors,
                          );
                          if (success) Get.back();
                        },
                        title: widget.controller
                                .isAddUpdateProductVariantLoading.value
                            ? null
                            : AppStrings.save,
                        isLoading: widget
                            .controller.isAddUpdateProductVariantLoading.value,
                        bgColor: AppColors.primaryColor,
                        borderColor: AppColors.primaryColor,
                        radius: 10.0,
                      )),
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
    final existingValues =
        widget.controller.dynamicAttributes[attributeKey]?.toList() ?? [];

    // Newly added values (key/value only).
    final List<String> newValues = [];

    final textCtrl = TextEditingController();
    String inputText = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setState) {
              void addValue() {
                final val = inputText.trim();
                if (val.isEmpty ||
                    existingValues.contains(val) ||
                    newValues.contains(val)) {
                  return;
                }
                setState(() {
                  newValues.add(val);
                  inputText = '';
                  textCtrl.clear();
                });
              }

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 10, 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: AppColors.greyE5, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.sell_outlined,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size12),
                          Expanded(
                            child: CustomText(
                              "${AppStrings.add} $attributeKey",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => Get.back(),
                            borderRadius: BorderRadius.circular(30),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.secondaryTextColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Value input with inline add
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              boxShadow: [AppShadows.textFieldShadow],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: inputText.trim().isNotEmpty
                                    ? AppColors.primaryColor
                                    : AppColors.greyE5,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset("assets/icons/tag_icon.png"),
                                SizedBox(width: SizeConfig.size12),
                                Expanded(
                                  child: TextField(
                                    controller: textCtrl,
                                    onChanged: (val) =>
                                        setState(() => inputText = val),
                                    onSubmitted: (_) => addValue(),
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      hintText:
                                          "${AppStrings.add} $attributeKey",
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
                                      ScaleTransition(
                                          scale: anim, child: child),
                                  child: inputText.trim().isNotEmpty
                                      ? InkWell(
                                          key: ValueKey(
                                              "${AppStrings.add}_$attributeKey"),
                                          onTap: addValue,
                                          child: const Icon(
                                            Icons.add_circle_rounded,
                                            color: AppColors.primaryColor,
                                            size: 28,
                                          ),
                                        )
                                      : SizedBox.shrink(
                                          key: ValueKey(
                                              "${AppStrings.empty.tr}_$attributeKey")),
                                ),
                              ],
                            ),
                          ),

                          if (existingValues.isNotEmpty ||
                              newValues.isNotEmpty) ...[
                            SizedBox(height: SizeConfig.size16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Existing values (locked, non-deletable)
                                ...existingValues.map(
                                  (val) => _lockedPill(val),
                                ),
                                // Newly added values (deletable)
                                ...newValues.map(
                                  (val) => _accentValuePill(
                                    val,
                                    () =>
                                        setState(() => newValues.remove(val)),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          SizedBox(height: SizeConfig.size20 + 2),

                          // Save button
                          Obx(
                            () => CustomBtn(
                              onTap: () async {
                                if (newValues.isEmpty) {
                                  Get.snackbar(
                                    AppStrings.error.tr,
                                    AppStrings.enterValue.tr,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                  return;
                                }

                                // Send only the added values for this
                                // attribute; the controller refetches and
                                // rebuilds the on-screen axes from the API.
                                final success = await widget.controller
                                    .addAttributeVariantsApi(
                                  attributeKey: attributeKey,
                                  values: List<String>.from(newValues),
                                );

                                if (success) Get.back();
                              },
                              title: widget.controller
                                      .isAddUpdateProductVariantLoading.value
                                  ? null
                                  : AppStrings.save,
                              isLoading: widget.controller
                                  .isAddUpdateProductVariantLoading.value,
                              bgColor: AppColors.primaryColor,
                              borderColor: AppColors.primaryColor,
                              radius: 10.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Already-saved value — shown muted with a lock, cannot be removed here.
  Widget _lockedPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.grey5B.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 14, color: AppColors.secondaryTextColor),
          const SizedBox(width: 6),
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  /// Newly added value — accent pill with a remove action.
  Widget _accentValuePill(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(Icons.close_rounded,
                size: 16, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> popupProductListedVariantMenuItems() {
    final items = <Map<String, dynamic>>[
      {
        'key': 'deleteVariant',
        'title': AppStrings.deleteVariant,
      },
    ];

    final List<PopupMenuEntry<String>> entries = [];

    for (int i = 0; i < items.length; i++) {
      entries.add(
        PopupMenuItem<String>(
          height: SizeConfig.size35,
          value: items[i]['key'],
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
