import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/model/product_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/product/model/product_nested_category_response.dart';
import 'package:BlueEra/features/me/product/view/widget/product_self_pickup_cart.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Category → sub-category → products listing for the product visit flow.
///
/// Structure mirrors [VisitGroceryProductsScreen] and
/// [MyFoodProductScreen]:
///
/// * Left sidebar: level-2 categories (children of the level-1 category
///   the user tapped on [VisitProductStoreDetailsScreen]).
/// * Right content: an optional horizontal tab bar for level-3 children
///   plus a paginated product grid. Products are loaded via
///   [InventoryController.fetchProductsByCategory] scoped to the
///   visiting business.
///
/// Product categories are 4-tier in the data model but we only surface
/// 3 tiers here — anything under the level-3 sub-category is aggregated
/// into its products by the server.
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
  final Rxn<ProductNestedCategoryResponse> _selectedCategory =
      Rxn<ProductNestedCategoryResponse>();

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
        businessId: widget.visitBusinessId,
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
          ProductSelfPickupCart(controller: cartController),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final level2 = widget.parentCategory.children ?? [];
    // No outer Obx — CommonGenericLeftSideCategoryList wraps each item
    // in its own Obx internally, so its selected state already reacts
    // to `_selectedCategory.value` changes without a wrapper here.
    // Wrapping it in Obx also trips GetX's "improper use" warning
    // because the observable reads happen inside callbacks passed to
    // the child, not during this builder's build.
    return CommonGenericLeftSideCategoryList<ProductNestedCategoryResponse>(
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
          // Level-3 tabs (if any) — reads reactively so a sidebar switch
          // updates the visible tabs immediately.
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

      // Using SliverMasonryGrid in a CustomScrollView is the same
      // pattern used by AllTopSellingGroceryProductsScreen and
      // DiscountFoodProductsScreen — both render inside Expanded
      // without layout errors. `MasonryGridView.count` hit a
      // "null check used on null" during performLayout here, which
      // this Sliver-based setup avoids.
      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childCount: items.length,
              itemBuilder: (context, index) => _ProductGridTile(
                product: items[index],
                cartController: cartController,
                onToggleCart: _onToggleCart,
                firstVariantId: _firstVariantId,
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
    final details = product.product.details;
    final variants = product.product.sellerClassification?.variants ?? [];
    final img = (details?.media.isNotEmpty ?? false) ? details!.media.first : '';
    final sellingPrice = variants.isNotEmpty ? variants.first.sellingPrice : null;
    final mrp = variants.isNotEmpty ? variants.first.mrp : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: AspectRatio(
                  aspectRatio: 1.05,
                  child: img.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.cover,
                          ),
                        )
                      : LocalAssets(
                          imagePath: AppIconAssets.place_holder_image,
                          boxFix: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Obx(() {
                  // Subscribe to cart list — this forces a rebuild on
                  // every add/remove so the toggle affordance stays in
                  // sync with the cart bar.
                  final cart = cartController.selectedProductVariants;
                  // ignore: unused_local_variable
                  final _ = cart.length;
                  final id = firstVariantId(product);
                  final added = cartController.isVariantInCart(id);
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: id == null ? null : () => onToggleCart(product),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            added ? AppColors.greenShade : AppColors.blackMite,
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
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  details?.name ?? '',
                  fontSize: SizeConfig.small,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size4),
                Row(
                  children: [
                    CustomText(
                      '${AppConstants.rupeeSymbol}${sellingPrice ?? 0}',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                    ),
                    if (mrp != null && sellingPrice != null && mrp > sellingPrice) ...[
                      const SizedBox(width: 6),
                      CustomText(
                        '${AppConstants.rupeeSymbol}$mrp',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
