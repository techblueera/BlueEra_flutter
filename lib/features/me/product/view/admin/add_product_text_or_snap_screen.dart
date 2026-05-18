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
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/features/me/product/view/admin/product_preview_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/attribute_two_rows.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_variant_grid_card.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_floating_cart.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/snap_scan_loader.dart';
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

  /// Live keystroke mirror — `controller.searchProduct` only updates
  /// after the debounce AND the 3-character gate, so binding the UI
  /// branch directly to it makes the typing hint card lag behind the
  /// keyboard. This mirrors the raw input so the hint switches the
  /// instant the user types or backspaces.
  static const int _minSearchChars = 3;
  final RxString _liveInput = ''.obs;

  @override
  void initState() {
    controller.fetchListOfSuggestedProductApi();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

    Get.toNamed(RouteHelper.getAddProductVariantScreenRoute());
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
                  Obx(() => CommonTextField(
                        textEditController: controller.searchController,
                        onChange: (value) {
                          _liveInput.value = value;
                          controller.onSearchChanged(value);
                        },
                        hintText: AppStrings
                            .typeAtLeastThreeCharForSearchProducts,
                        showClearIcon: _liveInput.value.isNotEmpty,
                        onClearTap: () {
                          controller.searchController.clear();
                          controller.searchProduct.value = '';
                          _liveInput.value = '';
                        },
                        isValidate: false,
                      )),
                ],
              ),
            ),

            SizedBox(height: SizeConfig.size15),

            // Results — switches between three states based on the
            // live keystroke count:
            //   0 chars        → suggested products (browse)
            //   1..2 chars     → typing hint (let the user know more
            //                    characters are needed before search
            //                    will fire)
            //   >= 3 chars     → real results (skeleton while loading)
            Obx(() {
              final length = _liveInput.value.trim().length;
              if (length == 0) return _buildSuggestedProducts();
              if (length < _minSearchChars) {
                return _SearchTypingHint(typed: length, required: _minSearchChars);
              }
              return _buildSearchResults();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    // Initial fetch — paint a placeholder grid that mirrors the real
    // variant card layout instead of a centered spinner. Gives the
    // merchant a preview of the layout they're about to receive and
    // avoids the "is anything happening?" pause.
    if (controller.ProductSearchLoading.isTrue) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: _VariantGridSkeleton(count: 4),
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

        // Load-more — two-card skeleton row keeps the visual language
        // consistent with the initial fetch instead of jumping to a
        // spinner.
        if (controller.isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: _VariantGridSkeleton(count: 2),
          ),
      ],
    );
  }

  Widget _buildSuggestedProducts() {
    return  controller.isSuggestedProductFirstLoading.isTrue
          ? Padding(
      padding: const EdgeInsets.all(30.0),
      child: Align(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    )
            : controller.suggestedProductList.isNotEmpty
               ? CustomFormCard(
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
          Padding(
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
    )
                 : SizedBox.shrink();
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
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: SnapScanLoader(),
        );
      }

      final searchData = controller.productSnapSearchData.value;
      final products = controller.snapSearchProductList;

      if (searchData == null || products.isEmpty) {
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
          // Summary header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "${searchData.foundCount ?? products.length} Items Found",
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                if ((searchData.missingCount ?? 0) > 0)
                  CustomText(
                    "${searchData.missingCount} Items missing",
                    color: AppColors.red,
                    fontWeight: FontWeight.w500,
                  ),
              ],
            ),
          ),

          // Product list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return _buildSnapProductCard(products[index]);
            },
          ),
        ],
      );
    });
  }

  Widget _buildSnapProductCard(VariantData variantData) {
    final product = variantData.productInformation;
    final variant = variantData.finalVariant;

    String imageUrl = '';
    if (product.media.isNotEmpty) {
      imageUrl = product.media.first;
    } else if (variant.mediaRelatedToVarient.isNotEmpty) {
      imageUrl = variant.mediaRelatedToVarient.first;
    }

    // Build unique attributes from product variants
    final Map<String, List<dynamic>> uniqueAttributes = {};
    final firstTwoKeys = <String>[];
    for (var v in product.variants) {
      for (var key in v.attributes.keys) {
        if (!firstTwoKeys.contains(key)) {
          firstTwoKeys.add(key);
        }
        if (firstTwoKeys.length == 1) break;
      }
      if (firstTwoKeys.length == 1) break;
    }
    for (var key in firstTwoKeys) {
      uniqueAttributes[key] = [];
      for (var v in product.variants) {
        final value = v.attributes[key];
        if (value != null) {
          if (key == 'color' && value is Map<String, dynamic>) {
            final colorMap = {
              "color_name": value["color_name"] ?? "",
              "color_code": value["color_code"] ?? ""
            };
            if (!uniqueAttributes[key]!.any((e) =>
                e is Map &&
                e["color_name"] == colorMap["color_name"] &&
                e["color_code"] == colorMap["color_code"])) {
              uniqueAttributes[key]!.add(colorMap);
            }
          } else {
            if (!uniqueAttributes[key]!.contains(value)) {
              uniqueAttributes[key]!.add(value);
            }
          }
        }
      }
    }

    return CustomFormCard(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
          margin: EdgeInsets.only(bottom: SizeConfig.size10),
          child: InkWell(
            onTap: () => controller.toggleVariantWithData(variantData),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Obx(() => Checkbox(
                  value: controller.isVariantSelected(variant.id),
                  onChanged: (_) =>
                      controller.toggleVariantWithData(variantData),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    side: BorderSide(
                      color: AppColors.secondaryTextColor
                    )
                  ),
                  checkColor: Colors.white,
                  activeColor: AppColors.primaryColor,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primaryColor;
                    }
                    return AppColors.white;
                  }),
                )),

                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          height: SizeConfig.size80,
                          width: SizeConfig.size80,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            height: SizeConfig.size80,
                            width: SizeConfig.size80,
                            child: const Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.cover,
                            height: SizeConfig.size80,
                            width: SizeConfig.size80,
                          ),
                        )
                      : LocalAssets(
                          imagePath: AppIconAssets.place_holder_image,
                          boxFix: BoxFit.cover,
                          height: SizeConfig.size80,
                          width: SizeConfig.size80,
                        ),
                ),

                SizedBox(width: SizeConfig.size10),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        product.name,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: SizeConfig.size5),
                      PriceRow(
                        sellingPrice: '\u20B9${variant.sellingPrice.toStringAsFixed(0)}',
                        mrp: '\u20B9${variant.mrp.toStringAsFixed(0)}',
                        discount: "${calculateDiscount('${variant.sellingPrice}', '${variant.mrp}')}% OFF",
                      ),
                      AttributeRows(attributeMap: uniqueAttributes),
                    ],
                  ),
                ),

                // Preview button
                IconButton(
                  onPressed: () => _openPreview(variantData),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
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

// ════════════════════════════════════════════════════════════════════
// SEARCH TYPING HINT — shown while the user has typed 1..n-1 chars and
// the API hasn't fired yet. Soft brand-tinted card with a breathing
// search glyph, a progress-dot row (filled = typed, outline = pending),
// and a one-line directive. Communicates the threshold without
// scolding — the user knows exactly how many more keystrokes unlock
// the search.
// ════════════════════════════════════════════════════════════════════

class _SearchTypingHint extends StatefulWidget {
  final int typed;
  final int required;

  const _SearchTypingHint({required this.typed, required this.required});

  @override
  State<_SearchTypingHint> createState() => _SearchTypingHintState();
}

class _SearchTypingHintState extends State<_SearchTypingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.required - widget.typed;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size20,
        vertical: SizeConfig.size24,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Whisper of brand color over white — the card reads as
        // primary-themed without competing with the search field.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Breathing search glyph — soft outer halo scales up while
          // the inner disc holds steady, suggesting "ready, waiting
          // for input" rather than "loading".
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              final t = _pulse.value; // 0..1
              final haloScale = 1.0 + 0.18 * t;
              final haloAlpha = 0.20 - 0.14 * t;
              return SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: haloScale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryColor
                              .withValues(alpha: haloAlpha.clamp(0.0, 1.0)),
                        ),
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryColor,
                            Color.lerp(
                              AppColors.primaryColor,
                              Colors.black,
                              0.12,
                            )!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            'Keep typing…',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            letterSpacing: -0.2,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            remaining == 1
                ? 'Just 1 more character to start searching'
                : 'Type $remaining more characters to start searching',
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.center,
            height: 1.4,
          ),
          SizedBox(height: SizeConfig.size18),
          // Progress dots — filled for keystrokes already typed,
          // outlined for the ones still needed. Reads at a glance.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.required, (i) {
              final filled = i < widget.typed;
              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: filled ? 22 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: filled
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: filled
                          ? AppColors.primaryColor
                          : AppColors.primaryColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// VARIANT GRID SKELETON — placeholder grid shown during the search
