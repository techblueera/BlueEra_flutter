import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/listing_form_screen_controller.dart';
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
    // WidgetsBinding.instance.addPostFrameCallback((_) {
      addProductViaAiController.preloadStep1ImagesToStep2();
    // });
    super.initState();
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
                                  // Empty slot -> pick new image
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

                     Container(
                       padding: EdgeInsets.all(10.0),
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(10.0),
                         border: Border.all(
                             color: AppColors.whiteE0,
                         ),
                         color: Colors.white
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           CustomText(
                             widget.generateAiProductContent.productName,
                             fontSize: SizeConfig.medium,
                             fontWeight: FontWeight.w400,
                             color: AppColors.secondaryTextColor,
                           ),
                           SizedBox(height: SizeConfig.size10),
                           // CustomText(
                           //   addProductViaAiRequest.category,
                           //   fontSize: SizeConfig.medium,
                           //   fontWeight: FontWeight.w600,
                           //   color: AppColors.primaryColor,
                           // ),
                           // SizedBox(height: SizeConfig.size10),
                           ExpandableText(
                             text: widget.generateAiProductContent.productDescription??'',
                             trimLines: 4,
                             style: TextStyle(
                               color: AppColors.grey60,
                               fontSize: SizeConfig.medium,
                               fontWeight: FontWeight.w600,
                             ),
                             expandMode: ExpandMode.dialog,
                             dialogTitle: 'Video Description',
                           ),
                         ],
                       ),
                     ),

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
                                onTap: () {},
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
                                '${widget.generateAiProductContent.specifications?.brand}',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),

                          ],
                        ),
                        SizedBox(height: SizeConfig.size10),
                        (widget.generateAiProductContent.seoKeywordTags?.isNotEmpty ?? false)
                            ? CustomText(
                          '${widget.generateAiProductContent.seoKeywordTags!.join(', ')}', /// Keyword/tegs
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                          height: 1.5,
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
                                onTap: () {},
                                child: LocalAssets(imagePath: AppIconAssets.pen_line))
                          ],
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CommonHorizontalDivider(
                          height: 1.0,
                          color: AppColors.whiteE0,
                        ),
                        SizedBox(height: SizeConfig.size10),

                        if(widget.generateAiProductContent.features?.isNotEmpty ?? false)
                        ...[
                          Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            widget.generateAiProductContent.features!.length, // number of items
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: CustomText(
                                    widget.generateAiProductContent.features![index],
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                    // height: 1.2,
                                  ),
                                ),
                          ),
                        ),
                          SizedBox(height: SizeConfig.size10),
                        ]
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
                                onTap: () {},
                                child: LocalAssets(imagePath: AppIconAssets.pen_line))
                          ],
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CommonHorizontalDivider(
                          height: 1.0,
                          color: AppColors.whiteE0,
                        ),
                        SizedBox(height: SizeConfig.size10),

                        widget.generateAiProductContent.approxMrpInr!='0' ?
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.0),
                          child: CustomText(
                            "${widget.generateAiProductContent.approxMrpInr}",
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryTextColor,
                           ),
                         ) : SizedBox(),

                        CustomText(
                            "${widget.generateAiProductContent.expiryOrWarranty}",
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                            height: 1.5,
                          ),

                        SizedBox(height: SizeConfig.size10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'User Guidance: ',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryTextColor,
                            ),
                            Expanded(
                              child: CustomText(
                                '${widget.generateAiProductContent.userGuide}',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: AppColors.secondaryTextColor,
                                height: 1.5,
                              ),
                            ),

                          ],
                        ),
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
                                onTap: () {},
                                child: LocalAssets(imagePath: AppIconAssets.pen_line))
                          ],
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CommonHorizontalDivider(
                          height: 1.0,
                          color: AppColors.whiteE0,
                        ),
                        SizedBox(height: SizeConfig.size10),

                        if(widget.generateAiProductContent.possibleVariants?.isNotEmpty ?? false)
                          ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                widget.generateAiProductContent.possibleVariants!.length, // number of items
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: CustomText(
                                        widget.generateAiProductContent.possibleVariants![index],
                                              fontSize: SizeConfig.medium,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.secondaryTextColor,
                                        height: 1.2,
                                      ),
                                    ),
                              ),
                            ),
                            SizedBox(height: SizeConfig.size10),
                          ],

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
