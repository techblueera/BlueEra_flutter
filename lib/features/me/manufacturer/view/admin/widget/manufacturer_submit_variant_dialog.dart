import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/product/model/generate_ai_product_content.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class ManufacturerSubmitVariantDialog extends StatefulWidget {
  final ManufacturerProductController controller;

  const ManufacturerSubmitVariantDialog({
    super.key,
    required this.controller,
  });

  @override
  State<ManufacturerSubmitVariantDialog> createState() =>
      _ManufacturerSubmitVariantDialogState();
}

class _ManufacturerSubmitVariantDialogState
    extends State<ManufacturerSubmitVariantDialog> {
  final productMrpController = TextEditingController();
  final productPriceController = TextEditingController();
  List<String> productImages = <String>[];
  int maxAllowedProductImage = 2;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Discount percentage
  RxDouble discountPercent = 0.0.obs;
  late String productFullName;
  RxBool _showImagePicker = false.obs;

  Future<void> pickProductImages(BuildContext context) async {
    try {
      final List<String>? selected =
          await PhotoPickerService.pickMultiplePhotos(
        context,
        AppStrings.productImage,
      );
      if (selected != null && selected.isNotEmpty) {
        final remaining = maxAllowedProductImage - productImages.length;
        if (remaining <= 0) return;
        setState(() {
          productImages.addAll(selected.take(remaining));
        });
      }
    } catch (e) {
      log('Image pick failed: $e');
    }
  }

  @override
  void initState() {
    productFullName = '${widget.controller.productNameController.text} ' +
        widget.controller.selectedVariantValues.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;

          if (key.toLowerCase() == 'color' && value is Map<String, dynamic>) {
            return value['color_name'] ?? '';
          } else {
            return value.toString();
          }
        }).join(', ');
    _prefillPricing();
    super.initState();
  }

  /// Prefill MRP & selling price from the AI variant matching the selected
  /// combination (falling back to the headline price). The user can edit it.
  void _prefillPricing() {
    final selected = widget.controller.selectedVariantValues;
    final variants = widget.controller.aiVariantData;

    AiVariantData? match;
    for (final v in variants) {
      final attrs = <String, dynamic>{...v.attributes, ...v.specification};
      if (selected.isEmpty) break;
      bool matches = true;
      selected.forEach((k, val) {
        final selVal = (k.toLowerCase() == 'color' && val is Map)
            ? (val['color_name'] ?? val['name'])
            : val;
        if (attrs[k]?.toString() != selVal?.toString()) matches = false;
      });
      if (matches) {
        match = v;
        break;
      }
    }

    final pricing = (match?.pricing.isNotEmpty ?? false)
        ? match!.pricing.first
        : (variants.isNotEmpty && variants.first.pricing.isNotEmpty
            ? variants.first.pricing.first
            : null);

    if (pricing != null) {
      if (pricing.mrp != null) productMrpController.text = pricing.mrp.toString();
      if (pricing.sellingPrice != null) {
        productPriceController.text = pricing.sellingPrice.toString();
      }
    } else {
      // Fallback to the headline price captured on the preview.
      final mrp = widget.controller.selectedProductOrVariantMrp.value.toString();
      final price =
          widget.controller.selectedProductOrVariantPrice.value.toString();
      if (mrp.isNotEmpty && mrp != '00,000') productMrpController.text = mrp;
      if (price.isNotEmpty && price != '00,000' && price != '00, 000') {
        productPriceController.text = price;
      }
    }

    discountPercent.value = calculateDiscount(
      productPriceController.text,
      productMrpController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
          top: 8,
        ),
        child: Form(
          key: formKey,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        productFullName,
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size5),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showImagePicker.value = !_showImagePicker.value;
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            AppStrings.uploadProductImagesOptional,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                          Obx(() => AnimatedRotation(
                                turns: _showImagePicker.value ? 0.25 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.chevron_right,
                                    color: AppColors.primaryColor),
                              )),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Obx(() => AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: _showImagePicker.value
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: SizedBox(
                            height: SizeConfig.size80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 2,
                              itemBuilder: (context, index) {
                                final hasImage = index < productImages.length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: GestureDetector(
                                    onTap: () => pickProductImages(context),
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteFE,
                                        borderRadius: BorderRadius.circular(6),
                                        border:
                                            Border.all(color: AppColors.greyE5),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (hasImage)
                                            Image.file(File(productImages[index]),
                                                fit: BoxFit.cover)
                                          else
                                            const Center(
                                              child: Icon(Icons.photo_outlined,
                                                  color: Colors.grey, size: 28),
                                            ),
                                          if (hasImage)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    productImages.removeAt(index),
                                                child: Container(
                                                  width: 22,
                                                  height: 22,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.close,
                                                      size: 14,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          secondChild: const SizedBox.shrink(),
                        )),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                CommonTextField(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  title: AppStrings.productMrp,
                  hintText: AppStrings.exampleMrp,
                  textEditController: productMrpController,
                  keyBoardType: TextInputType.number,
                  validator: (value) => ValidationMethod().validatePrice(
                      productPriceController.text, productMrpController.text),
                  onChange: (_) {
                    discountPercent.value = calculateDiscount(
                        productPriceController.text, productMrpController.text);
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                CommonTextField(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  title: AppStrings.productPrice,
                  hintText: AppStrings.examplePrice,
                  textEditController: productPriceController,
                  keyBoardType: TextInputType.number,
                  validator: (value) => ValidationMethod().validatePrice(
                      productPriceController.text, productMrpController.text),
                  onChange: (_) {
                    discountPercent.value = calculateDiscount(
                        productPriceController.text, productMrpController.text);
                  },
                ),
                SizedBox(height: SizeConfig.size10),
                Obx(() => CustomText(
                      discountPercent.value > 0
                          ? "${AppStrings.discount.tr}: ${discountPercent.value.toStringAsFixed(2)}%"
                          : "${AppStrings.discount.tr}: 0%",
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    )),
                SizedBox(height: SizeConfig.size16),
                CustomBtn(
                  title: AppStrings.publish,
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      widget.controller.addProductsInListing(
                          productListing: ManufacturerProductListing(
                              id: "",
                              image: productImages.isNotEmpty
                                  ? productImages
                                  : widget.controller.step2Images,
                              name: productFullName,
                              selectedVariants:
                                  widget.controller.selectedVariantValues,
                              price: productPriceController.text.trim(),
                              mrp: productMrpController.text.trim(),
                              discount:
                                  discountPercent.value.toStringAsFixed(2)));
                      Get.back();
                    }
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
