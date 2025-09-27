import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/view/create_varient_screen.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//// Need to add confirmation popup for data loss when back pressed

class ProductPreviewScreen extends StatefulWidget {
  final AddProductViaAiController controller;
  const ProductPreviewScreen({super.key, required this.controller});

  @override
  State<ProductPreviewScreen> createState() => _ProductPreviewScreenState();
}

class _ProductPreviewScreenState extends State<ProductPreviewScreen> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  late AddProductViaAiController controller;
  int _currentIndex = 0;

  @override
  void initState() {
    controller = widget.controller;
    super.initState();
  }

  void handleBackPress(BuildContext context) async {
     showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Do you really want to go back? Your product data will be lost.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Get.until(
                    (route) =>
                route.settings.name ==
                    RouteHelper.getInventoryScreenRoute(),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        handleBackPress(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteF3,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children:[
                    Container(
                      height: SizeConfig.size350,
                      color: AppColors.white,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          CarouselSlider.builder(
                            carouselController: _carouselController,
                            itemCount: controller.step2Images.length,
                            options: CarouselOptions(
                              height: SizeConfig.size350,
                              viewportFraction: 1.0,
                              enlargeCenterPage: false,
                              enableInfiniteScroll: false,
                              autoPlay: true,
                              onPageChanged: (index, reason) {
                                setState(() => _currentIndex = index);
                              },
                            ),
                            itemBuilder: (context, index, realIdx) {
                              return Image.file(
                                File(controller.step2Images[index]),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              );
                            },
                          ),

                          // 🔹 Positioned indicator at bottom
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(controller.step2Images.length, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  width: _currentIndex == index ? 8 : 6,
                                  height: _currentIndex == index ? 8 : 6,
                                  decoration: BoxDecoration(
                                    color: _currentIndex == index
                                        ? AppColors.primaryColor
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 15,
                      left: 15,
                      child: IconButton(
                      padding: EdgeInsets.zero,
                          onPressed:() {
                             handleBackPress(context);
                            },
                          icon: LocalAssets(
                            imagePath: AppIconAssets.back_arrow,
                            height: SizeConfig.paddingL,
                            width: SizeConfig.paddingL,
                            imgColor: Colors.black,
                          )),
                    ),
                  ],
                ),

                CustomFormCard(
                  margin: EdgeInsets.all(SizeConfig.size15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          controller.productNameController.text,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        SizedBox(
                          height: SizeConfig.size12,
                        ),
                        Row(
                          children: [
                            CustomText(
                              '₹00,000 ',
                              fontSize: 24.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainTextColor,
                            ),
                            SizedBox(
                              width: SizeConfig.size8,
                            ),
                            CustomText(
                              '50% Off ',
                              fontSize: 14.0,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                            CustomText(
                              '₹00,000 ',
                              fontSize: 14.0,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        )
                   ]
                  ),
                ),

                CustomFormCard(
                  margin: EdgeInsets.only(
                      left: SizeConfig.size15,
                      right: SizeConfig.size15,
                      bottom: SizeConfig.size15
                  ),
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
                        title: 'Create Variant - Start Selling',
                        onTap: (){
                          // Get.to(()=> CreateVariantScreen(controller: controller));

                          Get.toNamed(
                            RouteHelper.getCreateVariantScreenRoute(),
                            arguments: {
                              ApiKeys.controller: controller,
                            },
                          );

                          // controller.createProductViaAi(controller);
                        },
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white,
                        height: SizeConfig.size40,
                        radius: 10.0,
                        // isLoading: addProductViaAiController.isLoading.value
                      ),
                    ],
                  ),

                ),

              ],
            ),
          ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomText(
                'Product details',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CommonHorizontalDivider(
            height: 1.0,
            color: AppColors.whiteE0,
          ),
          // SizedBox(height: SizeConfig.size10),
          // Row(
          //   children: [
          //     CustomText(
          //       'Product Name: ',
          //       fontSize: SizeConfig.medium,
          //       fontWeight: FontWeight.w600,
          //       color: AppColors.secondaryTextColor,
          //     ),
          //
          //     Expanded(
          //       child: CustomText(
          //         controller.productNameController.text,
          //         fontSize: SizeConfig.medium,
          //         fontWeight: FontWeight.w400,
          //         color: AppColors.secondaryTextColor,
          //       ),
          //     ),
          //   ],
          // ),
          // SizedBox(height: SizeConfig.size10),
          //
          // Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     CustomText(
          //       'Brand: ',
          //       fontSize: SizeConfig.medium,
          //       fontWeight: FontWeight.w600,
          //       color: AppColors.secondaryTextColor,
          //     ),
          //     Expanded(
          //       child: CustomText(
          //         '${controller.brandController.text}',
          //         fontSize: SizeConfig.medium,
          //         fontWeight: FontWeight.w400,
          //         color: AppColors.secondaryTextColor,
          //       ),
          //     ),
          //
          //   ],
          // ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Variant',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
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

          if(controller.dynamicAttributes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: controller.dynamicAttributes.entries.map((entry) {
                final key = entry.key; // attribute name (e.g., "Size", "Pattern")
                final values = entry.value; // list of values under this attribute

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
                    SizedBox(height: SizeConfig.size8), // space between different attributes
                  ],
                );
              }).toList(),
            )


        ],
      ),
    );
  }


}
