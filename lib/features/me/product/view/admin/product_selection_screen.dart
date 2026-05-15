import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/me/product/view/admin/product_preview_screen.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_variant_grid_card.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_floating_cart.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ProductSelectionScreen extends StatefulWidget {
  final List<ProductNestedCategoryResponse> arrProducts;
  final String? categoryName;

  const ProductSelectionScreen({
    super.key,
    required this.arrProducts,
    this.categoryName,
  });

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  final controller = getOrPut(() => ProductController());
  final ScrollController scrollController = ScrollController();

  final Rxn<ProductNestedCategoryResponse> _selectedCategory =
      Rxn<ProductNestedCategoryResponse>();
  final RxInt selectedHorizontalTabIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.arrProducts.isNotEmpty) {
        _selectedCategory.value = widget.arrProducts.first;
        _fetchProducts();
      }
    });
  }

  void _onScrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !controller.isInventoryProductLoadingMore.value &&
        controller.inventoryProductHasMore) {
      _fetchProducts(isLoadMore: true);
    }
  }

  void _fetchProducts({bool isLoadMore = false}) {
    final category = _selectedCategory.value;
    if (category == null) return;

    String? categoryId;
    final tabIndex = selectedHorizontalTabIndex.value;

    if (tabIndex > 0 &&
        category.children != null &&
        category.children!.isNotEmpty) {
      categoryId = category.children![tabIndex - 1].sId;
    } else {
      categoryId = category.sId;
    }

    if (categoryId != null) {
      controller.fetchInventoryProducts(
        categoryId: categoryId,
        isLoadMore: isLoadMore,
      );
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final name = _selectedCategory.value?.name ??
              widget.categoryName ??
              AppStrings.tab_product;
          return Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        isShadowShow: false,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Icon(Icons.search),
        ),
      ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryList(),
              Expanded(child: _buildRightContent()),
            ],
          ),
          // Floating cart
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() => ProductFloatingCart(
                    selectedProducts: controller.selectedProducts.toList(),
                    onTap: () {
                      Get.toNamed(RouteHelper.getProductCartScreenRoute());
                    },
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return CommonGenericLeftSideCategoryList<ProductNestedCategoryResponse>(
      items: widget.arrProducts,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) => _selectedCategory.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = widget.arrProducts[index];
        if (_selectedCategory.value?.sId == selected.sId) return;

        _selectedCategory.value = selected;
        selectedHorizontalTabIndex.value = 0;
        _fetchProducts();
      },
    );
  }

  Widget _buildRightContent() {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Max Limit Error
              if (controller.isProductMaxLimitHit)
                Container(
                  width: SizeConfig.screenWidth,
                  decoration: BoxDecoration(
                    color: AppColors.redBE,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  margin: EdgeInsets.only(bottom: SizeConfig.size10),
                  padding: EdgeInsets.symmetric(
                    vertical: SizeConfig.size4,
                    horizontal: SizeConfig.size10,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.warningOutlineIcon,
                          width: SizeConfig.size20,
                          height: SizeConfig.size20,
                        ),
                        SizedBox(width: SizeConfig.size8),
                        CustomText(
                          'You can\'t select more than ${controller.productMaxLimit} products at a time.',
                          color: AppColors.redLite,
                          fontSize: SizeConfig.extraSmall,
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                ),

              _buildChildTabs(),
              SizedBox(height: 8),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ));
  }

  Widget _buildChildTabs() {
    return Obx(() {
      final children = _selectedCategory.value?.children ?? [];
      if (children.isEmpty) return const SizedBox.shrink();

      final List<dynamic> tabData = ["All", ...children];

      return HorizontalTabSelector<dynamic>(
        tabs: tabData,
        selectedIndex: selectedHorizontalTabIndex.value,
        labelBuilder: (item) =>
            (item is String) ? item : (item.name ?? ""),
        horizontalPadding: 8,
        verticalPadding: 6,
        verticalMargin: 0,
        horizontalMargin: 0,
        unSelectedBackgroundColor: AppColors.white,
        unSelectedBorderColor: AppColors.greyE5,
        onTabSelected: (index, label) {
          selectedHorizontalTabIndex.value = index;
          _fetchProducts();
        },
      );
    });
  }

  Widget _buildProductGrid() {
    return Obx(() {
      if (controller.isInventoryProductFirstLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      final products = controller.inventoryProductList;

      if (products.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: EmptyStateWidget(message: 'No products found.'),
        );
      }

      return MasonryGridView.count(
        controller: scrollController,
        itemCount: products.length +
            (controller.isInventoryProductLoadingMore.value ? 1 : 0),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: EdgeInsets.only(
          bottom: controller.selectedProducts.isNotEmpty
              ? SizeConfig.size80
              : SizeConfig.size30,
        ),
        itemBuilder: (_, i) {
          if (i == products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Obx(() => ProductVariantGridCard(
                variantData: products[i],
                isSelected: controller.isProductSelected(products[i].finalVariant.id),
                onTap: () => controller.toggleProductSelection(products[i]),
                onPreviewTap: () => _openPreview(products[i]),
              ));
        },
      );
    });
  }

  void _openPreview(VariantData variantData) {
    final product = variantData.productInformation;
    final variant = variantData.finalVariant;

    final productPreviewArgs = ProductPreviewArgs(
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
        ApiKeys.argProductData: productPreviewArgs,
        ApiKeys.id: controller.ownerID ?? '',
        ApiKeys.providerType: controller.ownerProviderType ?? ProviderType.business,
      },
    );
  }
}
