import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/store/models/product_nested_category_response.dart';
import 'package:BlueEra/features/common/store/view/store_product_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ProductSelectionScreen extends StatefulWidget {
  final List<ProductNestedCategory> arrProducts;
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
  final controller = getOrPut(() => DiscoverController());
  final ScrollController scrollController = ScrollController();
  final ProviderType _providerType = ProviderType.business;

  final Rxn<ProductNestedCategory> _selectedCategory =
      Rxn<ProductNestedCategory>();
  final Rxn<ProductNestedCategory> _selectedChild =
      Rxn<ProductNestedCategory>();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.arrProducts.isNotEmpty) {
        _selectCategory(widget.arrProducts.first);
      }
    });
  }

  void _selectCategory(ProductNestedCategory category) {
    _selectedCategory.value = category;

    if (category.children != null && category.children!.isNotEmpty) {
      _selectedChild.value = category.children!.first;
      _fetchProducts(category.children!.first.key ?? category.key);
    } else {
      _selectedChild.value = null;
      _fetchProducts(category.key);
    }
  }

  void _selectChild(ProductNestedCategory child) {
    _selectedChild.value = child;
    _fetchProducts(child.key);
  }

  void _fetchProducts(String? productCategory) {
    controller.getAllProductNearBy(
      providerType: _providerType,
      productCategory: productCategory,
    );
  }

  void _onLoadMore() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      final key = _selectedChild.value?.key ?? _selectedCategory.value?.key;
      controller.getAllProductNearBy(
        providerType: _providerType,
        productCategory: key,
        isLoadMore: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onLoadMore);
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryList(),
          Expanded(child: _buildRightContent()),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return CommonGenericLeftSideCategoryList<ProductNestedCategory>(
      items: widget.arrProducts,
      getIcon: (item) => '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) => _selectedCategory.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = widget.arrProducts[index];
        if (_selectedCategory.value?.sId == selected.sId) return;
        _selectCategory(selected);
      },
    );
  }

  Widget _buildRightContent() {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child tabs
              _buildChildTabs(),
              SizedBox(height: 8),
              // Product grid
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ));
  }

  Widget _buildChildTabs() {
    return Obx(() {
      final children = _selectedCategory.value?.children ?? [];
      if (children.isEmpty) return const SizedBox.shrink();

      final selected = _selectedChild.value;
      final selectedIdx = selected == null
          ? 0
          : children.indexWhere((c) => c.sId == selected.sId);

      return HorizontalTabSelector<ProductNestedCategory>(
        tabs: children,
        selectedIndex: selectedIdx < 0 ? 0 : selectedIdx,
        labelBuilder: (item) => item.name ?? '',
        horizontalPadding: 8,
        verticalPadding: 6,
        verticalMargin: 0,
        horizontalMargin: 0,
        unSelectedBackgroundColor: AppColors.white,
        unSelectedBorderColor: AppColors.greyE5,
        onTabSelected: (index, label) {
          _selectChild(children[index]);
        },
      );
    });
  }

  Widget _buildProductGrid() {
    return Obx(() {
      if (controller.isProductDataFirstLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final products = controller.productDataList;

      if (products.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: EmptyStateWidget(
            message: 'No products found.',
          ),
        );
      }

      return MasonryGridView.count(
        controller: scrollController,
        itemCount: products.length +
            (controller.isProductDataLoadingMore.value ? 1 : 0),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: EdgeInsets.only(bottom: SizeConfig.size30),
        itemBuilder: (_, i) {
          if (i == products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          return StoreProductCard(
            productStore: products[i].product,
            isShowInGrid: true,
          );
        },
      );
    });
  }
}
