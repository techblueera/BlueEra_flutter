import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/features/me/product/view/product/product_preview_screen.dart';
import 'package:BlueEra/features/me/product/widget/product_floating_cart.dart';
import 'package:BlueEra/features/me/product/widget/product_variant_grid_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

enum _AddProductMode { textSearch, snapSearch }

class AddProductTextOrSnapSearchScreen extends StatefulWidget {
  final String id;
  final ProviderType providerType;
  const AddProductTextOrSnapSearchScreen(
      {super.key, required this.id, required this.providerType});

  @override
  State<AddProductTextOrSnapSearchScreen> createState() =>
      _AddProductTextOrSnapSearchScreenState();
}

class _AddProductTextOrSnapSearchScreenState
    extends State<AddProductTextOrSnapSearchScreen> {
  final scrollController = ScrollController();
  final controller = Get.put(InventoryController());
  final Rx<_AddProductMode> _selectedMode = _AddProductMode.textSearch.obs;

  @override
  void initState() {
    controller.fetchListOfSuggestedProductApi();
    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<InventoryController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(title: AppStrings.addProduct),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildModeSelector(),
                Expanded(
                  child: Obx(() =>
                      _selectedMode.value == _AddProductMode.textSearch
                          ? _buildTextSearchContent()
                          : _buildSnapSearchContent()),
                ),
              ],
            ),
            // Floating cart
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Obx(() => ProductFloatingCart(
                      selectedProducts:
                          controller.selectedVariantsList.toList(),
                      onTap: () => _navigateToCart(),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCart() {
    // Sync selected variants to ProductController for the cart screen
    final productController = getOrPut(() => ProductController());
    productController.ownerID = widget.id;
    productController.ownerProviderType = widget.providerType;
    productController.selectedProducts
        .assignAll(controller.selectedVariantsList);

    // Sync variant selections
    for (final v in controller.selectedVariantsList) {
      final id = v.finalVariant.id;
      final inventoryCtrl = Get.find<InventoryController>();
      inventoryCtrl.variantSelection[id] = true;
    }

    Get.toNamed(RouteHelper.getProductCartScreenRoute());
  }

  void _openPreview(VariantData variantData) {
    final product = variantData.productInformation;
    final variant = variantData.finalVariant;

    final args = ProductPreviewArgs(
      productId: product.id,
      media: product.media.isNotEmpty
          ? product.media
          : variant.mediaRelatedToVarient,
      name: product.name,
      description: product.description,
      tags: product.tags,
      features: product.addProductFeatures.map((f) => f.title).toList(),
      details: product.addMoreDetails
          .map((d) => DetailPair(d.title, d.details))
          .toList(),
      sellingPrice: variant.sellingPrice.toString(),
      MRPPrice: variant.mrp.toString(),
      warranty: product.productWarrenty,
      expiry: '',
      userGuide: product.guideLine,
    );

    Get.toNamed(
      RouteHelper.getProductPreviewScreenRoute(),
      arguments: {
        ApiKeys.argProductData: args,
        ApiKeys.id: widget.id,
        ApiKeys.providerType: widget.providerType,
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // MODE SELECTOR
  // ════════════════════════════════════════════════════════════════════

  Widget _buildModeSelector() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size15,
        vertical: SizeConfig.size12,
      ),
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Obx(() => Row(
              children: [
                _buildModeTab(
                  icon: Icons.search_rounded,
                  label: 'Text Search',
                  mode: _AddProductMode.textSearch,
                ),
                SizedBox(width: 4),
                _buildModeTab(
                  icon: Icons.camera_alt_outlined,
                  label: 'Snap Search',
                  mode: _AddProductMode.snapSearch,
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required _AddProductMode mode,
  }) {
    final isActive = _selectedMode.value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectedMode.value = mode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isActive
                      ? AppColors.primaryColor
                      : AppColors.secondaryTextColor),
              SizedBox(width: SizeConfig.size6),
              CustomText(
                label,
                fontSize: SizeConfig.small,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // TEXT SEARCH
  // ════════════════════════════════════════════════════════════════════

  Widget _buildTextSearchContent() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels ==
            scrollInfo.metrics.maxScrollExtent) {
          if (controller.searchProduct.isNotEmpty) {
            if (controller.hasMoreData && !controller.isLoadingMore) {
              controller.fetchListOfSearchProductApi(
                  controller.searchProduct.value,
                  isLoadMore: true);
            }
          } else {
            if (controller.suggestedProductHasMoreData &&
                !controller.isSuggestedProductLoadingLoadingMore.value) {
              controller.fetchListOfSuggestedProductApi(isLoadMore: true);
            }
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.only(
          left: SizeConfig.size15,
          right: SizeConfig.size15,
          top: SizeConfig.size15,
          bottom: controller.selectedVariantsList.isNotEmpty
              ? SizeConfig.size80
              : SizeConfig.size15,
        ),
        child: Column(
          children: [
            _buildErrorBanner(),

            // Search field
            CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size16),
              borderRadius: BorderRadius.circular(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.enterProductName,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    AppStrings.findProductName,
                    fontSize: SizeConfig.small,
                    color: AppColors.grey9B,
                  ),
                  SizedBox(height: SizeConfig.size16),
                  CommonTextField(
                    textEditController: controller.searchController,
                    onChange: (value) => controller.onSearchChanged(value),
                    hintText:
                        AppStrings.typeAtLeastThreeCharForSearchProducts,
                    showClearIcon: controller.searchProduct.isNotEmpty,
                    onClearTap: () {
                      controller.searchController.clear();
                      controller.searchProduct.value = '';
                    },
                    isValidate: false,
                  ),
                ],
              ),
            ),

            SizedBox(height: SizeConfig.size15),

            // Results
            if (controller.searchProduct.isNotEmpty)
              _buildSearchResults()
            else
              _buildSuggestedProducts(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (controller.ProductSearchLoading.isTrue) {
      return Padding(
        padding: const EdgeInsets.all(30.0),
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.searchProductVariantsList.isNotEmpty) ...[
          CustomText(
            AppStrings.productVariants,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          _buildVariantGrid(controller.searchProductVariantsList),
        ],

        if (controller.isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestedProducts() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size15),
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.suggestedProducts,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.bold,
            color: AppColors.mainTextColor,
          ),
          controller.isSuggestedProductFirstLoading.isTrue
              ? Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
                )
              : controller.suggestedProductList.isEmpty
                  ? SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(top: SizeConfig.size15),
                      child: Column(
                        children: [
                          _buildVariantGrid(controller.suggestedProductList),
                          if (controller
                              .isSuggestedProductLoadingLoadingMore.isTrue)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // SNAP SEARCH
  // ════════════════════════════════════════════════════════════════════

  Widget _buildSnapSearchContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: SizeConfig.size15,
        right: SizeConfig.size15,
        top: SizeConfig.size15,
        bottom: controller.selectedVariantsList.isNotEmpty
            ? SizeConfig.size80
            : SizeConfig.size15,
      ),
      child: Column(
        children: [
          _buildErrorBanner(),
          _buildSnapSearchSection(),
        ],
      ),
    );
  }

  Widget _buildSnapSearchSection() {
    return CustomFormCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            "Upload Bulk Product",
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            "Upload a photo of products or menu to add them instantly",
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
          const SizedBox(height: 14),
          MasonryGridView.count(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.productSnapSearchConfig.length,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final config = controller.productSnapSearchConfig[index];
              final String title = config['title']!;
              final String placeholder = config['image']!;
              final String icon = config['icon']!;

              return Obx(() {
                final File? capturedFile =
                    controller.productSnapSearchImagesMap[title];
                final bool hasImage = capturedFile != null;
                final bool isAnyImageSelected = controller
                    .productSnapSearchImagesMap.values
                    .any((v) => v != null);
                final bool isBlocked = isAnyImageSelected && !hasImage;

                return Column(
                  children: [
                    InkWell(
                      onTap: isBlocked
                          ? null
                          : hasImage
                              ? () => navigatePushTo(
                                    context,
                                    ImageViewScreen(
                                      appBarTitle: title,
                                      imageUrls: [capturedFile.path],
                                      initialIndex: 0,
                                    ),
                                  )
                              : () =>
                                  controller.addProductImagesBySlot(title),
                      child: Opacity(
                        opacity: isBlocked ? 0.5 : 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: SizedBox(
                            height: SizeConfig.size180,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                hasImage
                                    ? Image.file(capturedFile,
                                        fit: BoxFit.cover)
                                    : Image.asset(placeholder,
                                        fit: BoxFit.cover),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: hasImage
                                          ? AppColors.primaryColor
                                          : AppColors.greyE5,
                                      width: hasImage ? 2 : 1,
                                    ),
                                  ),
                                ),
                                if (!hasImage) ...[
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 2, sigmaY: 2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: AppColors.black
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(10.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.white
                                                  .withValues(
                                                      alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                              border: Border.all(
                                                color: AppColors.white
                                                    .withValues(
                                                        alpha: 0.1),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                              children: [
                                                LocalAssets(
                                                  imagePath: icon,
                                                  height: 18,
                                                  width: 18,
                                                  boxFix:
                                                      BoxFit.scaleDown,
                                                  imgColor:
                                                      AppColors.white,
                                                ),
                                                const SizedBox(width: 6),
                                                CustomText(
                                                  title,
                                                  fontSize:
                                                      SizeConfig.small,
                                                  color: AppColors.white,
                                                  fontWeight:
                                                      FontWeight.w400,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (hasImage)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => controller
                                          .removeProductImageBySlot(
                                              title),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red
                                            .withValues(alpha: 0.8),
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      title,
                      fontSize: 12,
                      color: hasImage
                          ? AppColors.primaryColor
                          : isBlocked
                              ? AppColors.greyE5
                              : AppColors.secondaryTextColor,
                      fontWeight:
                          hasImage ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ],
                );
              });
            },
          ),
          const SizedBox(height: 10),
          const CustomText(
            "Upload picture/menu containing up to 20 product at time",
            fontWeight: FontWeight.w400,
            color: AppColors.red,
            textAlign: TextAlign.center,
          ),
          _buildSnapSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSnapSearchResults() {
    return Obx(() {
      final response = controller.productSnapSearchResponse.value;
      if (response.status == Status.INITIAL) return const SizedBox();
      if (response.status == Status.LOADING) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(
            child: Image.asset(
              'assets/images/grocery_loading_indicator.gif',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        );
      }

      final products = controller.snapSearchProductList;
      if (products.isEmpty) {
        return Column(
          children: [
            SizedBox(height: SizeConfig.paddingL),
            const EmptyStateWidget(
              message:
                  'We couldn\'t identify any products from this photo. \n'
                  'Try capturing a clearer shot or searching for individual items!',
            ),
            SizedBox(height: SizeConfig.paddingL),
            CustomBtn(
              width: SizeConfig.size120,
              title: "Retry",
              textColor: AppColors.white,
              bgColor: AppColors.primaryColor,
              radius: 10.0,
              onTap: () => controller.fetchProductSnapSearchApi(),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: CustomText(
              "${products.length} Items Found",
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          _buildVariantGrid(products),
        ],
      );
    });
  }

  // ════════════════════════════════════════════════════════════════════
  // SHARED: VARIANT GRID + ERROR BANNER
  // ════════════════════════════════════════════════════════════════════

  Widget _buildVariantGrid(List<VariantData> variants) {
    return Obx(() => MasonryGridView.count(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          padding: EdgeInsets.zero,
          itemCount: variants.length,
          itemBuilder: (_, index) {
            final variant = variants[index];
            return ProductVariantGridCard(
              variantData: variant,
              isSelected:
                  controller.isVariantSelected(variant.finalVariant.id),
              onTap: () =>
                  controller.toggleVariantWithData(variant),
              onPreviewTap: () => _openPreview(variant),
            );
          },
        ));
  }

  Widget _buildErrorBanner() {
    if (!controller.showErrorBanner.value) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.redLightOut,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline,
                color: AppColors.white, size: 16),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: CustomText(
              AppStrings.max10Products,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w500,
              color: AppColors.red,
            ),
          ),
          GestureDetector(
            onTap: controller.dismissErrorBanner,
            child:
                const Icon(Icons.close, color: AppColors.red, size: 20),
          ),
        ],
      ),
    );
  }
}
