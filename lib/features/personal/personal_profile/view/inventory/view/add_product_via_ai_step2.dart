import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/category_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/step1_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/step2_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/step3_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/generate_ai_product_content.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddProductViaAiStep2 extends StatefulWidget {
  final AddProductViaAiController controller;
  final GenerateAiProductContent generateAiProductContent;

  AddProductViaAiStep2({super.key, required this.generateAiProductContent, required this.controller});

  @override
  State<AddProductViaAiStep2> createState() => _AddProductViaAiStep2State();
}

class _AddProductViaAiStep2State extends State<AddProductViaAiStep2> {
 AddProductViaAiController controller = AddProductViaAiController();

  @override
  void initState() {
    controller = widget.controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.preloadStep1ImagesToStep2();
      setData();
     });
    super.initState();
  }

  void setData(){
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
    controller.selectedCategory.value = '';
    controller.selectedCategoryId.value = '';
    // controller.productVariant.clear();

    // controller.selectedExpiryDuration = 'Day'.obs;
    // controller.selectedProductDuration = 'Day'.obs;
    // controller.selectedExpiryValue = Rx<num>(1);
    // controller.selectedProductValue = Rx<num>(1);

    controller.productNameController.text = widget.generateAiProductContent.productName??'';
    controller.productDescriptionController.text = widget.generateAiProductContent.description??'';
    controller.brandController.text = widget.generateAiProductContent.brand??'';
    controller.tags.value = widget.generateAiProductContent.tags??[];
    controller.selectedCategory.value = widget.generateAiProductContent.amazonCategory??'';
    log('selectedCategory-- ${controller.selectedCategory.value}');
    List<String> features = widget.generateAiProductContent.features ?? [];
    if(features.isNotEmpty){
      for (final feature in features) {
        controller.featureControllers.add(TextEditingController(text: feature));
      }
    }
    List<Specification> addMoreDetails = widget.generateAiProductContent.specifications ?? [];
    if(addMoreDetails.isNotEmpty){
      for(final addMoreDetail in addMoreDetails)
        controller.detailsList.add(addMoreDetail);
    }

    if(widget.generateAiProductContent.brandWebsite!=null){
      controller.linkController.text = widget.generateAiProductContent.brandWebsite??'';
    }

    controller.mrpController.text = widget.generateAiProductContent.mrp?.toInt().toString()??'';
    List<String> userGuide = widget.generateAiProductContent.userGuide ?? [];
    if(userGuide.isNotEmpty){
      for (final guideLine in userGuide) {
        controller.userGuideLineControllers.add(TextEditingController(text: guideLine));
      }
    }

    controller.productWarrantyController.text = widget.generateAiProductContent.warranty??'';
    controller.productExpiryDurationController.text = widget.generateAiProductContent.durationOfExpiryFromManufacture??'';

    final variantMap = widget.generateAiProductContent.variant ?? {};

    variantMap.forEach((key, valueList) {
      if (valueList.isEmpty) return;

      if (key == 'color') {
        log('key-- $key');
        for (final colorItem in valueList) {
          log('colorItem-- $colorItem');
          log('colorItem runtimeType: ${colorItem.runtimeType}');
          if (colorItem is Map<String, dynamic>) {
            final colorCode = colorItem['color_code'] as String? ?? '#000000';
            final colorName = colorItem['name'] as String? ?? 'Unknown';
            Color color = hexToColor(colorCode);
            log('colorCode-- $colorCode');
            log('colorName-- $colorCode');

            controller.selectedColors.add(
              SelectedColor(color, colorName),
            );
            log('Selected colors count: ${controller.selectedColors.length}');
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

    setState(() {});

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
        title: "Add Product Via AI",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Obx(()=> Column(
          children: [
            CustomFormCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'add product within 1 min via aI',
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size20),
                      CustomText(
                        'Upload product Images',
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: controller.maxStep2Images.value,
                            itemBuilder: (context, index) {
                              final hasImage = index < totalImages;

                              return GestureDetector(
                                onTap: () {
                                  if (!hasImage) controller.pickImagesStep2(context);
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
                                          child: Icon(Icons.photo_outlined, color: Colors.grey, size: 28),
                                        ),
                                      if (hasImage && index >= controller.step1Images.length)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => controller.removeImageStep2(index),
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 14, color: Colors.white),
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

                      // Container(
                      //   padding: EdgeInsets.all(10.0),
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(10.0),
                      //     border: Border.all(
                      //         color: AppColors.whiteE0,
                      //     ),
                      //     color: Colors.white
                      //   ),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Row(
                      //         children: [
                      //           CustomText(
                      //             'Product Name: ',
                      //             fontSize: SizeConfig.medium,
                      //             fontWeight: FontWeight.w600,
                      //             color: AppColors.secondaryTextColor,
                      //           ),
                      //
                      //           Expanded(
                      //             child: CustomText(
                      //               widget.generateAiProductContent.name,
                      //               fontSize: SizeConfig.medium,
                      //               fontWeight: FontWeight.w400,
                      //               color: AppColors.secondaryTextColor,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //       SizedBox(height: SizeConfig.size10),
                      //
                      //       CustomText(
                      //         'Product Description: ',
                      //         fontSize: SizeConfig.medium,
                      //         fontWeight: FontWeight.w600,
                      //         color: AppColors.secondaryTextColor,
                      //       ),
                      //       SizedBox(height: SizeConfig.size3),
                      //       ExpandableText(
                      //         text: widget.generateAiProductContent.description??'',
                      //         trimLines: 4,
                      //         style: TextStyle(
                      //           fontSize: SizeConfig.medium,
                      //           fontWeight: FontWeight.w400,
                      //           color: AppColors.secondaryTextColor,
                      //         ),
                      //         expandMode: ExpandMode.dialog,
                      //         dialogTitle: 'Video Description',
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      SizedBox(height: SizeConfig.size10),

                      /// category
                      CustomText(
                        'Category',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Obx(() => InkWell(
                        onTap: () async {
                          await showCategoryBottomSheet(context);
                          // controller.openCategoryBottomSheet(context);
                        },
                        child: Container(
                          width: SizeConfig.screenWidth,
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
                              )),
                          child: controller.selectedCategory.isNotEmpty
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                  controller.selectedCategory.value,
                                  fontSize:  SizeConfig.medium,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black
                              ),
                            ],
                          )
                              : Container(
                            // padding: EdgeInsets.all(SizeConfig.size12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  'Select a category',
                                  color: AppColors.grey9A,
                                  fontWeight: FontWeight.w400,
                                  fontSize: SizeConfig.large,
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: AppColors.grey9A)
                              ],
                            ),
                          ),
                        ),
                      )),

                    ]
                )
            ),
            SizedBox(height: SizeConfig.size10),
            CustomFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Here Is Your Product details',
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
                          : 'Post Product',
                    onTap: (){
                      //Get.to(()=> ProductPreviewScreen(controller: controller));
                       controller.createProductViaAi(controller);
                    },
                    bgColor: AppColors.primaryColor,
                    textColor: AppColors.white,
                    height: SizeConfig.size40,
                    radius: 10.0,
                     isLoading: controller.isCreateProductLoading.value
                  ),
                ],
              ),

            ),
            SizedBox(height: SizeConfig.size20),
          ],
         )
        ),
      ),
    );
  }

  Widget _buildProductDetails(){
    return Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.whiteE0)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Product details',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              InkWell(
                  onTap: () {
                    Get.to(()=> Step1Section(controller: controller));
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
                'Product Name: ',
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
                'Brand: ',
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
            'Product Description: ',
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
            dialogTitle: 'Product Description',
          ),

          SizedBox(height: SizeConfig.size10),
          (controller.tags.isNotEmpty)
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Tags/Keywords: ',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size3),
              CustomText(
                '${ controller.tags.join(', ')}', /// Keyword/tegs
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
                height: 1.5,
              ),
            ],
          ) : SizedBox(),
        ],
      ),
    );
  }

  Widget _buildProductFeature(){
    return  Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.whiteE0)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Product Features',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              InkWell(
                  onTap: () {
                    Get.to(()=> Step2Section(controller: controller));
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

          if(controller.featureControllers.isNotEmpty)
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
                          // height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if(controller.linkController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Website: ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: ()=> launchURL(controller.linkController.text),
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

          if(controller.detailsList.isNotEmpty)
            ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'More Details: ',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(height: SizeConfig.size3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        controller.detailsList.length, // number of items
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
                                  // height: 1.2,
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

  Widget _buildPricingAndWarranty(){
    return Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.whiteE0)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Pricing & warranty',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              InkWell(
                  onTap: () {
                    Get.to(()=> Step3Section(controller: controller));
                  },
                  child: LocalAssets(imagePath: AppIconAssets.pen_line))
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CommonHorizontalDivider(
            height: 1.0,
            color: AppColors.whiteE0,
          ),

          (controller.mrpController.text.isNotEmpty) ?
          Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                CustomText(
                  'MRP: ',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
                Expanded(
                  child: CustomText(
                    "${controller.mrpController.text}",
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryTextColor,
                  ),
                ),

              ],
            ),
          ) : SizedBox(),

          if(controller.productWarrantyController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  CustomText(
                    'Product Warranty: ',
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

          if(controller.productExpiryDurationController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  CustomText(
                    'Expiry Time: ',
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

          if(controller.userGuideLineControllers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'User Guidance: ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: 3.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      controller.userGuideLineControllers.length, // number of items
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
    return Container(
      padding: EdgeInsets.all(SizeConfig.size8),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppColors.whiteE0)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Variant',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     CustomText(
          //       'Variant',
          //       fontSize: SizeConfig.large,
          //       fontWeight: FontWeight.w600,
          //       color: AppColors.mainTextColor,
          //     ),
          //     InkWell(
          //         onTap: () {
          //           Get.to(()=> Step4Section(controller: controller));
          //         },
          //         child: LocalAssets(imagePath: AppIconAssets.pen_line))
          //   ],
          // ),
          SizedBox(height: SizeConfig.size6),
          CommonHorizontalDivider(
            height: 1.0,
            color: AppColors.whiteE0,
          ),
          SizedBox(height: SizeConfig.size8),

          if(controller.selectedColors.isNotEmpty)
            ...[
              CustomText(
                'Color: ',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: 5.0),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  controller.selectedColors.length, // number of items
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
                    // Attribute title
                    CustomText(
                      '$key:',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 3.0),

                    // Values
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
          })



        ],
      ),
    );
  }
}
