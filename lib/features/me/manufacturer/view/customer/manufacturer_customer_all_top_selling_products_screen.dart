import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/widget/manufacturer_product_top_selling_tile.dart';
import 'package:BlueEra/features/me/manufacturer/view/customer/widget/manufacturer_product_self_pickup_cart.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class ManufacturerCustomerAllTopSellingProductsScreen extends StatefulWidget {
  final String visitBusinessId;

  const ManufacturerCustomerAllTopSellingProductsScreen({super.key, required this.visitBusinessId});

  @override
  State<ManufacturerCustomerAllTopSellingProductsScreen> createState() =>
      _CustomerAllTopSellingProductsScreenState();
}

class _CustomerAllTopSellingProductsScreenState
    extends State<ManufacturerCustomerAllTopSellingProductsScreen> {
  final ManufacturerInventoryController controller =
      getOrPut<ManufacturerInventoryController>(() => ManufacturerInventoryController());
  final ScrollController _scrollController = ScrollController();

  late final ManufacturerProductSelfPickupController _cartController;

  ViewBusinessDetailsController? get _viewBusinessDetailsController =>
      Get.isRegistered<ViewBusinessDetailsController>()
          ? Get.find<ViewBusinessDetailsController>()
          : null;

  @override
  void initState() {
    super.initState();
    _cartController = getOrPut<ManufacturerProductSelfPickupController>(
        () => ManufacturerProductSelfPickupController());
    _scrollController.addListener(_onScroll);
    // Defer the fetch until after the first frame so the controller's
    // observable mutations don't re-enter an in-flight build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchBusinessProducts(
          visitBusinessId: widget.visitBusinessId,
          isDiscountedProducts: true);
    });
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
    final bDetails =
        _viewBusinessDetailsController?.visitedBusinessProfileDetails?.data;
    if (_cartController.isVariantInCart(id)) {
      _cartController.removeFromCart(product);
    } else {
      _cartController.addToCart(
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
      controller.fetchBusinessProducts(
          visitBusinessId: widget.visitBusinessId,
          isDiscountedProducts: true,
          isLoadMore: true);
    }
  }

  Future<void> _onRefresh() async {
    await controller.fetchBusinessProducts(
      visitBusinessId: widget.visitBusinessId,
      isDiscountedProducts: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  // Extra bottom space so the last row isn't hidden behind
                  // the floating cart pill.
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            );
          }),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: ManufacturerProductSelfPickupCart(controller: _cartController),
          ),
        ],
      ),
    );
  }
}

class _TopSellingProductTile extends StatelessWidget {
  final GetProductData product;
  final ManufacturerProductSelfPickupController cartController;
  final void Function(GetProductData) onToggleCart;
  final String? Function(GetProductData) firstVariantId;

  const _TopSellingProductTile({
    required this.product,
    required this.cartController,
    required this.onToggleCart,
    required this.firstVariantId,
  });

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
              child: ManufacturerProductTopSellingImage(
                product: product,
                cartOverlay: Obx(() {
                  final cart = cartController.selectedProductVariants;
                  // ignore: unused_local_variable
                  final _ = cart.length;
                  final id = firstVariantId(product);
                  final added = cartController.isVariantInCart(id);
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                    onPressed: id == null ? null : () => onToggleCart(product),
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
          ),
          ManufacturerProductTopSellingInfoSection(product: product),
        ],
      ),
    );
  }
}
