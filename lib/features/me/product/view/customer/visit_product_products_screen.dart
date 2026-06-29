import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_customer_card.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_self_pickup_cart.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class VisitProductProductsScreen extends StatefulWidget {
  final ProductCategoryWithInventoryModel parentCategory;
  final String visitBusinessId;

  const VisitProductProductsScreen({
    super.key,
    required this.parentCategory,
    required this.visitBusinessId,
  });

  @override
  State<VisitProductProductsScreen> createState() =>
      _VisitProductProductsScreenState();
}

class _VisitProductProductsScreenState
    extends State<VisitProductProductsScreen> {
  final InventoryController controller =
      getOrPut<InventoryController>(() => InventoryController());
  final ProductSelfPickupController cartController =
      getOrPut<ProductSelfPickupController>(
          () => ProductSelfPickupController());

  final ScrollController _scrollController = ScrollController();

  /// Currently selected level-2 category (sidebar).
  final Rxn<ProductCategoryWithInventoryModel> _selectedCategory =
      Rxn<ProductCategoryWithInventoryModel>();

  /// Horizontal tab index for level-3 children. `0` → "All"
  /// (uses the level-2 category id directly).
  final RxInt _selectedTabIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final children = widget.parentCategory.children ?? [];
      if (children.isNotEmpty) {
        _selectedCategory.value = children.first;
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !controller.isProductByCategoryLoadingMore.value &&
        controller.productByCategoryHasMore) {
      _fetchProducts(isLoadMore: true);
    }
  }

  void _fetchProducts({bool isLoadMore = false}) {
    final category = _selectedCategory.value;
    if (category == null) return;

    String? categoryId;
    final tabIndex = _selectedTabIndex.value;
    if (tabIndex > 0 &&
        category.children != null &&
        category.children!.isNotEmpty) {
      // level-3 selected
      categoryId = category.children![tabIndex - 1].sId;
    } else {
      // "All" → level-2
      categoryId = category.sId;
    }

    if (categoryId == null) return;
    controller.fetchProductsByCategory(
      categoryId: categoryId,
      isLoadMore: isLoadMore,
      visitBusinessId: widget.visitBusinessId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final name = _selectedCategory.value?.name ??
              widget.parentCategory.name ??
              'Products';
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSidebar(),
              Expanded(child: _buildRightContent()),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: ProductSelfPickupCart(controller: cartController),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final level2 = widget.parentCategory.children ?? [];
    return CommonGenericLeftSideCategoryList<ProductCategoryWithInventoryModel>(
      items: level2,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) => _selectedCategory.value?.sId == item.sId,
      onTap: (item, index) {
        if (_selectedCategory.value?.sId == item.sId) return;
        _selectedCategory.value = item;
        _selectedTabIndex.value = 0;
        _fetchProducts();
      },
    );
  }

  Widget _buildRightContent() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final category = _selectedCategory.value;
            final children = category?.children ?? [];
            if (children.isEmpty) return const SizedBox.shrink();

            final tabData = <dynamic>['All', ...children];
            return HorizontalTabSelector<dynamic>(
              tabs: tabData,
              selectedIndex: _selectedTabIndex.value,
              labelBuilder: (item) =>
                  (item is String) ? item : (item.name ?? ''),
              horizontalPadding: 8,
              verticalPadding: 6,
              verticalMargin: 0,
              horizontalMargin: 0,
              unSelectedBackgroundColor: AppColors.white,
              unSelectedBorderColor: AppColors.greyE5,
              onTabSelected: (index, label) {
                _selectedTabIndex.value = index;
                _fetchProducts();
              },
            );
          }),
          SizedBox(height: SizeConfig.size8),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Obx(() {
      if (controller.isProductByCategoryFirstLoading.value) {
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      final items = controller.productsByCategoryList;
      if (items.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: EmptyStateWidget(message: 'No products found.'),
        );
      }

      final isLoadingMore =
          controller.isProductByCategoryLoadingMore.value;

      // 2-column masonry grid of the shared customer card → variants sheet →
      // add to cart, identical to the grocery products screen.
      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
                bottom: SizeConfig.size15 + kBottomNavigationBarHeight),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childCount: items.length,
              itemBuilder: (context, i) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.greyE5),
                ),
                clipBehavior: Clip.antiAlias,
                child: ProductCustomerCard(
                  product: items[i],
                  cartController: cartController,
                  visitBusinessId: widget.visitBusinessId,
                ),
              ),
            ),
          ),
          if (isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: SizeConfig.size100),
          ),
        ],
      );
    });
  }
}