// API call. Mimics the real ProductVariantGridCard layout (image ▸
// title ▸ price) so the merchant gets a preview of the layout, and
// applies a moving shimmer via ShaderMask so the placeholders feel
// alive rather than frozen.
// ════════════════════════════════════════════════════════════════════

class _VariantGridSkeleton extends StatefulWidget {
  final int count;

  const _VariantGridSkeleton({this.count = 4});

  @override
  State<_VariantGridSkeleton> createState() => _VariantGridSkeletonState();
}

class _VariantGridSkeletonState extends State<_VariantGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      itemCount: widget.count,
      itemBuilder: (_, i) => _SkeletonVariantCard(animation: _shimmer),
    );
  }
}

class _SkeletonVariantCard extends StatelessWidget {
  final Animation<double> animation;

  const _SkeletonVariantCard({required this.animation});

  // Bases & highlight tuned for a calm, light card surface.
  static const Color _base = Color(0xFFEDEFF3);
  static const Color _highlight = Color(0xFFF8F9FB);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value; // 0..1
        // Move the gradient from off-left to off-right so the bright
        // band sweeps cleanly across the card.
        final dx = -1.5 + 3.0 * t;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(dx - 0.6, 0),
              end: Alignment(dx + 0.6, 0),
              colors: const [_base, _highlight, _base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE6E8EE),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                // Image placeholder — matches the variant card hero.
                AspectRatio(
                  aspectRatio: 1.0,
                  child: ColoredBox(color: _base),
                ),
                // Info zone — name bar (long), price bar (short).
                Padding(
                  padding: EdgeInsets.fromLTRB(10, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkBar(width: double.infinity, height: 10),
                      SizedBox(height: 8),
                      _SkBar(width: 80, height: 10),
                      SizedBox(height: 14),
                      _SkBar(width: 64, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkBar extends StatelessWidget {
  final double width;
  final double height;

  const _SkBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _SkeletonVariantCard._base,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
