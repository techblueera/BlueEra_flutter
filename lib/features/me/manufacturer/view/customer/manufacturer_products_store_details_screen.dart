import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/manufacturer/view/customer/manufacturer_visit_product_store_details_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ManufacturerProductsStoreDetailsScreen extends StatefulWidget {
  final ProductStore? productStore;
  final String? id;
  final ProviderType? providerType;

  const ManufacturerProductsStoreDetailsScreen({
    super.key,
    required this.productStore,
    this.id,
    this.providerType,
  });

  @override
  State<ManufacturerProductsStoreDetailsScreen> createState() =>
      _ProductsStoreDetailsScreenState();
}

class _ProductsStoreDetailsScreenState
    extends State<ManufacturerProductsStoreDetailsScreen> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ManufacturerProductController controller =
      Get.find<ManufacturerProductController>();
  int _currentIndex = 0;
  bool isOwnProduct = false;

  @override
  void initState() {
    if (widget.productStore != null) {
      isOwnProduct =
          widget.productStore?.sellerClassification?.owner?.id == userId;

      controller.step2Images.value = widget.productStore?.details?.media ?? [];
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

      late List<AddMoreDetail> tempDetailsList =
          widget.productStore?.details?.addMoreDetails ?? [];
      controller.detailsList.value = tempDetailsList.map((spec) {
        return ManufacturerProductMoreDetails(
          title: spec.title,
          details: spec.details,
        );
      }).toList();

      controller.mrpController.text =
          widget.productStore?.details?.mrpPerUnit.toString() ?? '0.0';
      controller.productWarrantyController.text =
          widget.productStore?.details?.productWarranty ?? '';

      controller.listedProducts.clear();
      List<Variant> variants =
          widget.productStore?.sellerClassification?.variants ?? [];
      if (variants.isNotEmpty) {
        controller.listedProducts.value =
            widget.productStore?.sellerClassification?.variants.map((variant) {
                  return ManufacturerProductListing(
                    id: variant.id,
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
                        ? (((variant.mrp - variant.sellingPrice) /
                                    variant.mrp) *
                                100)
                            .toStringAsFixed(0)
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
    deleteIfRegistered<ManufacturerProductController>();
    super.dispose();
  }

  void handleBackPress(BuildContext context) async {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(AppStrings.discardChanges),
        content: const CustomText(AppStrings.doYouReallyWantToGoBack),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const CustomText(AppStrings.no),
          ),
          TextButton(
            onPressed: () {
              Get.until(
                (route) =>
                    route.settings.name == RouteHelper.getProductScreenRoute(),
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
      canPop: widget.productStore != null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        handleBackPress(context);
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          // title: controller.productNameController.text.isNotEmpty
          //     ? controller.productNameController.text
          //     : AppStrings.productDetails,
          title: AppStrings.productDetails,
          onBackTap: () {
            if (widget.productStore != null) {
              Get.back();
              return;
            }
            handleBackPress(context);
          },
        ),
        bottomNavigationBar: _buildBottomBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// IMAGE CAROUSEL
                _buildImageCarousel(),

                SizedBox(height: SizeConfig.paddingXS),

                /// PRODUCT TITLE & PRICE
                _buildProductInfoCard(),

                SizedBox(height: SizeConfig.paddingXS),

                /// SELLER INFO
                if (widget.productStore != null &&
                    widget.productStore?.business_name != null)
                  _buildSellerCard(),

                SizedBox(height: SizeConfig.paddingXS),

                /// VARIANTS
                if (widget.productStore != null &&
                    controller.listedProducts.isNotEmpty)
                  _buildListedProducts(),

                SizedBox(height: SizeConfig.paddingXS),

                /// PRODUCT DESCRIPTION
                _buildDescriptionSection(),

                SizedBox(height: SizeConfig.paddingXS),

                /// FEATURES
                _buildFeaturesSection(),

                SizedBox(height: SizeConfig.paddingXS),

                /// MORE DETAILS
                _buildMoreDetailsSection(),

                SizedBox(height: SizeConfig.paddingXS),

                /// PRICING & WARRANTY
                _buildPricingSection(),

                SizedBox(height: SizeConfig.paddingXS),

                /// VARIANT OPTIONS (for new product creation)
                if (widget.productStore == null) _buildVariantOptionsSection(),

                SizedBox(height: SizeConfig.size100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE CAROUSEL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildImageCarousel() {
    return Stack(
      children: [
        Container(
          height: SizeConfig.size350,
          color: AppColors.white,
          child: Obx(() {
            if (controller.step2Images.isEmpty) {
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      size: 60, color: Colors.grey[400]),
                ),
              );
            }
            return Stack(
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
                            appBarTitle: widget.productStore?.business_name
                                    ?.capitalizeFirst ??
                                '',
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
                              placeholder: (_, __) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey[400]),
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
                if (controller.step2Images.length > 1)
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.paddingS,
                          vertical: SizeConfig.size4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomText(
                        "${_currentIndex + 1}/${controller.step2Images.length}",
                        fontSize: SizeConfig.size12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCT INFO CARD (Title, Price, Tags)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProductInfoCard() {
    final name = controller.productNameController.text;
    final firstVariant =
        widget.productStore?.sellerClassification?.variants.firstOrNull;
    final sellingPrice = firstVariant?.sellingPrice;
    final mrp = firstVariant?.mrp;
    final discount = (mrp != null && mrp > 0 && sellingPrice != null)
        ? (((mrp - sellingPrice) / mrp) * 100).toInt()
        : 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ManufacturerProduct name
            CustomText(
              name.isNotEmpty ? name : "Untitled ManufacturerProduct",
              fontSize: SizeConfig.size18,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 3,
            ),

            SizedBox(height: SizeConfig.paddingXS),

            // Price row
            if (sellingPrice != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    '₹$sellingPrice',
                    fontSize: SizeConfig.size24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                  if (mrp != null && mrp != sellingPrice) ...[
                    SizedBox(width: SizeConfig.paddingXS),
                    CustomText(
                      '₹$mrp',
                      fontSize: SizeConfig.size14,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                    SizedBox(width: SizeConfig.paddingXS),
                    if (discount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingXS,
                            vertical: SizeConfig.size2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          "$discount% OFF",
                          fontSize: SizeConfig.size12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ],
              ),
            ],

            // Tags
            if (controller.tags.isNotEmpty) ...[
              SizedBox(height: SizeConfig.paddingS),
              Wrap(
                spacing: SizeConfig.paddingXS,
                runSpacing: SizeConfig.size4,
                children: controller.tags
                    .map(
                      (tag) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingXS,
                            vertical: SizeConfig.size2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomText(
                          tag,
                          fontSize: SizeConfig.size11,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SELLER CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSellerCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          final owner = widget.productStore?.sellerClassification?.owner;
          if (owner == null) return;
          final ownerId = owner.id;
          final screen = AppConstants.storeFeedScreen;
          final isBusiness = owner.type == ProviderType.business.title;
          debugPrint('owner type -- ${owner.type}');
          debugPrint('id -- ${owner.id}');
          final destination = isBusiness
              ? ManufacturerVisitProductStoreDetailsScreen(
                  visitBusinessId: ownerId)
              : NewVisitProfileScreen(
                  authorId: ownerId, screenFromName: screen);
          Get.to(() => destination);
        },
        child: CommonCardWidget(
          cardMargin: 0,
          child: Row(
            children: [
              // Seller avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                backgroundImage:
                    (widget.productStore?.business_logo ?? '').isNotEmpty
                        ? NetworkImage(widget.productStore!.business_logo!)
                        : null,
                child: (widget.productStore?.business_logo ?? '').isEmpty
                    ? CustomText(
                        getInitials(widget.productStore?.business_name),
                        fontSize: SizeConfig.size16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      )
                    : null,
              ),
              SizedBox(width: SizeConfig.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      widget.productStore?.business_name?.capitalizeFirst ??
                          AppStrings.na,
                      fontSize: SizeConfig.size14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((widget.productStore?.category ?? '').isNotEmpty)
                      CustomText(
                        widget.productStore!.category!,
                        fontSize: SizeConfig.size12,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: SizeConfig.size16, color: AppColors.secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DESCRIPTION SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDescriptionSection() {
    final desc = controller.productDescriptionController.text;
    if (desc.isEmpty) {
      return _sectionCard(
        icon: Icons.description_outlined,
        title: AppStrings.productDescription,
        child: const EmptyStateWidget(
          message: "No description added.",
          imageSize: 40,
        ),
      );
    }
    return _sectionCard(
      icon: Icons.description_outlined,
      title: AppStrings.productDescription,
      child: ExpandableText(
        text: desc,
        trimLines: 4,
        style: TextStyle(
          fontSize: SizeConfig.size13,
          color: AppColors.secondaryTextColor,
          height: 1.5,
        ),
        expandMode: ExpandMode.dialog,
        dialogTitle: AppStrings.productDescription,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FEATURES SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFeaturesSection() {
    final hasFeatures = controller.featureControllers.isNotEmpty;
    final hasLink = controller.linkController.text.isNotEmpty;

    if (!hasFeatures && !hasLink) {
      return _sectionCard(
        icon: Icons.checklist_outlined,
        title: AppStrings.productFeatures,
        child: const EmptyStateWidget(
          message: "No features added.",
          imageSize: 40,
        ),
      );
    }

    return _sectionCard(
      icon: Icons.checklist_outlined,
      title: AppStrings.productFeatures,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFeatures)
            ...controller.featureControllers.map(
              (fc) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: Colors.green.shade600),
                    SizedBox(width: SizeConfig.paddingXS),
                    Expanded(
                      child: CustomText(
                        fc.text,
                        fontSize: SizeConfig.size13,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hasLink) ...[
            SizedBox(height: SizeConfig.paddingXS),
            Row(
              children: [
                Icon(Icons.link, size: 16, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.paddingXS),
                Expanded(
                  child: GestureDetector(
                    onTap: () => launchURL(controller.linkController.text),
                    child: CustomText(
                      controller.linkController.text,
                      fontSize: SizeConfig.size13,
                      color: AppColors.primaryColor,
                      decoration: TextDecoration.underline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MORE DETAILS SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMoreDetailsSection() {
    if (controller.detailsList.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      icon: Icons.info_outline,
      title: AppStrings.moreDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controller.detailsList.map((detail) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: SizeConfig.size100,
                  child: CustomText(
                    detail.title ?? '',
                    fontSize: SizeConfig.size13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                SizedBox(width: SizeConfig.paddingXS),
                Expanded(
                  child: CustomText(
                    detail.details ?? '-',
                    fontSize: SizeConfig.size13,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRICING & WARRANTY SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPricingSection() {
    final hasMrp = controller.mrpController.text.isNotEmpty;
    final hasWarranty = controller.productWarrantyController.text.isNotEmpty;
    final hasExpiry =
        controller.productExpiryDurationController.text.isNotEmpty;
    final hasGuide = controller.userGuideLineControllers.isNotEmpty;

    if (!hasMrp && !hasWarranty && !hasExpiry && !hasGuide) {
      return const SizedBox.shrink();
    }

    return _sectionCard(
      icon: Icons.sell_outlined,
      title: AppStrings.pricingWarranty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMrp)
            _infoRow(AppStrings.mrp.tr, "₹${controller.mrpController.text}"),
          if (hasWarranty)
            _infoRow(AppStrings.productWarranty.tr,
                controller.productWarrantyController.text),
          if (hasExpiry)
            _infoRow(AppStrings.expiryTime.tr,
                controller.productExpiryDurationController.text),
          if (hasGuide) ...[
            SizedBox(height: SizeConfig.paddingXS),
            CustomText(
              '${AppStrings.userGuidance.tr}:',
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            ...controller.userGuideLineControllers.map(
              (gc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: CustomText(
                        gc.text,
                        fontSize: SizeConfig.size13,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VARIANT OPTIONS (for product creation flow)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVariantOptionsSection() {
    return _sectionCard(
      icon: Icons.tune_outlined,
      title: AppStrings.variant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.selectedColors.isNotEmpty) ...[
            CustomText(
              '${AppStrings.color.tr}:',
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.selectedColors.map((selected) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: selected.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CustomText(
                        selected.name,
                        fontSize: SizeConfig.size12,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: SizeConfig.paddingS),
          ],
          if (controller.dynamicAttributes.isNotEmpty)
            ...controller.dynamicAttributes.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.paddingXS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      '${entry.key}:',
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: entry.value
                          .map(
                            (val) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: CustomText(
                                val,
                                fontSize: SizeConfig.size12,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            }),
          SizedBox(height: SizeConfig.paddingS),
          CustomBtn(
            title: AppStrings.createVariantStartSelling,
            onTap: () {
              Get.toNamed(
                RouteHelper.getCreateVariantScreenRoute(),
                arguments: {
                  ApiKeys.controller: controller,
                  ApiKeys.id: widget.id,
                  ApiKeys.providerType: widget.providerType,
                },
              );
            },
            bgColor: AppColors.primaryColor,
            textColor: AppColors.white,
            height: SizeConfig.size40,
            radius: 10.0,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LISTED VARIANTS GRID
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildListedProducts() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.style_outlined,
                    size: SizeConfig.size20, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.paddingXS),
                CustomText(
                  AppStrings.listedVariants,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.paddingS),
            LayoutBuilder(
              builder: (context, constraints) {
                const crossAxisCount = 2;
                const crossSpacing = 8.0;
                const mainSpacing = 8.0;

                final itemWidth = (constraints.maxWidth -
                        ((crossAxisCount - 1) * crossSpacing)) /
                    crossAxisCount;

                return MasonryGridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossSpacing,
                  mainAxisSpacing: mainSpacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.listedProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.listedProducts[index];
                    return _variantCard(product,
                        width: itemWidth, index: index);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _variantCard(
    ManufacturerProductListing product, {
    required double width,
    required int index,
  }) {
    return Obx(() {
      final isSelected = controller.selectedVariantIndex.value == index;

      return GestureDetector(
        onTap: () {
          if (isSelected) {
            controller.selectedVariantIndex.value = -1;
            controller.step2Images.value =
                widget.productStore?.details?.media ?? [];
          } else {
            controller.selectedVariantIndex.value = index;
            controller.step2Images.value = product.image;
          }
        },
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(9)),
                      child: CustomImageSlideshow(
                        isLoading: false,
                        width: double.infinity,
                        height: double.infinity,
                        imagePaths: product.image,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _iconButton(
                        InkWell(
                          onTap: () => showSelectedVariantsDialog(
                              context, product.selectedVariants),
                          child: const Icon(Icons.remove_red_eye_outlined,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),

              // Details
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      product.name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.size12,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    Row(
                      children: [
                        CustomText(
                          '₹${product.price}',
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.size13,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        Flexible(
                          child: CustomText(
                            '₹${product.mrp}',
                            fontSize: SizeConfig.size11,
                            color: AppColors.secondaryTextColor,
                            decoration: TextDecoration.lineThrough,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if ((product.discount ?? '').isNotEmpty) ...[
                      SizedBox(height: SizeConfig.size2),
                      CustomText(
                        '${product.discount}% ${AppStrings.off.tr}',
                        fontSize: SizeConfig.size11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ],
                ),
              ),

              // Chat button
              if (!isOwnProduct)
                Padding(
                  padding: EdgeInsets.only(
                    left: SizeConfig.paddingXS,
                    right: SizeConfig.paddingXS,
                    bottom: SizeConfig.paddingXS,
                  ),
                  child: InkWell(
                    onTap: () => _onChatWithVariant(product),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomText(
                        AppStrings.chat,
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.size12,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget? _buildBottomBar() {
    if (widget.productStore == null || isOwnProduct) return null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeConfig.paddingS,
          right: SizeConfig.paddingS,
          bottom: SizeConfig.paddingM,
          top: SizeConfig.paddingXSL,
        ),
        child: Row(
          children: [
            Expanded(
              child: PositiveCustomBtn(
                onTap: () {
                  if (isGuestUser()) {
                    createProfileScreen();
                    return;
                  }
                  final chatViewController = Get.find<ChatViewController>();
                  chatViewController.checkChatConnectionAndOpenChat(
                    userId: widget.productStore?.user_id ?? '',
                    route: AppConstants.route_discover,
                  );
                },
                title: AppStrings.chat,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: SizeConfig.size20, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.paddingXS),
                CustomText(
                  title,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.paddingS),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: SizeConfig.size100 + SizeConfig.size20,
            child: CustomText(
              label,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
          Expanded(
            child: CustomText(
              value.isNotEmpty ? value : '-',
              fontSize: SizeConfig.size13,
              color: AppColors.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(Widget child) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  void _onChatWithVariant(ManufacturerProductListing product) async {
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final chatViewController = Get.find<ChatViewController>();
    List<Map<String, String>> urlList =
        product.image.map((e) => {ApiKeys.url: e}).toList();
    Map<String, dynamic> data = {
      ApiKeys.product_id: "${product.id}",
      ApiKeys.price: "${product.price}",
      ApiKeys.discount: "${product.discount}",
      ApiKeys.message: "${product.name}",
      ApiKeys.message_type: AppConstants.product,
      ApiKeys.title: product.name,
      ApiKeys.variant: jsonEncode(product.selectedVariants),
      ApiKeys.mrp: product.mrp,
      ApiKeys.url: urlList,
    };
    chatViewController.checkChatConnectionAndOpenChat(
      userId: widget.productStore?.user_id ?? '',
      shareProductParams: data,
      isWithProductSend: true,
      route: AppConstants.route_discover,
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
            padding:
                const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: CustomText(
                        AppStrings.selectedVariants,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.mainTextColor),
                    ),
                  ],
                ),
                if (selectedVariants != null && selectedVariants.isNotEmpty)
                  _buildVariantsList(selectedVariants)
                else
                  const CustomText(
                    AppStrings.noVariantsSelected,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVariantsList(Map<String, dynamic> selectedVariants) {
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

  Widget _buildVariantRow(String key, dynamic value) {
    if (key == 'color' && value is Map<String, dynamic>) {
      final color = ManufacturerSelectedColor.fromJson(value);
      return Row(
        children: [
          CustomText("$key : ", fontSize: SizeConfig.size14),
          CustomText(
            color.name,
            fontSize: SizeConfig.size13,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
          const SizedBox(width: 6),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.greyE5, width: 2),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        CustomText("$key : ", fontSize: SizeConfig.size14),
        Flexible(
          child: CustomText(
            "$value",
            fontSize: SizeConfig.size13,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
