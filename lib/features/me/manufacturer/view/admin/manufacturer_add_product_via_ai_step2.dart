import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_step1_section.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_step2_section.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_step3_section.dart';
import 'package:BlueEra/features/me/product/model/generate_ai_product_content.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManufacturerAddProductViaAiStep2 extends StatefulWidget {
  final ManufacturerProductController controller;
  final GenerateAiProductContent generateAiProductContent;
  final String id;
  final ProviderType providerType;

  ManufacturerAddProductViaAiStep2(
      {super.key,
      required this.generateAiProductContent,
      required this.controller,
      required this.id,
      required this.providerType});

  @override
  State<ManufacturerAddProductViaAiStep2> createState() =>
      _ManufacturerAddProductViaAiStep2State();
}

class _ManufacturerAddProductViaAiStep2State
    extends State<ManufacturerAddProductViaAiStep2> {
  late ManufacturerProductController controller;

  @override
  void initState() {
    controller = widget.controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.preloadStep1ImagesToStep2();
      setData();
    });
    super.initState();
  }

  void setData() {
    controller.productNameController.clear();
    controller.productDescriptionController.clear();
    controller.brandController.clear();
    controller.linkController.clear();
    controller.mrpController.clear();
    controller.guidelineController.clear();
    controller.tags.clear();
    controller.featureControllers.clear();
    controller.detailsList.clear();
    controller.userGuideLineControllers.clear();
    controller.selectedColors.clear();
    controller.dynamicAttributes.clear();
    controller.listedProducts.clear();
    controller.selectedVariantIndex.value = 0;
    controller.selectedProductOrVariantPrice = '00,000'.obs;
    controller.selectedProductOrVariantDiscount = '0'.obs;
    controller.selectedProductOrVariantMrp = '00,000'.obs;

    controller.productNameController.text =
        widget.generateAiProductContent.productName ?? '';
    controller.productDescriptionController.text =
        widget.generateAiProductContent.description ?? '';
    controller.brandController.text =
        widget.generateAiProductContent.brand ?? '';
    controller.tags.value = widget.generateAiProductContent.tags ?? [];
    List<String> features = widget.generateAiProductContent.features ?? [];
    if (features.isNotEmpty) {
      for (final feature in features) {
        controller.featureControllers.add(TextEditingController(text: feature));
      }
    }
    List<Specification> addMoreDetails =
        widget.generateAiProductContent.specifications ?? [];
    widget.controller.detailsList.value = addMoreDetails.map((spec) {
      return ManufacturerProductMoreDetails(
        title: spec.title,
        details: spec.details,
      );
    }).toList();

    controller.mrpController.text =
        widget.generateAiProductContent.mrp?.toInt().toString() ?? '';
    List<String> userGuide = widget.generateAiProductContent.userGuide ?? [];
    if (userGuide.isNotEmpty) {
      for (final guideLine in userGuide) {
        controller.userGuideLineControllers
            .add(TextEditingController(text: guideLine));
      }
    }

    controller.productWarrantyController.text =
        widget.generateAiProductContent.warranty ?? '';
    controller.productExpiryDurationController.text =
        widget.generateAiProductContent.durationOfExpiryFromManufacture ?? '';

    // Keep the full per-variant data (attributes + pricing) for the
    // create-product request body.
    controller.aiVariantData = widget.generateAiProductContent.variantData;

    final variantMap = widget.generateAiProductContent.variant ?? {};

    variantMap.forEach((key, valueList) {
      if (valueList.isEmpty) return;

      if (key == 'color') {
        log('key-- $key');
        for (final colorItem in valueList) {
          if (colorItem is Map<String, dynamic>) {
            final colorCode = colorItem['color_code'] as String? ?? '#000000';
            final colorName = colorItem['name'] as String? ?? 'Unknown';
            Color color = hexToColor(colorCode);

            controller.selectedColors.add(
              ManufacturerSelectedColor(color, colorName),
            );
          }
        }
      } else {
        // Dynamic attributes
        controller.dynamicAttributes.putIfAbsent(key, () => <String>[].obs);
        for (final val in valueList) {
          controller.dynamicAttributes[key]!.add(val.toString());
        }
      }
    });

    log('Selected colors count: ${controller.selectedColors.length}');
    log('Dynamic attributes: ${controller.dynamicAttributes}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: AppStrings.addProductViaAI,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Obx(() => Column(
              children: [
                CustomFormCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      CustomText(
                        AppStrings.addProductWithin1Min,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size20),
                      CustomText(
                        AppStrings.uploadProductImages,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black28,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      SizedBox(
                        height: SizeConfig.size80,
                        child: Obx(() {
                          final totalImages = controller.step2Images.length;

                          return GridView.builder(
                            scrollDirection: Axis.horizontal,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: controller.maxStep2Images.value,
                            itemBuilder: (context, index) {
                              final hasImage = index < totalImages;

                              return GestureDetector(
                                onTap: () {
                                  if (!hasImage)
                                    controller.pickImagesStep2(context);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteFE,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.greyE5),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (hasImage)
                                        Image.file(
                                          File(controller.step2Images[index]),
                                          fit: BoxFit.cover,
                                        )
                                      else
                                        const Center(
                                          child: Icon(Icons.photo_outlined,
                                              color: Colors.grey, size: 28),
                                        ),
                                      if (hasImage &&
                                          index >=
                                              controller.step1Images.length)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => controller
                                                .removeImageStep2(index),
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
                              );
                            },
                          );
                        }),
                      ),
                      SizedBox(height: SizeConfig.size10),
                    ])),
                SizedBox(height: SizeConfig.size10),
                CustomFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.hereIsYourProduct,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size10),

                      /// Product Details
                      _buildProductDetails(),
                      SizedBox(height: SizeConfig.size10),

                      /// features
                      _buildProductFeature(),
                      SizedBox(height: SizeConfig.size10),

                      /// pricing & warranty
                      _buildPricingAndWarranty(),
                      SizedBox(height: SizeConfig.size10),

                      /// Product variant
                      _buildProductVariant(),

                      SizedBox(height: SizeConfig.size20),

                      /// Submit
                      CustomBtn(
                          title: controller.isCreateProductLoading.value
                              ? null // hide text
                              : AppStrings.postProduct,
                          onTap: () {
                            controller.createProductViaAi(
                                controller, widget.id, widget.providerType);
                          },
                          bgColor: AppColors.primaryColor,
                          textColor: AppColors.white,
                          height: SizeConfig.size40,
                          radius: 10.0,
                          isLoading: controller.isCreateProductLoading.value),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
              ],
            )),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.whiteE0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.productDetails,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              InkWell(
                  onTap: () {
                    Get.to(() =>
                        ManufacturerStep1Section(controller: controller));
                  },
                  child: LocalAssets(imagePath: AppIconAssets.pen_line))
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CommonHorizontalDivider(
            height: 1.0,
            color: AppColors.whiteE0,
          ),
          SizedBox(height: SizeConfig.size10),
          Row(
            children: [
              CustomText(
                '${AppStrings.productName.tr}: ',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              Expanded(
                child: CustomText(
                  controller.productNameController.text,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                '${AppStrings.brand.tr}: ',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              Expanded(
                child: CustomText(
                  '${controller.brandController.text}',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            '${AppStrings.productDescription}: ',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size3),
          ExpandableText(
            text: controller.productDescriptionController.text,
            trimLines: 4,
            style: TextStyle(
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              height: 1.5,
            ),
            expandMode: ExpandMode.dialog,
            dialogTitle: AppStrings.productDescription,
          ),
          SizedBox(height: SizeConfig.size10),
          (controller.tags.isNotEmpty)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      '${AppStrings.tagsKeywords.tr}: ',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(height: SizeConfig.size3),
                    CustomText(
                      '${controller.tags.join(', ')}',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      height: 1.5,
                    ),
                  ],
                )
              : SizedBox(),
        ],
      ),
    );
  }

  Widget _buildProductFeature() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.whiteE0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.productFeatures,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              InkWell(
                  onTap: () {
                    Get.to(() =>
                        ManufacturerStep2Section(controller: controller));
                  },
                  child: LocalAssets(imagePath: AppIconAssets.pen_line))
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CommonHorizontalDivider(
            height: 1.0,
            color: AppColors.whiteE0,
          ),
          SizedBox(height: SizeConfig.size10),
          if (controller.featureControllers.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                controller.featureControllers.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 6.0, right: 8.0),
                        width: 4.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: CustomText(
                          controller.featureControllers[index].text,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (controller.linkController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '${AppStrings.website}: ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => launchURL(controller.linkController.text),
                      child: CustomText(
                        '${controller.linkController.text}',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (controller.detailsList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '${AppStrings.moreDetails}: ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      controller.detailsList.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 6.0, right: 8.0),
                              width: 4.0,
                              height: 4.0,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTextColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: CustomText(
                                '${controller.detailsList[index].title} - ${controller.detailsList[index].details}',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingAndWarranty() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.whiteE0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.pricingWarranty,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              InkWell(
                  onTap: () {
                    Get.to(() =>
                        ManufacturerStep3Section(controller: controller));
                  },
                  child: LocalAssets(imagePath: AppIconAssets.pen_line))
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CommonHorizontalDivider(
            height: 1.0,
            color: AppColors.whiteE0,
          ),
          if (controller.productWarrantyController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  CustomText(
                    '${AppStrings.productWarranty.tr}: ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  Expanded(
                    child: CustomText(
                      "${controller.productWarrantyController.text}",
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          if (controller.productExpiryDurationController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  CustomText(
                    '${AppStrings.expiryTime.tr}: ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  Expanded(
                    child: CustomText(
                      "${controller.productExpiryDurationController.text}",
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          if (controller.userGuideLineControllers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '${AppStrings.userGuidance.tr}: ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: 3.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      controller.userGuideLineControllers.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 6.0, right: 8.0),
                              width: 4.0,
                              height: 4.0,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTextColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: CustomText(
                                controller.userGuideLineControllers[index].text,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductVariant() {
    final variants = widget.generateAiProductContent.variantData;
    return Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.whiteE0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.variant,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          CommonHorizontalDivider(
            height: 1.0,
            color: AppColors.whiteE0,
          ),
          SizedBox(height: SizeConfig.size8),

          // Show every variant possibility coming from variantData.
          if (variants.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                variants.length,
                (i) => Padding(
                  padding: EdgeInsets.only(
                    bottom: i == variants.length - 1 ? 0 : SizeConfig.size8,
                  ),
                  child: _variantCard(variants[i]),
                ),
              ),
            )
          else
            _buildLegacyVariantInfo(),
        ],
      ),
    );
  }

  // One card per variant — name + price, with attribute / specification chips.
  Widget _variantCard(AiVariantData v) {
    final pricing = v.pricing.isNotEmpty ? v.pricing.first : null;
    final attrEntries = <MapEntry<String, dynamic>>[
      ...v.attributes.entries,
      ...v.specification.entries,
    ];
    final showStrike = pricing?.mrp != null &&
        pricing?.sellingPrice != null &&
        (pricing!.mrp! > pricing.sellingPrice!);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
        color: AppColors.whiteFE,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  v.variantName ?? v.value ?? AppStrings.na,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),
              if (pricing != null) ...[
                const SizedBox(width: 6),
                CustomText(
                  '₹${pricing.sellingPrice ?? pricing.mrp ?? ''}',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
                if (showStrike) ...[
                  const SizedBox(width: 6),
                  CustomText(
                    '₹${pricing.mrp}',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.secondaryTextColor,
                  ),
                ],
              ],
            ],
          ),
          if (attrEntries.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: attrEntries
                  .map((e) => _variantChip('${e.key}: ${e.value}'))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _variantChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  // Fallback display (colors + flattened attributes) when no variantData
  // is present.
  Widget _buildLegacyVariantInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.selectedColors.isNotEmpty) ...[
          CustomText(
            '${AppStrings.color.tr}: ',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: 5.0),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              controller.selectedColors.length,
              (i) {
                final selected = controller.selectedColors[i];
                return Container(
                  padding: EdgeInsets.all(6.0),
                  margin: EdgeInsets.only(bottom: 6.0),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
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
                );
              },
            ),
          ),
          SizedBox(height: SizeConfig.size10),
        ],
        Obx(() {
          if (controller.dynamicAttributes.isEmpty) return SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: controller.dynamicAttributes.entries.map((entry) {
              final key = entry.key; // attribute name
              final values = entry.value; // RxList<String>

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '$key:',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  const SizedBox(height: 3.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      values.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 6.0, right: 8.0),
                              width: 4.0,
                              height: 4.0,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTextColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: CustomText(
                                values[index],
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size8),
                ],
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
