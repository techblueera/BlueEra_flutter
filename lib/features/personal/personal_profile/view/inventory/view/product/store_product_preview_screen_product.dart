import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class StoreProductPreviewScreenProduct extends StatefulWidget {
  final ProductStore? productStore;
  // final bool? isShowBusinessInfo;
  final String? id;
  final ProductServiceProviderType? providerType;

  const StoreProductPreviewScreenProduct(
      { super.key,
        required this.productStore,
        // this.isShowBusinessInfo,
        this.id,
        this.providerType});

  @override
  State<StoreProductPreviewScreenProduct> createState() =>
      _StoreProductPreviewScreenProductState();
}

class _StoreProductPreviewScreenProductState
    extends State<StoreProductPreviewScreenProduct> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ProductController controller = Get.put(ProductController());
  int _currentIndex = 0;
  bool isOwnProduct = false;

  @override
  void initState() {
    if (widget.productStore != null) {
      // Check Who's prdouct
      isOwnProduct = widget.productStore?.sellerClassification?.owner?.id == userId;

      controller.step2Images.value =
          widget.productStore?.details?.media ?? [];
      controller.productNameController.text =
          widget.productStore?.details?.name ?? '';
      controller.productDescriptionController.text =
          widget.productStore?.details?.description ?? '';
      controller.tags.value = widget.productStore?.details?.tags ?? [];
      List<ProductFeature> features =
          widget.productStore?.details?.addProductFeatures ?? [];
      if (features.isNotEmpty) {
        for (final feature in features) {
          controller.featureControllers
              .add(TextEditingController(text: feature.title));
        }
      }
      // controller.linkController.text = widget.productData?.product.details?.name??'';
      late List<AddMoreDetail> tempDetailsList =
          widget.productStore?.details?.addMoreDetails ?? [];
      controller.detailsList.value = tempDetailsList.map((spec) {
        return ProductMoreDetails(
          title: spec.title,
          details: spec.details,
        );
      }).toList();
      controller.mrpController.text =
          widget.productStore?.details?.mrpPerUnit.toString() ?? '0.0';
      controller.productWarrantyController.text =
          widget.productStore?.details?.productWarranty ?? '';
      // controller.productExpiryDurationController.text = widget.productData?.product.details?.produ??'';
      // controller.productExpiryDurationController.text = widget.productData?.product.details?.produ??'';
      // List<String> userGuide = widget.productData.userGuide ?? [];
      // if(userGuide.isNotEmpty){
      //   for (final guideLine in userGuide) {
      //     controller.userGuideLineControllers.add(TextEditingController(text: guideLine));
      //   }
      // }
      controller.listedProducts.clear();
      List<Variant> variants =
          widget.productStore?.sellerClassification?.variants ?? [];
      if (variants.isNotEmpty) {
        controller.listedProducts.value = widget
                .productStore?.sellerClassification?.variants
                .map((variant) {
              return ProductListing(id: variant.id,
                image: variant.mediaRelatedToVariant.isNotEmpty
                    ? variant.mediaRelatedToVariant
                    : [],
                name:
                    '${widget.productStore?.details?.name}  ${variant.attributes.values.map((v) => v.toString()).join()}',
                selectedVariants: variant.attributes
                    .map((key, value) => MapEntry(key, value)),
                price: variant.sellingPrice.toString(),
                mrp: variant.mrp.toString(),
                discount: variant.mrp > 0
                    ? (((variant.mrp - variant.sellingPrice) / variant.mrp) *
                            100)
                        .toStringAsFixed(2)
                    : null,
              );
            }).toList() ??
            [];
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<ProductController>();
    super.dispose();
  }

  void handleBackPress(BuildContext context) async {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(AppStrings.discardChanges),
        content: const CustomText(
            AppStrings.doYouReallyWantToGoBack
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const CustomText(AppStrings.no),
          ),
          TextButton(
            onPressed: () {
              Get.until(
                (route) =>
                    route.settings.name ==
                    RouteHelper.getInventoryScreenRoute(),
              );
            },
            child: const CustomText(AppStrings.yes),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: (widget.productStore != null) ? true : false,
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
                  children: [
                    Container(
                        height: SizeConfig.size350,
                        color: AppColors.white,
                        child: Obx(
                          () => Stack(
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
                                  final imagePath = controller.step2Images[index];
                                  final isNetwork = isNetworkImage(imagePath);

                                  return InkWell(
                                    onTap: () {
                                      navigatePushTo(
                                        Get.context!,
                                        ImageViewScreen(
                                          subTitle: '',
                                          appBarTitle: widget.productStore?.business_name?.capitalizeFirst ?? '',
                                          imageUrls: controller.step2Images,
                                          initialIndex: realIdx,
                                        ),
                                      );
                                    },
                                    child: isNetwork
                                        ? CachedNetworkImage(
                                      imageUrl: imagePath,
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
                                    )
                                        : Image.file(
                                      File(imagePath),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                  );

                                },
                              ),
                              (controller.step2Images.length > 1)
                                  ? Positioned(
                                      bottom: 8,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                            controller.step2Images.length,
                                            (index) {
                                          return AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4.0),
                                            width:
                                                _currentIndex == index ? 8 : 6,
                                            height:
                                                _currentIndex == index ? 8 : 6,
                                            decoration: BoxDecoration(
                                              color: _currentIndex == index
                                                  ? AppColors.primaryColor
                                                  : Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        }),
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          ),
                        )),
                    Positioned(
                      top: 15,
                      left: 15,
                      child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (widget.productStore != null) {
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
                // if (widget.isShowBusinessInfo ?? false)
                  if (widget.productStore != null &&
                      widget.productStore?.business_name != null &&
                      widget.productStore?.user_id != null)
                    InkWell(
                      onTap: (){
                        final owner = widget.productStore?.sellerClassification?.owner;
                        final ownerId = owner?.id ?? '';
                        final screen = AppConstants.storeFeedScreen;

                        if (owner == null) return;

                        final isBusiness = owner.type == ProductServiceProviderType.business.title;

                        final destination = isBusiness
                            ? VisitBusinessProfileNew(
                          businessId: ownerId,
                          screenName: screen,
                        )
                            : NewVisitProfileScreen(
                          authorId: ownerId,
                          screenFromName: screen,
                        );

                        Get.to(() => destination);

                      },
                      child: CustomFormCard(
                        margin: EdgeInsets.only(
                            left: SizeConfig.size15,
                            right: SizeConfig.size15,
                            top: SizeConfig.size15),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey,
                              backgroundImage: widget
                                          .productStore?.business_logo !=
                                      null
                                  ? NetworkImage(
                                      widget.productStore?.business_logo ??
                                          "")
                                  : null,
                              child: widget.productStore?.business_logo ==
                                      null
                                  ? CustomText(
                                      getInitials(widget
                                          .productStore?.business_name),
                                      fontSize: SizeConfig.size18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: SizeConfig.size10),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        widget.productStore?.business_name
                                                ?.capitalizeFirst ??
                                            AppStrings.na,
                                        fontSize: SizeConfig.large18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.mainTextColor,
                                        maxLines: 2,
                                      ),
                                      // SizedBox(
                                      //   height: SizeConfig.size5,
                                      // ),
                                      CustomText(
                                        widget.productStore?.category ??
                                            AppStrings.na,
                                        fontSize: SizeConfig.large,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.mainTextColor,
                                        maxLines: 1,
                                      ),
                                    ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                if (widget.productStore != null)
                  if (controller.listedProducts.isNotEmpty)
                    _buildListedProducts(),
                /*   CustomFormCard(
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
                      ]),
                ),*/
                CustomFormCard(
                  margin: EdgeInsets.only(
                      left: SizeConfig.size15,
                      right: SizeConfig.size15,
                      bottom: SizeConfig.size15),
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
                      _buildExpandableSection(
                          title: AppStrings.productDetails,
                          content: _buildProductDetailsContent(),
                          initiallyExpanded: true),
                      _buildExpandableSection(
                          title: AppStrings.productFeatures,
                          content: _buildProductFeaturesContent()),
                      _buildExpandableSection(
                          title: AppStrings.pricingWarranty,
                          content: _buildPricingAndWarrantyContent()),
                      if (widget.productStore == null)
                        _buildExpandableSection(
                            title: AppStrings.variant,
                            content: _buildProductVariantContent()),
                      SizedBox(height: SizeConfig.size20),
                      if (widget.productStore == null)

                        /// Submit
                        CustomBtn(
                          title: AppStrings.createVariantStartSelling,
                          onTap: () {
                            if (widget.productStore == null) {
                              Get.toNamed(
                                RouteHelper.getCreateVariantScreenRoute(),
                                arguments: {
                                  ApiKeys.controller: controller,
                                  ApiKeys.id: widget.id,
                                  ApiKeys.providerType: widget.providerType
                                },
                              );
                            }
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
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: CustomText(
          title,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        childrenPadding: EdgeInsets.only(
            left: SizeConfig.size15,
            right: SizeConfig.size15,
            bottom: SizeConfig.size8),
        children: [content],
      ),
    );
  }

  Widget _buildProductDetailsContent() {
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
                    '${AppStrings.tagsKeywords.tr}: ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size3),
                  CustomText(
                    '${controller.tags.join(', ')}',

                    /// Keyword/tegs
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                    height: 1.5,
                  ),
                ],
              )
            : SizedBox(),
      ],
    );
  }

  Widget _buildProductFeaturesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        // height: 1.2,
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

  Widget _buildPricingAndWarrantyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (controller.mrpController.text.isNotEmpty)
            ? Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Row(
                  children: [
                    CustomText(
                      '${AppStrings.mrp.tr}: ',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    Expanded(
                      child: CustomText(
                        "₹${controller.mrpController.text}",
                        // fontSize: SizeConfig.large,
                        // fontWeight: FontWeight.w700,
                        // color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              )
            : SizedBox(),
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
                    // number of items
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
        if (controller.dynamicAttributes.isNotEmpty)
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
                  SizedBox(height: SizeConfig.size8),
                  // space between different attributes
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

              final itemWidth = (constraints.maxWidth -
                      ((crossAxisCount - 1) * crossSpacing)) /
                  crossAxisCount;

              return MasonryGridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.listedProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.listedProducts[index];
                  return ProductCard(product, width: itemWidth, index: index);
                },
              );
            },
          ),
        ],
      ),
    );

  }

  Widget ProductCard(
    ProductListing product, {
    required double width,
    required int index,
  }) {
    return Obx(() {
      final isSelected = controller.selectedVariantIndex.value == index;

      return GestureDetector(
        onTap: () {
          // Toggle selection
          if (isSelected) {
            controller.selectedVariantIndex.value = -1; // unselect
            controller.step2Images.value =
                widget.productStore?.details?.media ?? [];
          } else {
            controller.selectedVariantIndex.value = index; // select
            controller.step2Images.value = product.image; // variant photo
          }
        },
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.whiteFE,
            boxShadow: isSelected ? null : [AppShadows.cardShadow],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                width: 1.5),
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
                      child: _buildIconBox(InkWell(
                          onTap: () => showSelectedVariantsDialog(
                              context, product.selectedVariants),
                          child: Icon(Icons.remove_red_eye_outlined,
                              color: Colors.white, size: 16))),
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
                          ' ${product.discount}% ${AppStrings.off.tr}',
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

              if(!isOwnProduct)
              InkWell(
                onTap:
                // (!isOwnProduct) ?
                    () async {
                  if (isGuestUser()) {
                    createProfileScreen();

                    return;
                  }
                  final chatViewController = Get.find<ChatViewController>();
                  Map<String, dynamic> detas = {
                    ApiKeys.user_id: widget.productStore?.user_id
                  };
                  chatViewController.newVisitContactApiResponse?.value;
                  await chatViewController.checkChatConnection(detas);
                  List<Map<String, String>> urlList =
                  product.image.map((e) => {"url": e}).toList();
                  Map<String, dynamic> data = {
                    ApiKeys.product_id:"${product.id}",

                    ApiKeys.price: "${product.price}",
                    ApiKeys.discount: "${product.discount}",
                    if ((chatViewController.newVisitContactApiResponse
                        ?.value?.data?.conversationId ==
                        '' ||
                        chatViewController.newVisitContactApiResponse
                            ?.value?.data?.conversationId ==
                            null))
                      ApiKeys.other_user_id: (chatViewController
                          .newVisitContactApiResponse
                          ?.value
                          ?.data
                          ?.otherUserId ??
                          '')
                    else
                      ApiKeys.conversation_id: (chatViewController
                          .newVisitContactApiResponse
                          ?.value
                          ?.data
                          ?.conversationId ??
                          ''),
                    ApiKeys.message:
                    "${product.name}",
                    ApiKeys.message_type: "product",
                    ApiKeys.title: product.name,
                    ApiKeys.variant : jsonEncode(product.selectedVariants),
                    ApiKeys.mrp :product.mrp,
                    ApiKeys.url: urlList,
                  };
                  chatViewController.openAnyOneChatFunction(
                    shareProductParams: data,
                    isWithProductSend: true,
                    profileImage: widget.productStore?.business_logo,
                    otherUserId: (chatViewController.newVisitContactApiResponse
                                    ?.value?.data?.conversationId ??
                                '') ==
                            ""
                        ? chatViewController.newVisitContactApiResponse?.value
                                ?.data?.otherUserId ??
                            ''
                        : null,
                    // businessId: widget
                    //     .productStore?.sellerClassification?.owner?.id,
                    type: "business",
                    isInitialMessage: (chatViewController
                                    .newVisitContactApiResponse
                                    ?.value
                                    ?.data
                                    ?.conversationId ??
                                '') ==
                            ""
                        ? true
                        : false,
                    userId: widget.productStore?.user_id,
                    conversationId: (chatViewController
                            .newVisitContactApiResponse
                            ?.value
                            ?.data
                            ?.conversationId ??
                        ''),
                    contactName: widget.productStore?.business_name,
                    contactNo: widget.productStore?.mobile_no,
                  );
                },
                // : null,
                child: Container(
                  // width: Get.width,
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size15,
                      vertical: SizeConfig.size5),
                  margin: EdgeInsets.only(
                      top: SizeConfig.size5,
                      left: SizeConfig.size15,
                      right: SizeConfig.size15,
                      bottom: SizeConfig.size8),
                  child: CustomText(
                    AppStrings.chat,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.primaryColor)
                      // color: (!isOwnProduct) ? AppColors.primaryColor : Colors.grey,
                      // borderRadius: BorderRadius.circular(5),
                      // border: Border.all(color: (!isOwnProduct) ? AppColors.primaryColor : Colors.grey)
                  ),
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
          boxShadow: [AppShadows.textFieldShadow]),
      alignment: Alignment.center,
      child: child,
    );
  }

  void showSelectedVariantsDialog(
      BuildContext context, Map<String, dynamic>? selectedVariants) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.only(
                top: 8.0, left: 16.0, right: 16.0, bottom: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Expanded(
                      child: const CustomText(
                        AppStrings.selectedVariants,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                  const Icon(Icons.check_circle, color: Colors.blue, size: 20),
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
