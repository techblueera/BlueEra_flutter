import 'dart:developer' as dev;

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_self_pickup_cart.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_top_selling_tile.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

/// Paginated grid of all "Top Selling Products" for a grocery business.
///
/// Opened from the "View All" action on the Top Selling Products section of
/// either [MyGroceryStoreScreen] (owner view) or [VisitGroceryStoreScreen]
/// (customer view). Both flows share [GroceryController]; the [otherStore]
/// flag picks between the authenticated `business-products` endpoint and
/// the `public/business-products` endpoint.
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

  /// Returns true if the given product variant is currently in the cart.
  /// Only meaningful in customer mode.
  bool _isVariantInCart(BusinessProductData item) {
    final ctrl = _groceryCustomerController;
    if (ctrl == null) return false;
    final variantId = item.productVariant?.sId;
    if (variantId == null) return false;
    return ctrl.selectedGroceriesVariants.any((v) => v.sId == variantId);
  }

  void _onToggleCart(BusinessProductData item) {
    final ctrl = _groceryCustomerController;
    if (ctrl == null) {
      dev.log(
        '[AllTopSelling] toggle aborted — ctrl is null',
        name: 'AllTopSelling',
      );
      return;
    }
    final productVariant = item.productVariant;
    if (productVariant == null) {
      commonSnackBar(message: AppStrings.groceryViewNoVariantsAvailable.tr);
      return;
    }

    final beforeLen = ctrl.selectedGroceriesVariants.length;
    final already = _isVariantInCart(item);
    dev.log(
      '[AllTopSelling] toggle tapped variantId=${productVariant.sId} '
      'alreadyInCart=$already beforeLen=$beforeLen '
      'ctrlHash=${identityHashCode(ctrl)}',
      name: 'AllTopSelling',
    );

    if (already) {
      ctrl.removeFromCart(productVariant);
      dev.log(
        '[AllTopSelling] after removeFromCart len=${ctrl.selectedGroceriesVariants.length}',
        name: 'AllTopSelling',
      );
      return;
    }

    final bDetails = _viewBusinessDetailsController
        ?.visitedBusinessProfileDetails
        ?.data;
    // Resolve image: prefer product-level image, fallback to variant image.
    String? productImage;
    if (item.product?.images?.isNotEmpty ?? false) {
      productImage = item.product!.images!.first.url;
    } else if (productVariant.images?.isNotEmpty ?? false) {
      productImage = productVariant.images!.first.url;
    }

    ctrl.addToCart(
      productVariant,
      inventoryId: item.sId,
      productId: productVariant.sId,
      businessId: widget.visitBusinessId,
      businessName: bDetails?.businessName,
      businessLogo: bDetails?.logo,
      businessAddress: bDetails?.address,
      productImage: productImage,
    );
    dev.log(
      '[AllTopSelling] after addToCart len=${ctrl.selectedGroceriesVariants.length} '
      'bDetails.name=${bDetails?.businessName} visitBusinessId=${widget.visitBusinessId}',
      name: 'AllTopSelling',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
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
                      childCount: items.length,
                      itemBuilder: (context, index) => _TopSellingProductTile(
                        item: items[index],
                        customerController: _isCustomerMode
                            ? _groceryCustomerController
                            : null,
                        onToggleCart: _isCustomerMode
                            ? () => _onToggleCart(items[index])
                            : null,
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
              child: GrocerySelfPickupCart(
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

  final GrocerySelfPickupConsumerController? customerController;

  final VoidCallback? onToggleCart;

  const _TopSellingProductTile({
    required this.item,
    this.customerController,
    this.onToggleCart,
  });

  bool get _isCustomerMode => customerController != null;

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
              child: GroceryTopSellingImage(
                item: item,
                cartOverlay: _isCustomerMode
                    ? Obx(() {
                        final cart = customerController!
                            .selectedGroceriesVariants;
                        final cartLen = cart.length;
                        final variantId = item.productVariant?.sId;
                        final added = variantId != null &&
                            cart.any((v) => v.sId == variantId);
                        dev.log(
                          '[AllTopSelling] tile Obx variantId=$variantId '
                          'cartLen=$cartLen added=$added '
                          'ctrlHash=${identityHashCode(customerController)} '
                          'listHash=${identityHashCode(cart)} '
                          'cartIds=${cart.map((v) => v.sId).toList()}',
                          name: 'AllTopSelling',
                        );
                        return IconButton(
                          onPressed: onToggleCart,
                          icon: Container(
                            // padding: const EdgeInsets.all(4),
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
          GroceryTopSellingInfoSection(item: item),
        ],
      ),
    );
  }
}
