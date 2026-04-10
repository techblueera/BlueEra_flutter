import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/view/widget/product_self_pickup_cart.dart';
import 'package:BlueEra/features/me/product/widget/product_top_selling_tile.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Paginated MasonryGridView of all "Top Selling" products for a business.
///
/// Opened from the "View All" action on [ProductHomeScreen] (owner flow —
/// pass no [visitBusinessId]) or from [VisitProductStoreDetailsScreen]
/// (customer flow — pass the visiting business's id). Shares
/// [InventoryController] state so the preview and this screen stay in
/// sync.
class AllTopSellingProductsScreen extends StatefulWidget {
  /// When non-null, paginate products scoped to this visiting business.
  /// When null, falls back to the current user's own business via the
  /// global `businessId` inside [InventoryController.fetchProducts].
  final String? visitBusinessId;

  const AllTopSellingProductsScreen({super.key, this.visitBusinessId});

  @override
  State<AllTopSellingProductsScreen> createState() =>
      _AllTopSellingProductsScreenState();
}

class _AllTopSellingProductsScreenState
    extends State<AllTopSellingProductsScreen> {
  final InventoryController controller =
      getOrPut<InventoryController>(() => InventoryController());
  final ScrollController _scrollController = ScrollController();

  /// Non-null only when launched from the customer visit flow.
  ProductSelfPickupController? _cartController;

  bool get _isVisitMode =>
      widget.visitBusinessId != null && widget.visitBusinessId!.isNotEmpty;

  ViewBusinessDetailsController? get _viewBusinessDetailsController =>
      Get.isRegistered<ViewBusinessDetailsController>()
          ? Get.find<ViewBusinessDetailsController>()
          : null;

  @override
  void initState() {
    super.initState();
    if (_isVisitMode) {
      _cartController = getOrPut<ProductSelfPickupController>(
          () => ProductSelfPickupController());
    }
    _scrollController.addListener(_onScroll);
    // Defer the fetch until after the first frame so the controller's
    // observable mutations don't re-enter an in-flight build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchProducts(visitBusinessId: widget.visitBusinessId);
    });
  }

  String? _firstVariantId(GetProductData product) {
    final variants = product.product.sellerClassification?.variants;
    if (variants == null || variants.isEmpty) return null;
    final id = variants.first.id;
    return id.isEmpty ? null : id;
  }

  void _onToggleCart(GetProductData product) {
    final ctrl = _cartController;
    if (ctrl == null) return;
    final id = _firstVariantId(product);
    if (id == null) return;
    final bDetails = _viewBusinessDetailsController
        ?.visitedBusinessProfileDetails
        ?.data;
    if (ctrl.isVariantInCart(id)) {
      ctrl.removeFromCart(product);
    } else {
      ctrl.addToCart(
        product,
        businessId: widget.visitBusinessId,
        businessName: bDetails?.businessName,
        businessLogo: bDetails?.logo,
        businessAddress: bDetails?.address,
      );
    }
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
    if (position.pixels >= position.maxScrollExtent - 200) {
      // Controller remembers the active owner id for the paginated run,
      // so we don't need to re-pass `visitBusinessId` here.
      controller.fetchProducts(isLoadMore: true);
    }
  }

  Future<void> _onRefresh() async {
    await controller.fetchProducts(visitBusinessId: widget.visitBusinessId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: 'Top Selling Products',
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            final items = controller.allProducts;
            final status =
                controller.ownDraftAndPublicProductResponse.value.status;
            final isInitialLoading =
                status == Status.INITIAL && items.isEmpty;
            final isLoadingMore = controller.isAllProductsLoadingMore.value;

            if (isInitialLoading) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 80),
                    EmptyStateWidget(
                      message: 'No top selling products yet.',
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(SizeConfig.size10),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childCount: items.length,
                      itemBuilder: (context, index) => _TopSellingProductTile(
                        product: items[index],
                        cartController: _cartController,
                        onToggleCart:
                            _isVisitMode ? _onToggleCart : null,
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
                  // Extra bottom space in visit mode so the last row
                  // isn't hidden behind the floating cart pill.
                  SliverToBoxAdapter(
                    child: SizedBox(height: _isVisitMode ? 120 : 24),
                  ),
                ],
              ),
            );
          }),
          if (_cartController != null)
            ProductSelfPickupCart(controller: _cartController!),
        ],
      ),
    );
  }
}

class _TopSellingProductTile extends StatelessWidget {
  final GetProductData product;
  final ProductSelfPickupController? cartController;
  final void Function(GetProductData)? onToggleCart;
  final String? Function(GetProductData) firstVariantId;

  const _TopSellingProductTile({
    required this.product,
    required this.firstVariantId,
    this.cartController,
    this.onToggleCart,
  });

  bool get _isVisitMode => cartController != null && onToggleCart != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: AspectRatio(
              aspectRatio: 1.05,
              child: ProductTopSellingImage(
                product: product,
                cartOverlay: _isVisitMode
                    ? Obx(() {
                        final cart =
                            cartController!.selectedProductVariants;
                        // ignore: unused_local_variable
                        final _ = cart.length;
                        final id = firstVariantId(product);
                        final added =
                            cartController!.isVariantInCart(id);
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                          onPressed: id == null
                              ? null
                              : () => onToggleCart!(product),
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
                      })
                    : null,
              ),
            ),
          ),
          ProductTopSellingInfoSection(product: product),
        ],
      ),
    );
  }
}
