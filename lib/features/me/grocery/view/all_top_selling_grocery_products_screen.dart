import 'dart:developer' as dev;

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_business_products_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    ctrl.addToCart(
      productVariant,
      inventoryId: item.sId,
      productId: productVariant.sId,
      businessId: widget.visitBusinessId,
      businessName: bDetails?.businessName,
      businessLogo: bDetails?.logo,
      businessAddress: bDetails?.address,
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

          // Cart bar — placed as a direct Positioned child of this Stack
          // (not wrapped in SelfPickupCommonCartUi) so that layout and
          // StackParentData propagation are unambiguous even with
          // StackFit.expand. Driven by its own Obx that reads
          // `length` (a directly-tracked RxList accessor) so it
          // reliably reacts to every cart mutation.
          if (_isCustomerMode && _groceryCustomerController != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Obx(() {
                final cart = _groceryCustomerController!
                    .selectedGroceriesVariants;
                final itemCount = cart.length;
                dev.log(
                  '[AllTopSelling] cart-bar Obx rebuild itemCount=$itemCount '
                  'ids=${cart.map((v) => v.sId).toList()}',
                  name: 'AllTopSelling',
                );
                if (itemCount == 0) return const SizedBox.shrink();
                return SafeArea(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GrocerySelfPickUpCartScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustomText(
                              '$itemCount ${itemCount == 1 ? AppStrings.groceryViewItemLabel.tr : AppStrings.groceryViewItemsLabel.tr}',
                              fontSize: 13,
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          CustomText(
                            AppStrings.groceryViewViewCart.tr,
                            fontSize: 16,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _TopSellingProductTile extends StatelessWidget {
  final BusinessProductData item;

  /// Non-null ⇒ customer mode: renders the add/remove overlay on the
  /// image and subscribes its `Obx` to the controller's cart list so it
  /// stays in sync with every other surface (visit store, product
  /// listing, cart bar, etc.).
  final GrocerySelfPickupConsumerController? customerController;

  /// Called when the user taps the add/remove icon. Ignored when
  /// [customerController] is null.
  final VoidCallback? onToggleCart;

  const _TopSellingProductTile({
    required this.item,
    this.customerController,
    this.onToggleCart,
  });

  bool get _isCustomerMode => customerController != null;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.product?.images?.isNotEmpty ?? false;
    final imageUrl = hasImage ? item.product?.images!.first.url ?? '' : '';

    final imageChild = hasImage
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.cover,
            ),
          )
        : LocalAssets(
            imagePath: AppIconAssets.place_holder_image,
            boxFix: BoxFit.cover,
          );

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
              child: _isCustomerMode
                  ? Stack(
                      children: [
                        Positioned.fill(child: imageChild),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Obx(() {
                            // Explicitly touch `.length` first — that
                            // read always registers this Obx as a
                            // listener on the cart RxList. Then do the
                            // actual membership check. Without the
                            // explicit length read, GetX may not
                            // register the subscription reliably.
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
                      ],
                    )
                  : imageChild,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  '${item.product?.name ?? ''}',
                  fontSize: SizeConfig.small,
                  maxLines: 1,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                FittedBox(
                  child: Row(
                    children: [
                      if (item.productVariant?.isVegetarian != null) ...[
                        FoodTypeIndicator(
                          isVegetarian:
                              item.productVariant?.isVegetarian! ?? false,
                        ),
                        SizedBox(width: SizeConfig.size6),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              width: 0.5, color: AppColors.greyE5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 0.5),
                        child: CustomText(
                          '${item.productVariant?.variantName ?? ''}',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice:
                      "${AppConstants.rupeeSymbol}${item.minSellingPrice}",
                  mrp: "${AppConstants.rupeeSymbol}${item.minMrp}",
                  discount: "${item.avgDiscount}% OFF",
                ),
                SizedBox(height: SizeConfig.size4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
