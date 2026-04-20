import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeProductScreen extends StatefulWidget {
  final bool isShowInGrid;

  const HomeMadeProductScreen({super.key, this.isShowInGrid = true});

  @override
  State<HomeMadeProductScreen> createState() => _HomeMadeProductScreenState();
}

class _HomeMadeProductScreenState extends State<HomeMadeProductScreen> {
  final controller = getOrPut(() => DiscoverController());
  final productController = getOrPut(() => ProductController());
  final ScrollController _scrollController = ScrollController();
  final ProviderType _providerType = ProviderType.user;

  /// Level-0 category selected in the left sidebar
  final Rxn<ProductNestedCategoryResponse> _selectedCategory = Rxn();

  /// Level-1 category selected in the top horizontal tabs
  final Rxn<ProductNestedCategoryResponse> _selectedChild = Rxn();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (productController.productsNestedCategoryList.isEmpty) {
        await productController.fetchProductsNestedCategory();
      }
      final list = productController.productsNestedCategoryList;
      if (list.isNotEmpty) _selectCategory(list.first);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  /// Select a level-0 category, auto-select its first child, and fetch products.
  void _selectCategory(ProductNestedCategoryResponse category) {
    _selectedCategory.value = category;
    final children = category.children ?? [];
    if (children.isNotEmpty) {
      _selectedChild.value = children.first;
      _fetchProducts(children.first.sId ?? category.sId);
    } else {
      _selectedChild.value = null;
      _fetchProducts(category.sId);
    }
  }

  /// Select a level-1 child tab and fetch products.
  void _selectChild(ProductNestedCategoryResponse child) {
    _selectedChild.value = child;
    _fetchProducts(child.sId);
  }

  void _fetchProducts(String? productCategory) {
    controller.getAllProductNearBy(
      providerType: _providerType,
      productCategory: productCategory,
    );
  }

  void _onLoadMore() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final tagId =
          _selectedChild.value?.sId ?? _selectedCategory.value?.sId;
      controller.getAllProductNearBy(
        providerType: _providerType,
        productCategory: tagId,
        isLoadMore: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final name = _selectedCategory.value?.name ?? 'Home Made Products';
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
      ),
      body: SafeArea(
        child: Obx(() {
          final status =
              productController.nestedProductCategoryResponse.value.status;
          if (status == Status.INITIAL || status == Status.LOADING) {
            return const Center(child: CircularProgressIndicator());
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryList(),
              SizedBox(width: SizeConfig.size6),
              Expanded(
                child: Column(
                  children: [
                    _buildChildTabs(),
                    Expanded(child: _buildProductContent()),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Left sidebar: level-0 categories
  Widget _buildCategoryList() {
    return Obx(() {
      final list = productController.productsNestedCategoryList;
      if (list.isEmpty) return const SizedBox.shrink();
      return CommonGenericLeftSideCategoryList<ProductNestedCategoryResponse>(
        items: list,
        getLabel: (item) => item.name ?? '',
        getIcon: (item) => item.image ?? '',
        isSelected: (item) => _selectedCategory.value?.sId == item.sId,
        onTap: (item, index) => _selectCategory(item),
      );
    });
  }

  /// Horizontal tabs: level-1 children of the selected level-0 category
  Widget _buildChildTabs() {
    return Obx(() {
      final children = _selectedCategory.value?.children ?? [];
      if (children.isEmpty) return const SizedBox.shrink();
      final selected = _selectedChild.value;
      final selectedIdx = selected == null
          ? 0
          : children.indexWhere((c) => c.sId == selected.sId);
      return Padding(
        padding: EdgeInsets.only(
          top: SizeConfig.size8,
          right: SizeConfig.size8,
        ),
        child: HorizontalTabSelector<ProductNestedCategoryResponse>(
          tabs: children,
          selectedIndex: selectedIdx < 0 ? 0 : selectedIdx,
          labelBuilder: (item) => item.name ?? '',
          horizontalPadding: 8,
          verticalPadding: 6,
          verticalMargin: 0,
          horizontalMargin: 0,
          unSelectedBackgroundColor: AppColors.white,
          unSelectedBorderColor: AppColors.greyE5,
          onTabSelected: (index, label) => _selectChild(children[index]),
        ),
      );
    });
  }

  /// Two-column grid that pushes an odd-count last item to the right cell.
  Widget _buildTwoColumnGrid(List<GetProductData> products) {
    final rowCount = (products.length / 2).ceil();
    final hasLoadMore = controller.isProductDataLoadingMore.value;
    final totalItems = rowCount + (hasLoadMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        right: SizeConfig.paddingXS,
        bottom: SizeConfig.paddingL,
      ),
      itemCount: totalItems,
      itemBuilder: (context, rowIdx) {
        if (rowIdx >= rowCount) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final leftIdx = rowIdx * 2;
        final rightIdx = leftIdx + 1;
        final Widget leftCell = StoreProductCard(
          productStore: products[leftIdx].product,
          isShowInGrid: true,
        );
        final Widget rightCell = rightIdx < products.length
            ? StoreProductCard(
                productStore: products[rightIdx].product,
                isShowInGrid: true,
              )
            : const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftCell),
              const SizedBox(width: 8),
              Expanded(child: rightCell),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductContent() {
    return Obx(() {
      if (controller.isProductDataFirstLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final productList =
          List<GetProductData>.from(controller.productDataList);

      if (productList.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message:
                'No ${_selectedChild.value?.name ?? _selectedCategory.value?.name ?? ''} products found',
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product count chip
          Padding(
            padding: EdgeInsets.only(
              top: SizeConfig.paddingS,
              right: SizeConfig.paddingXS,
              bottom: SizeConfig.size6,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.greyE5, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 14, color: AppColors.primaryColor),
                  const SizedBox(width: 6),
                  CustomText(
                    "${productList.length}${controller.isProductDataLoadingMore.value ? '+' : ''} Products",
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
          ),

          // Product grid/list
          Expanded(
            child: widget.isShowInGrid
                ? _buildTwoColumnGrid(productList)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      right: SizeConfig.paddingXS,
                      bottom: SizeConfig.paddingL,
                    ),
                    itemCount: productList.length +
                        (controller.isProductDataLoadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= productList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size10),
                        child: StoreProductCard(
                          productStore: productList[index].product,
                          isShowInGrid: widget.isShowInGrid,
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}
