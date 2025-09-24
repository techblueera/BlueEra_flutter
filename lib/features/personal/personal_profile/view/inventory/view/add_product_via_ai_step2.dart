import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/step1_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/step2_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/step3_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/step4_section.dart';
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
  final GenerateAiProductContent generateAiProductContent;

  AddProductViaAiStep2({super.key, required this.generateAiProductContent});

  @override
  State<AddProductViaAiStep2> createState() => _AddProductViaAiStep2State();
}

class _AddProductViaAiStep2State extends State<AddProductViaAiStep2> {
  final AddProductViaAiController addProductViaAiController = Get.put(AddProductViaAiController());
  final ManualListingScreenController manualListingScreenController = Get.put(ManualListingScreenController());

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addProductViaAiController.preloadStep1ImagesToStep2();
      setData();
    });
    super.initState();
  }

  void setData(){
    manualListingScreenController.productNameController.text = widget.generateAiProductContent.name??'';
    manualListingScreenController.shortDescriptionController.text = widget.generateAiProductContent.description??'';
    manualListingScreenController.brandController.text = widget.generateAiProductContent.brand??'';
    manualListingScreenController.tags.value = widget.generateAiProductContent.tags??[];
    List<AddProductFeature> features = widget.generateAiProductContent.addProductFeatures ?? [];
    if(features.isNotEmpty){
      for (final feature in features) {
        manualListingScreenController.featureControllers.add(TextEditingController(text: feature.title));
      }
    }
    if(widget.generateAiProductContent.linkOrReferealWebsite!=null
       && (widget.generateAiProductContent.linkOrReferealWebsite?.title?.isNotEmpty??false)
    ){
      manualListingScreenController.linkController.text = widget.generateAiProductContent.linkOrReferealWebsite?.title??'';
    }

    List<AddMoreDetail> addMoreDetails = widget.generateAiProductContent.addMoreDetails ?? [];
    if(addMoreDetails.isNotEmpty){
      for(final addMoreDetail in addMoreDetails)
      manualListingScreenController.detailsList.add(addMoreDetail);
    }

    manualListingScreenController.mrpController.text = widget.generateAiProductContent.mrpPerUnit?.toInt().toString()??'';
    manualListingScreenController.guidelineController.text = widget.generateAiProductContent.userGuide??'';

    if(widget.generateAiProductContent.expiryTime!=null) {
      final binding = widget.generateAiProductContent.expiryTime?.asDropdownBinding;
      manualListingScreenController.selectedExpiryDuration.value = binding?['type'];
      manualListingScreenController.selectedExpiryValue.value = binding?['value'];
    }

    if(widget.generateAiProductContent.productWarranty!=null) {
      final binding = widget.generateAiProductContent.productWarranty?.asDropdownBinding;
      manualListingScreenController.selectedProductDuration.value = binding?['type'];
      manualListingScreenController.selectedProductValue.value = binding?['value'];
    }
    setState(() {});

  }

  @override
  void dispose() {
    Get.delete<AddProductViaAiController>();
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
        child: Column(
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
                    final totalImages = addProductViaAiController.step2Images.length;

                    return GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: addProductViaAiController.maxStep2Images.value,
                      itemBuilder: (context, index) {
                        final hasImage = index < totalImages;

                        return GestureDetector(
                          onTap: () {
                            if (!hasImage) addProductViaAiController.pickImagesStep2(context);
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
                                    File(addProductViaAiController.step2Images[index]),
                                    fit: BoxFit.cover,
                                  )
                                else
                                  const Center(
                                    child: Icon(Icons.photo_outlined, color: Colors.grey, size: 28),
                                  ),
                                if (hasImage && index >= addProductViaAiController.step1Images.length)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => addProductViaAiController.removeImageStep2(index),
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
                        onTap: () =>
                            manualListingScreenController.openCategoryBottomSheet(context),
                        child: Container(
                          width: SizeConfig.screenWidth,
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              boxShadow: [AppShadows.textFieldShadow],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.greyE5,
                              )),
                          child: manualListingScreenController.selectedBreadcrumb.value != null
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.only(left: SizeConfig.size12),
                                constraints: BoxConstraints(
                                  maxWidth: SizeConfig.screenWidth * 0.7,
                                ),
                                // width: SizeConfig.screenWidth * 0.5,
                                child: Wrap(
                                  children: List.generate(
                                    manualListingScreenController.selectedBreadcrumb.value!.length,
                                        (i) {
                                      final item = manualListingScreenController.breadcrumb[i];
                                      final isLast = i == manualListingScreenController.breadcrumb.length - 1;

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CustomText(
                                              item.name,
                                              fontSize:  SizeConfig.medium,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.black
                                          ),
                                          if (!isLast)
                                            const Icon(Icons.chevron_right, size: 16),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              IconButton(
                                  onPressed: () {
                                    manualListingScreenController.selectedBreadcrumb.value = null;
                                  },
                                  icon: Icon(Icons.close,
                                      size: 20, color: AppColors.grey9A)
                              )
                            ],
                          )
                              : Container(
                            padding: EdgeInsets.all(SizeConfig.size12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
                  Container(
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
                                  Get.to(()=> Step1Section(controller: manualListingScreenController));
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
                                manualListingScreenController.productNameController.text,
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
                                '${manualListingScreenController.brandController.text}',
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
                          text: manualListingScreenController.shortDescriptionController.text,
                          trimLines: 4,
                          style: TextStyle(
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                          expandMode: ExpandMode.dialog,
                          dialogTitle: 'Video Description',
                        ),

                        SizedBox(height: SizeConfig.size10),
                        (manualListingScreenController.tags.isNotEmpty)
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
                                    '${ manualListingScreenController.tags.join(', ')}', /// Keyword/tegs
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                    height: 1.5,
                                  ),
                              ],
                            ) : SizedBox(),
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.size10),

                  /// features
                  Container(
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
                                  Get.to(()=> Step2Section(controller: manualListingScreenController));
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

                        if(widget.generateAiProductContent.addProductFeatures!=null)
                          if(manualListingScreenController.featureControllers.isNotEmpty)
                        ...[
                          Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            manualListingScreenController.featureControllers.length, // number of items
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: CustomText(
                                    manualListingScreenController.featureControllers[index].text,
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                    // height: 1.2,
                                  ),
                                ),
                          ),
                        ),
                      ],

                        if(manualListingScreenController.linkController.text.isNotEmpty)
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
                                  onTap: ()=> launchURL(manualListingScreenController.linkController.text),
                                  child: CustomText(
                                    '${manualListingScreenController.linkController.text}',
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),

                        if(manualListingScreenController.detailsList.isNotEmpty)
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
                                      widget.generateAiProductContent.addMoreDetails!.length, // number of items
                                          (index) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: CustomText(
                                          '${manualListingScreenController.detailsList[index].title} - ${manualListingScreenController.detailsList[index].details}',
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.secondaryTextColor,
                                          // height: 1.2,
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
                  ),
                  SizedBox(height: SizeConfig.size10),

                  /// pricing & warranty
                  Container(
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
                                  Get.to(()=> Step3Section(controller: manualListingScreenController));
                                },
                                child: LocalAssets(imagePath: AppIconAssets.pen_line))
                          ],
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CommonHorizontalDivider(
                          height: 1.0,
                          color: AppColors.whiteE0,
                        ),

                        (manualListingScreenController.mrpController.text.isNotEmpty) ?
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
                                  "${manualListingScreenController.mrpController.text}",
                                  fontSize: SizeConfig.large,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondaryTextColor,
                                 ),
                              ),

                            ],
                          ),
                         ) : SizedBox(),

                        if(widget.generateAiProductContent.productWarranty!=null)
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
                                    "${widget.generateAiProductContent.productWarranty?.asText}",
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                    height: 1.5,
                                  ),
                              ),
                            ],
                          ),
                        ),

                        if(widget.generateAiProductContent.expiryTime!=null)
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
                                    "${widget.generateAiProductContent.expiryTime?.asText}",
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if(manualListingScreenController.guidelineController.text.isNotEmpty)
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
                              CustomText(
                                "${manualListingScreenController.guidelineController.text}",
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                                height: 1.5,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: SizeConfig.size5),

                        // Column(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: List.generate(
                        //     widget.generateAiProductContent.userGuide!.length, // number of items
                        //         (index) => Padding(
                        //       padding: const EdgeInsets.only(bottom: 4.0),
                        //       child: CustomText(
                        //         widget.generateAiProductContent.userGuide![index],
                        //         fontSize: SizeConfig.medium,
                        //         fontWeight: FontWeight.w400,
                        //         color: AppColors.secondaryTextColor,
                        //         height: 1.2,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size10),

                  /// Product variant
                  Container(
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
                              'Variant',
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                            ),
                            InkWell(
                                onTap: () {
                                  Get.to(()=> Step4Section(controller: manualListingScreenController));
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

                        // if(widget.generateAiProductContent.possibleVariants?.isNotEmpty ?? false)
                        //   ...[
                        //     Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: List.generate(
                        //         widget.generateAiProductContent.possibleVariants!.length, // number of items
                        //             (index) => Padding(
                        //               padding: const EdgeInsets.only(bottom: 4.0),
                        //               child: CustomText(
                        //                 widget.generateAiProductContent.possibleVariants![index],
                        //                       fontSize: SizeConfig.medium,
                        //                       fontWeight: FontWeight.w400,
                        //                       color: AppColors.secondaryTextColor,
                        //                 height: 1.2,
                        //               ),
                        //             ),
                        //       ),
                        //     ),
                        //     SizedBox(height: SizeConfig.size10),
                        //   ],

                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),

                  /// Submit
                  CustomBtn(
                    // title: addProductViaAiController.isLoading.value
                    //     ? null // hide text
                    //     : 'Generate',
                    title: 'Post Product',
                    onTap: addProductViaAiController.onGenerate,
                    bgColor: AppColors.primaryColor,
                    textColor: AppColors.white,
                    height: SizeConfig.size40,
                    radius: 10.0,
                    // isLoading: addProductViaAiController.isLoading.value
                  ),
                ],
              ),

            ),
            SizedBox(height: SizeConfig.size20),
          ],
        ),
      ),
    );
  }
}
