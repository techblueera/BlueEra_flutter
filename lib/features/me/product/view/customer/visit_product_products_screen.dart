import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_top_selling_tile.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_self_pickup_cart.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
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

  ViewBusinessDetailsController? get _viewBusinessDetailsController =>
      Get.isRegistered<ViewBusinessDetailsController>()
          ? Get.find<ViewBusinessDetailsController>()
          : null;

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

  String? _firstVariantId(GetProductData product) {
    final variants = product.product.sellerClassification?.variants;
    if (variants == null || variants.isEmpty) return null;
    final id = variants.first.id;
    return id.isEmpty ? null : id;
  }

  void _onToggleCart(GetProductData product) {
    final id = _firstVariantId(product);
    if (id == null) return;
    final bDetails = _viewBusinessDetailsController
        ?.visitedBusinessProfileDetails
        ?.data;
    if (cartController.isVariantInCart(id)) {
      cartController.removeFromCart(product);
    } else {
      cartController.addToCart(
        product,
        userId: widget.visitBusinessId,
        businessName: bDetails?.businessName,
        businessLogo: bDetails?.logo,
        businessAddress: bDetails?.address,
      );
    }
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

      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.zero,
            // Why: a uniform SliverGrid (was SliverMasonryGrid) so
            // every tile claims the same cell height — masonry let
            // 1-line vs 2-line product names produce ragged rows.
            // The 0.62 ratio matches the proportions of the
            // top-selling product cards on the store-details screen so
            // this grid and that preview present products with
            // consistent dimensions.
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductGridTile(
                  product: items[index],
                  cartController: cartController,
                  onToggleCart: _onToggleCart,
                  firstVariantId: _firstVariantId,
                ),
                childCount: items.length,
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

class _ProductGridTile extends StatelessWidget {
  final GetProductData product;
  final ProductSelfPickupController cartController;
  final void Function(GetProductData) onToggleCart;
  final String? Function(GetProductData) firstVariantId;

  const _ProductGridTile({
    required this.product,
    required this.cartController,
    required this.onToggleCart,
    required this.firstVariantId,
  });

  @override
  Widget build(BuildContext context) {
    // Mirrors the top-selling carousel card on
    // visit_product_store_details_screen — same ProductTopSellingImage
    // for the thumbnail + cart overlay, same ProductTopSellingInfoSection
    // for the title + price block — so the entry point and the
    // category grid present products with identical visuals.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size4),
          Expanded(
            child: ProductTopSellingImage(
              product: product,
              cartOverlay: Obx(() {
                // Subscribe to cart list — forces a rebuild on every
                // add/remove so the toggle affordance stays in sync
                // with the cart bar.
                final cart = cartController.selectedProductVariants;
                // ignore: unused_local_variable
                final _ = cart.length;
                final id = firstVariantId(product);
                final added = cartController.isVariantInCart(id);
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed:
                      id == null ? null : () => onToggleCart(product),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: added
                          ? AppColors.greenShade
                          : AppColors.blackMite,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      added ? Icons.check : Icons.add,
                      size: SizeConfig.size16,
                      color: AppColors.white,
                    ),
                  ),
                );
              }),
            ),
          ),
          ProductTopSellingInfoSection(product: product),
        ],
      ),
    );
  }
}
