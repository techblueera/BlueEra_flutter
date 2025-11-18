import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ProductPreviewArgs {
  final String? productId;
  final List<String>? media;
  final String? name;
  final String? description;
  final List<String>? tags;
  final List<String>? features;
  final String? link;
  final List<DetailPair>? details;
  final String? sellingPrice;
  final String? MRPPrice;
  final String? warranty;
  final String? expiry;
  final String? linkOrReferralUrl;
  final List<String>? userGuide;
  final List<ProductListing>? listedProducts; /// for seeing listed products

  /// Both will be used for available options
  final List<SelectedColor>? selectedColors;  /// for seeing all products
  final Map<String, List<String>>? dynamicAttributes;  /// we will send all the dynamic attribute available

  ProductPreviewArgs({
    this.productId,
    this.media,
    this.name,
    this.description,
    this.tags,
    this.features,
    this.link,
    this.details,
    this.sellingPrice,
    this.MRPPrice,
    this.warranty,
    this.expiry,
    this.linkOrReferralUrl,
    this.userGuide,
    this.selectedColors,
    this.dynamicAttributes,
    this.listedProducts,
  });
}

class DetailPair {
  final String? title;
  final String? detail;
  const DetailPair(this.title, this.detail);
}

class ProductPreviewScreen extends StatefulWidget {
  // final OwnProductData? productData;
  final String? id;
  final ProductServiceProviderType? providerType;
  final ProductPreviewArgs? productPreviewArgs;
  final bool isFromProductCreation;
  final bool isUserCanCreateVariants;

  const ProductPreviewScreen({
    super.key,
    required this.id,
    required this.providerType,
    required this.productPreviewArgs,
    required this.isFromProductCreation,
    required this.isUserCanCreateVariants});

  @override
  State<ProductPreviewScreen> createState() => _ProductPreviewScreenState();
}

