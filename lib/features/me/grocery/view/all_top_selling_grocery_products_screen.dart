import 'dart:developer' as dev;

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/customer_grocery_self_pickup_cart.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_qty_stepper.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_top_selling_product_card.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_variants_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AllTopSellingGroceryProductsScreen extends StatefulWidget {
  final String userId;
  final bool otherStore;

  /// When [otherStore] is `true` (customer flow), this is the visiting
  /// business's id — required so that add-to-cart calls can tag the cart
  /// item with the correct `businessId`. Unused in the owner flow.
  final String? visitBusinessId;

  const AllTopSellingGroceryProductsScreen({
    super.key,
    required this.userId,
    required this.otherStore,
    this.visitBusinessId,
  });

  @override
  State<AllTopSellingGroceryProductsScreen> createState() =>
      _AllTopSellingGroceryProductsScreenState();
}

class _AllTopSellingGroceryProductsScreenState
    extends State<AllTopSellingGroceryProductsScreen> {
  final controller = getOrPut(() => GroceryController());
  final ScrollController _scrollController = ScrollController();

  /// Customer-only collaborators. Resolved lazily so the owner flow (which
  /// has no cart) isn't forced to instantiate them.
  GrocerySelfPickupConsumerController? _groceryCustomerController;
  ViewBusinessDetailsController? _viewBusinessDetailsController;

  bool get _isCustomerMode => widget.otherStore;

  @override
  void initState() {
    super.initState();
    dev.log(
      '[AllTopSelling] initState otherStore=${widget.otherStore} '
      'userId=${widget.userId} visitBusinessId=${widget.visitBusinessId} '
      'customerModeCtrlRegistered=${Get.isRegistered<GrocerySelfPickupConsumerController>()}',
      name: 'AllTopSelling',
    );
    if (_isCustomerMode) {
      // IMPORTANT: explicitly specify the generic as the *non-nullable*
      // type. The assignment target is `GrocerySelfPickupConsumerController?`
      // (nullable), so without the explicit generic Dart infers
      // `T = GrocerySelfPickupConsumerController?` and GetX treats `T` and
      // `T?` as different type keys — causing `getOrPut` to create a
      // brand-new instance instead of reusing the one the visit screen
      // is mutating. That mismatch was why the cart looked empty here.
      _groceryCustomerController = getOrPut<GrocerySelfPickupConsumerController>(
        () => GrocerySelfPickupConsumerController(),
      );
      _viewBusinessDetailsController =
          Get.find<ViewBusinessDetailsController>();
      dev.log(
        '[AllTopSelling] cart on entry: '
        'length=${_groceryCustomerController!.selectedGroceriesVariants.length} '
        'ids=${_groceryCustomerController!.selectedGroceriesVariants.map((v) => v.sId).toList()} '
        'hashCode=${identityHashCode(_groceryCustomerController!.selectedGroceriesVariants)} '
        'ctrlHashCode=${identityHashCode(_groceryCustomerController)}',
        name: 'AllTopSelling',
      );
    }
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchGroceryBusinessProductsRepo(
        widget.userId,
        widget.otherStore,
      );
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
    if (position.pixels >= position.maxScrollExtent - 200) {
      controller.fetchGroceryBusinessProductsRepo(
        widget.userId,
        widget.otherStore,
        isLoadMore: true,
      );
    }
  }

  Future<void> _onRefresh() async {
    await controller.fetchGroceryBusinessProductsRepo(
      widget.userId,
      widget.otherStore,
    );
  }

  /// Adds one of [item]'s variant to the cart (first tap / "+" on the
  /// stepper). Decrement is handled directly in the tile via the
  /// controller, since it needs no business context.
  void _onAddToCart(BusinessProductData item) {
    final ctrl = _groceryCustomerController;
    if (ctrl == null) return;
    final productVariant = item.productVariant;
    if (productVariant == null) {
      commonSnackBar(message: AppStrings.groceryViewNoVariantsAvailable.tr);
      return;
    }

    final bDetails = _viewBusinessDetailsController
        ?.visitedBusinessProfileDetails
        ?.data;
    ctrl.addToCart(
      productVariant,
      inventoryId: item.sId,
      productId: productVariant.sId,
      businessId: widget.visitBusinessId,
      businessName: bDetails?.businessName,
      businessLogo: bDetails?.logo,
      businessAddress: bDetails?.address,
      // Shared resolver (variant image → product image) so the cart
      // thumbnail matches the tile.
      productImage: item.primaryImageUrl,
    );
  }

  /// Add a **specific** variant to the cart (used by the variants sheet, where
  /// the customer picks the exact variant). Mirrors [_onAddToCart] but for an
  /// explicit variant rather than the product's representative one.
  void _onAddVariantToCart(BusinessProductData product, ProductVariants variant) {
    final ctrl = _groceryCustomerController;
    if (ctrl == null) return;
    final bDetails =
        _viewBusinessDetailsController?.visitedBusinessProfileDetails?.data;
    ctrl.addToCart(
      variant,
      inventoryId: product.sId,
      productId: variant.sId,
      businessId: widget.visitBusinessId,
      businessName: bDetails?.businessName,
      businessLogo: bDetails?.logo,
      businessAddress: bDetails?.address,
      productImage: variant.images?.isNotEmpty ?? false
          ? variant.images!.first.url
          : product.primaryImageUrl,
    );
  }

  /// Open the variants sheet for a product. Customer mode wires the cart;
  /// owner mode shows view + edit/delete.
  void _openVariantsSheet(GroceryProductVariantGroup group) {
    showGroceryVariantsSheet(
      context: context,
      productName: group.product.product?.name ?? '',
      productImageUrl: group.product.productImageUrlOnly,
      variants: group.variants,
      cartController: _isCustomerMode ? _groceryCustomerController : null,
      onAddToCart: _isCustomerMode
          ? (variant) => _onAddVariantToCart(group.product, variant)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: AppStrings.groceryViewTopSellingProducts.tr,
      ),
      body: Stack(
        // Force the Stack to fill the Scaffold body so the cart bar's
        // `Positioned(bottom: 20)` is pinned to the real bottom — even on
        // the initial frame where the Obx returns a tiny loading spinner.
        fit: StackFit.expand,
        children: [
          Obx(() {
            final items = controller.groceryBusinessProductsList;
            // One card per product (the list can carry one row per variant);
            // tapping a card opens the variants sheet.
            final groups = groupBusinessProductsByProduct(items.toList());
            final status =
                controller.fetchGroceryBusinessProductsResponse.value.status;
            final isInitialLoading =
                status == Status.INITIAL && items.isEmpty;
            final isLoadingMore =
                controller.isBusinessProductsLoadingMore.value;

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
                  children: [
                    const SizedBox(height: 80),
                    EmptyStateWidget(
                      message: AppStrings.groceryViewNoTopSellingYet.tr,
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
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return _TopSellingProductTile(
                          item: group.product,
                          variants: group.variants,
                          customerController: _isCustomerMode
                              ? _groceryCustomerController
                              : null,
                          onIncrement: _isCustomerMode
                              ? () => _onAddToCart(group.product)
                              : null,
                          onTapTile: () => _openVariantsSheet(group),
                        );
                      },
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
                  // Bottom breathing room so the last row isn't hidden
                  // behind the floating cart bar when customer mode is on.
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _isCustomerMode ? 120 : 24,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (_isCustomerMode && _groceryCustomerController != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: CustomerGrocerySelfPickupCart(
                controller: _groceryCustomerController!,
              ),
            ),
        ],
      ),
    );
  }
}

class _TopSellingProductTile extends StatelessWidget {
  final BusinessProductData item;
  final List<ProductVariants> variants;

  final GrocerySelfPickupConsumerController? customerController;

  /// Add-one handler (owns the business context). Decrement is handled
  /// inline against [customerController].
  final VoidCallback? onIncrement;

  /// Opens the variants sheet for this product (pick a variant to add, or
  /// view/edit/delete in owner mode).
  final VoidCallback? onTapTile;

  const _TopSellingProductTile({
    required this.item,
    required this.variants,
    this.customerController,
    this.onIncrement,
    this.onTapTile,
  });

  bool get _isCustomerMode => customerController != null;

  @override
  Widget build(BuildContext context) {
    // Same shared card as the admin home top-selling rail so both surfaces
    // look identical. Customer mode shows the add/remove stepper over the
    // image; the whole card taps through to the variants sheet.
    return GestureDetector(
      onTap: onTapTile,
      behavior: HitTestBehavior.opaque,
      child: GroceryTopSellingProductCard(
        product: item,
        variants: variants,
        imageOverlay: _isCustomerMode
            ? Obx(() {
                final variant = item.productVariant;
                final qty = customerController!.getQuantity(variant?.sId);
                return GroceryQtyStepper(
                  quantity: qty,
                  onIncrement: onIncrement ?? () {},
                  onDecrement: () {
                    if (variant == null) return;
                    customerController!.removeFromCart(variant);
                  },
                );
              })
            : null,
      ),
    );
  }
}