class _ProductPreviewScreenState extends State<ProductPreviewScreen> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  final ProductController controller = Get.put(ProductController());
  int _currentIndex = 0;

  @override
  void initState() {
    if(widget.productPreviewArgs!=null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadPreviewArgs(widget.productPreviewArgs!);
      });
    }
    super.initState();
  }

  void loadPreviewArgs(ProductPreviewArgs args) {
    controller.productId = args.productId ?? '';

    controller.productNameController.text = args.name ?? '';
    controller.productDescriptionController.text = args.description ?? '';
    controller.linkController.text = args.linkOrReferralUrl ?? '';

    controller.selectedProductOrVariantMrp.value = args.MRPPrice ?? '';
    controller.selectedProductOrVariantPrice.value = args.sellingPrice ?? '';
    controller.selectedProductOrVariantDiscount.value = calculateDiscount(
        controller.selectedProductOrVariantPrice.value,
        controller.selectedProductOrVariantMrp.value.toString()
    ).toStringAsFixed(2);

    controller.mrpController.text = args.MRPPrice ?? '';
    controller.productWarrantyController.text = args.warranty ?? '';
    controller.productExpiryDurationController.text = args.expiry ?? '';

    // Reactive lists
    controller.allProductImages.assignAll(args.media ?? []);
    controller.tags.assignAll(args.tags ?? []);

    controller.featureControllers
      ..clear()
      ..addAll((args.features ?? []).map((f) => TextEditingController(text: f)));

    controller.detailsList.assignAll(
      (args.details ?? [])
          .map((d) => ProductMoreDetails(title: d.title, details: d.detail))
          .toList(),
    );

    controller.userGuideLineControllers
      ..clear()
      ..addAll((args.userGuide ?? []).map((g) => TextEditingController(text: g)));

    if ((args.listedProducts?.isNotEmpty ?? false)) {
      controller.listedProducts.assignAll(args.listedProducts!);
    }

    if ((args.selectedColors?.isNotEmpty ?? false)) {
      controller.selectedColors.assignAll(args.selectedColors!);
    }

    // Reactive map
    if (args.dynamicAttributes?.isNotEmpty ?? false) {
      controller.dynamicAttributes.clear();
      args.dynamicAttributes!.forEach((key, value) {
        controller.dynamicAttributes[key] = RxList(value);
      });
    }

//     log("""
// productId: ${args.productId}
// allProductsImages: ${args.media}
// productName: ${args.name}
// description: ${args.description}
// tags: ${args.tags}
// features: ${args.features}
// details: ${args.details?.map((d) => {"title": d.title, "detail": d.detail}).toList()}
// mrp: ${args.MRPPrice}
// warranty: ${args.warranty}
// expiry: ${args.expiry}
// userGuide: ${args.userGuide}
// listedProducts: ${args.listedProducts}
// selectedColors: ${args.selectedColors},
// dynamicAttributes: ${args.dynamicAttributes}
// """);

    setState(() {

    });
  }

  @override
  void dispose() {
    Get.delete<ProductController>();
    super.dispose();
  }

  void handleBackPress(BuildContext context) async {
    await showCommonDialog(
      context: context,
      text: AppStrings.doYouReallyWantToGoBack,
      confirmText: AppStrings.yes,
      cancelText: AppStrings.no,
      confirmCallback: () {
        Navigator.of(context).pop(); // Close dialog first

        if(widget.providerType == ProductServiceProviderType.business){
          bool navigated = false;
          Get.until((route) {
            if (route.settings.name == RouteHelper.getInventoryScreenRoute()) {
              navigated = true;
            }
            return navigated;
          });

          if (!navigated) {
            Get.until((route) => Get.currentRoute == RouteHelper.getBottomNavigationBarScreenRoute());
            Get.toNamed(RouteHelper.getInventoryScreenRoute());
          }
        }else if(widget.providerType == ProductServiceProviderType.user){
          Get.until((route) => Get.currentRoute == RouteHelper.getEarnWithBlueEraNewScreenRoute());
        }else if(widget.providerType == ProductServiceProviderType.channel){
          Get.until((route) => Get.currentRoute == RouteHelper.getChannelScreenRoute());
        }
      },
      cancelCallback: () {
        Navigator.of(context).pop(); // Just close dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: (widget.isFromProductCreation) ? false : true,
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
                      child: Obx(()=>  Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          CarouselSlider.builder(
                            carouselController: _carouselController,
                            itemCount: controller.allProductImages.length,
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
                              return !isNetworkImage(controller.allProductImages[index])
                                  ? Image.file(
                                File(controller.allProductImages[index]),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ) : CachedNetworkImage(
                                imageUrl: controller.allProductImages[index],
                                fit: BoxFit.contain,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image),
                                ),
                              );
                            },
                          ),

                          (controller.allProductImages.length > 1)
                              ? Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(controller.allProductImages.length, (index) {
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
                          ) : SizedBox(),
                        ],
                       ),
                      )

                    ),
                    Positioned(
                      top: 15,
                      left: 15,
                      child: IconButton(
                      padding: EdgeInsets.zero,
                          onPressed:() {
                            if(widget.isFromProductCreation == false) {
                              Get.back();
                              return;
                            }

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

                if(controller.listedProducts.isNotEmpty)
                 _buildListedProducts(),

                Obx(()=> CustomFormCard(
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

                        if(controller.selectedVariantIndex.value != - 1)
                          Padding(
                            padding: EdgeInsets.only(top: SizeConfig.size12),
                            child: Row(
                              children: [
                                CustomText(
                                  '₹${controller.selectedProductOrVariantPrice.value}',
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mainTextColor,
                                ),
                                SizedBox(
                                  width: SizeConfig.size8,
                                ),
                                CustomText(
                                  '₹${controller.selectedProductOrVariantMrp.value}',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryTextColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                CustomText(
                                  ' ${controller.selectedProductOrVariantDiscount.value}% Off ',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.green7F,
                                ),
                              ],
                            ),
                          )
                      ]
                  ),
                )),

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

                      _buildExpandableSection(title: AppStrings.productDetails, content: _buildProductDetailsContent(), initiallyExpanded: true),
                      _buildExpandableSection(title: AppStrings.productFeatures, content: _buildProductFeaturesContent()),
                      _buildExpandableSection(title: AppStrings.pricingAndWarranty, content: _buildPricingAndWarrantyContent()),

                      if((widget.productPreviewArgs?.selectedColors?.isNotEmpty ?? false)
                          ||  (widget.productPreviewArgs?.dynamicAttributes?.isNotEmpty ?? false))
                      _buildExpandableSection(title: AppStrings.variant, content: _buildProductVariantContent()),


                      SizedBox(height: SizeConfig.size20),

                      /// Submit
                      if(widget.isUserCanCreateVariants)
                      CustomBtn(
                        title: AppStrings.createVariantStartSelling,
                        onTap: (){
                            Get.toNamed(
                              RouteHelper.getCreateVariantScreenRoute(),
                              arguments: {
                                ApiKeys.controller: controller,
                                ApiKeys.id: widget.id,
                                ApiKeys.providerType: widget.providerType
                              },
                            );
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

  Widget _buildExpandableSection({
    required String title,
    required Widget content,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: SizeConfig.size8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.whiteE0),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: CustomText(
          title,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        childrenPadding: EdgeInsets.only(
            left: SizeConfig.size15,
            right: SizeConfig.size15,
            bottom: SizeConfig.size8
        ),
        children: [content],
      ),
    );
  }


  Widget _buildProductDetailsContent(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              '${AppStrings.tagsKeywords}: ',
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
    );
  }

  Widget _buildProductFeaturesContent(){
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


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
                    '${AppStrings.moreDetails}: ',
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
    );
  }

  Widget _buildPricingAndWarrantyContent(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (controller.selectedProductOrVariantMrp.isNotEmpty) ?
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Row(
            children: [
              CustomText(
                '${AppStrings.mrp}: ',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              Expanded(
                child: CustomText(
                  "${controller.selectedProductOrVariantMrp.value}",
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
                  '${AppStrings.productWarranty}: ',
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
                  '${AppStrings.expiryTime}: ',
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
                  '${AppStrings.userGuidance}: ',
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
    );
  }

  Widget _buildProductVariantContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if(controller.selectedColors.isNotEmpty)
          ...[
            CustomText(
              '${AppStrings.color}: ',
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
    );
  }

  Widget _buildListedProducts() {
    return CustomFormCard(
      margin: EdgeInsets.only(
          left: SizeConfig.size15,
          right: SizeConfig.size15,
          top: SizeConfig.size15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.listedVariants,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = 2;
              final crossSpacing = 6.0;
              final mainSpacing = 6.0;

              final itemWidth =
                  (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) /
                      crossAxisCount;

              return MasonryGridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.listedProducts.length,
                itemBuilder: (context, index) {
                  final product =  controller.listedProducts[index];
                  return ProductCard(
                    product,
                    width: itemWidth,
                    index: index
                  );
                },
              );
            },
          ),
        ],
      ),
    );

    // final Map<int, int> _currentIndices = {};
    // final Map<int, CarouselSliderController> _controllers = {};
    //
    // return  Obx(()=>
    // controller.listedProducts.isNotEmpty ?
    // CustomFormCard(
    //   margin: EdgeInsets.symmetric(vertical: SizeConfig.size20),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       CustomText(
    //         'Listing',
    //         fontWeight: FontWeight.bold,
    //         fontSize: SizeConfig.large,
    //         color: AppColors.mainTextColor,
    //       ),
    //       SizedBox(height: SizeConfig.size10),
    //       ListView.builder(
    //         shrinkWrap: true,
    //         itemCount: controller.listedProducts.length,
    //         physics: NeverScrollableScrollPhysics(),
    //         itemBuilder: (context, productIndex) {
    //           final product = controller.listedProducts[productIndex];
    //
    //           // init default values
    //           _currentIndices.putIfAbsent(productIndex, () => 0);
    //           _controllers.putIfAbsent(productIndex, () => CarouselSliderController());
    //
    //           return Container(
    //             margin: EdgeInsets.only(bottom: 16),
    //             decoration: BoxDecoration(
    //                 color: AppColors.whiteFE,
    //                 borderRadius: BorderRadius.circular(10),
    //                 border: Border.all(
    //                   color: AppColors.whiteE5,
    //                 )
    //             ),
    //             child: Row(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //
    //                 SizedBox(
    //                   width: 120,
    //                   height: 120,
    //                   child: Stack(
    //                     children: [
    //                       CarouselSlider.builder(
    //                         carouselController: _controllers[productIndex],
    //                         itemCount: product.image.length,
    //                         options: CarouselOptions(
    //                           height: 120,
    //                           viewportFraction: 1.0,
    //                           enlargeCenterPage: false,
    //                           enableInfiniteScroll: false,
    //                           onPageChanged: (index, reason) {
    //                             setState(() {
    //                               _currentIndices[productIndex] = index;
    //                             });
    //                           },
    //                         ),
    //                         itemBuilder: (context, imgIndex, realIdx) {
    //                           return ClipRRect(
    //                             borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
    //                             child: CachedNetworkImage(
    //                               imageUrl: product.image[imgIndex],
    //                               width: 120,
    //                               height: 120,
    //                               fit: BoxFit.cover,
    //                               placeholder: (context, url) => Container(
    //                                 color: Colors.grey[200],
    //                                 child: const Center(
    //                                   child: CircularProgressIndicator(strokeWidth: 2),
    //                                 ),
    //                               ),
    //                               errorWidget: (context, url, error) => Container(
    //                                 color: Colors.grey[200],
    //                                 child: const Icon(Icons.broken_image),
    //                               ),
    //                             ),
    //                           );
    //                         },
    //
    //                       ),
    //
    //                       Positioned(
    //                         bottom: 6,
    //                         left: 0,
    //                         right: 0,
    //                         child: Row(
    //                           mainAxisAlignment: MainAxisAlignment.center,
    //                           children: List.generate(product.image.length, (dotIndex) {
    //                             final isActive = _currentIndices[productIndex] == dotIndex;
    //                             return AnimatedContainer(
    //                               duration: const Duration(milliseconds: 300),
    //                               margin: const EdgeInsets.symmetric(horizontal: 3.0),
    //                               width: isActive ? 8 : 6,
    //                               height: isActive ? 8 : 6,
    //                               decoration: BoxDecoration(
    //                                 color: isActive ? AppColors.primaryColor : Colors.grey,
    //                                 shape: BoxShape.circle,
    //                               ),
    //                             );
    //                           }),
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //
    //
    //                 // ClipRRect(
    //                 //   borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
    //                 //   child: Container(
    //                 //     color: AppColors.whiteF1,
    //                 //     child: Image.file(
    //                 //       File(product.image[0]),
    //                 //       width: 120,
    //                 //       height: 120,
    //                 //       fit: BoxFit.cover,
    //                 //     ),
    //                 //   ),
    //                 // ),
    //
    //                 SizedBox(width: 12),
    //                 Flexible(
    //                   child: Padding(
    //                     padding: const EdgeInsets.symmetric(vertical: 8),
    //                     child: Column(
    //                       crossAxisAlignment: CrossAxisAlignment.start,
    //                       mainAxisAlignment: MainAxisAlignment.start,
    //                       children: [
    //                         CustomText(
    //                           product.name,
    //                           fontWeight: FontWeight.bold,
    //                           fontSize: SizeConfig.large,
    //                           color: AppColors.mainTextColor,
    //                         ),
    //                         SizedBox(height: 8),
    //
    //                         Row(
    //                           children: [
    //                             CustomText(
    //                               '₹${product.price}',
    //                               fontWeight: FontWeight.bold,
    //                               fontSize: SizeConfig.large,
    //                               color: AppColors.mainTextColor,
    //                             ),
    //                             SizedBox(width: 8),
    //                             CustomText(
    //                               '₹${product.mrp}',
    //                               fontWeight: FontWeight.bold,
    //                               fontSize: SizeConfig.medium,
    //                               color: AppColors.secondaryTextColor,
    //                               decoration: TextDecoration.lineThrough,
    //                             ),
    //                             SizedBox(width: 8),
    //                             CustomText(
    //                               '${product.discount}% off',
    //                               fontWeight: FontWeight.bold,
    //                               fontSize: SizeConfig.medium,
    //                               color: Colors.green,
    //                             ),
    //                           ],
    //                         )
    //
    //                         // product.discount != null
    //                         //     ? Row(
    //                         //   children: [
    //                         //     CustomText(
    //                         //       '₹${product.price}',
    //                         //       fontWeight: FontWeight.bold,
    //                         //       fontSize: SizeConfig.large,
    //                         //       color: AppColors.mainTextColor,
    //                         //     ),
    //                         //     SizedBox(width: 8),
    //                         //     CustomText(
    //                         //       '₹${product.mrp}',
    //                         //       fontWeight: FontWeight.bold,
    //                         //       fontSize: SizeConfig.medium,
    //                         //       color: AppColors.secondaryTextColor,
    //                         //       decoration: TextDecoration.lineThrough,
    //                         //     ),
    //                         //     SizedBox(width: 8),
    //                         //     CustomText(
    //                         //       '${product.discount}% off',
    //                         //       fontWeight: FontWeight.bold,
    //                         //       fontSize: SizeConfig.medium,
    //                         //       color: Colors.green,
    //                         //     ),
    //                         //   ],
    //                         // ) : Row(
    //                         //   children: [
    //                         //     CustomText(
    //                         //       '₹${product.minPrice}-${product.maxPrice}',
    //                         //       fontWeight: FontWeight.bold,
    //                         //       fontSize: SizeConfig.large,
    //                         //       color: AppColors.secondaryTextColor
    //                         //     )
    //                         //   ],
    //                         // ),
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           );
    //         },
    //       ),
    //     ],
    //   ),
    // )
    //     : SizedBox()
    // );
  }

  Widget ProductCard(
      ProductListing product,
     {
        required double width,
       required int index,
     }) {
    return Obx(() {
      final isSelected = controller.selectedVariantIndex.value == index;

      return GestureDetector(
        onTap: () {
          // Toggle selection
          if (isSelected) {
            controller.selectedVariantIndex.value = -1;
            controller.allProductImages.value = widget.productPreviewArgs?.media??[];
            controller.selectedProductOrVariantPrice.value = '00, 000';
            controller.selectedProductOrVariantMrp.value = '00,000';
            controller.selectedProductOrVariantDiscount.value = '0';
          } else {
            controller.selectedVariantIndex.value = index; // select
            controller.allProductImages.value = product.image;
            controller.productNameController.text = product.name;
            controller.selectedProductOrVariantPrice.value = product.price ?? '00,000';
            controller.selectedProductOrVariantMrp.value = product.mrp ?? '00,000';
            controller.selectedProductOrVariantDiscount.value = product.discount ?? '0';
          }
        },
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.whiteFE,
            boxShadow: isSelected ? null : [AppShadows.cardShadow],
            borderRadius:  BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
              width: 1.5
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 1.2, // square-ish image (adjust if needed)
                child: Stack(
                  children: [
                    CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: double.infinity,
                      imagePaths: product.image,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildIconBox(
                          InkWell(
                              onTap: ()=> showSelectedVariantsDialog(context, product.selectedVariants),
                              child: Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 16))
                      ),
                    ),
                  ],
                ),
              ),

              // Product Details
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    CustomText(
                      product.name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price Row
                    Row(
                      children: [
                        CustomText(
                          '₹${product.price}',
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                        ),
                        const SizedBox(width: 8),
                        CustomText(
                          ' ₹${product.mrp}',
                          fontSize: SizeConfig.small11,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                        ),
                        CustomText(
                          ' ${product.discount}% ${AppStrings.off}',
                          fontSize: SizeConfig.small11,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w400,
                        ),

                      ],
                    ),
                    const SizedBox(height: 6),

                    // Status
                    CustomText(
                      AppStrings.activeProducts,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.small11,
                      color: AppColors.primaryColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });

  }

  Widget _buildIconBox(Widget child) {
    return Container(
      height: 25,
      width: 25,
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [AppShadows.textFieldShadow]
      ),
      alignment: Alignment.center,
      child: child,
    );
  }


  void showSelectedVariantsDialog(BuildContext context, Map<String, dynamic>? selectedVariants) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.only(
                top: 8.0,
                left: 16.0,
                right: 16.0,
                bottom: 16.0
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        AppStrings.selectedVariants,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

                // Variants list
                if (selectedVariants != null && selectedVariants.isNotEmpty)
                  buildVariantsList(selectedVariants)
                else
                  const CustomText(
                      AppStrings.noVariantsSelected,
                      fontSize: 14,
                      color: Colors.grey
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVariantRow(String key, dynamic value) {
    // Handle color variant specially
    if (key == 'color' && value is Map<String, dynamic>) {
      final color = SelectedColor.fromJson(value);

      return Row(
        children: [
          CustomText(
            "$key : ",
            fontSize: SizeConfig.large,
          ),
          CustomText(
            color.name,
            fontSize: SizeConfig.medium,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 6),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.greyE5, width: 2.0),
            ),
          ),
        ],
      );
    }

    // Default text-only variant
    return Row(
      children: [
        CustomText(
          "$key : ",
          fontSize: SizeConfig.large,
        ),
        CustomText(
          "$value",
          fontSize: SizeConfig.medium,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }


  Widget buildVariantsList(Map<String, dynamic> selectedVariants) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: selectedVariants.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: _buildVariantRow(entry.key, entry.value)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

