import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/widget/automotive_product_top_selling_tile.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/widget/automotive_product_self_pickup_cart.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AutomotiveCustomerAllTopSellingProductsScreen extends StatefulWidget {
  final String visitUserId;

  const AutomotiveCustomerAllTopSellingProductsScreen({super.key, required this.visitUserId});

  @override
  State<AutomotiveCustomerAllTopSellingProductsScreen> createState() =>
      _AutomotiveCustomerAllTopSellingProductsScreenState();
}

class _AutomotiveCustomerAllTopSellingProductsScreenState
    extends State<AutomotiveCustomerAllTopSellingProductsScreen> {
  final AutomotiveInventoryController controller =
      getOrPut<AutomotiveInventoryController>(() => AutomotiveInventoryController());
  final ScrollController _scrollController = ScrollController();

  late final AutomotiveProductSelfPickupController _cartController;

  ViewBusinessDetailsController? get _viewBusinessDetailsController =>
      Get.isRegistered<ViewBusinessDetailsController>() ? Get.find<ViewBusinessDetailsController>() : null;

  @override
  void initState() {
    super.initState();
    _cartController =
        getOrPut<AutomotiveProductSelfPickupController>(() => AutomotiveProductSelfPickupController());
    _scrollController.addListener(_onScroll);
    // Defer the fetch until after the first frame so the controller's
    // observable mutations don't re-enter an in-flight build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchBusinessProducts(visitUserId: widget.visitUserId, isDiscountedProducts: true);
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
    final bDetails = _viewBusinessDetailsController?.visitedBusinessProfileDetails?.data;
    if (_cartController.isVariantInCart(id)) {
      _cartController.removeFromCart(product);
    } else {
      _cartController.addToCart(
        product,
        userId: widget.visitUserId,
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
          visitUserId: widget.visitUserId, isDiscountedProducts: true, isLoadMore: true);
    }
  }

  /// Opens the native share sheet with the product's BlueEra deep link
  /// and its name.
  Future<void> _onShareTap(GetProductData product) async {
    final details = product.product.details;
    final rawName = details?.name.trim() ?? '';
    final name = rawName.isNotEmpty ? rawName : 'this product';
    final shareLink = automotiveDeepLink(automotiveId: details?.id);

    await ShareService.instance.openShareSheet(
      text: "Check out $name on BlueEra:\n$shareLink",
      subject: name,
    );
  }

  Future<void> _onRefresh() async {
    await controller.fetchBusinessProducts(
      visitUserId: widget.visitUserId,
      isDiscountedProducts: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(
        appBarColor: AppColors.white,
        title: 'Top Selling AutomotiveProducts',
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            final items = controller.allProducts;
            final status = controller.ownDraftAndPublicProductResponse.value.status;
            final isInitialLoading = status == Status.INITIAL && items.isEmpty;
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
                  ...buildNativeAdGridSlivers(
                    itemCount: items.length,
                    keyPrefix: 'auto_top_native_ad',
                    adPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                    gridSliverBuilder: (start, end) => SliverPadding(
                      padding: EdgeInsets.all(SizeConfig.size10),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childCount: end - start,
                        itemBuilder: (context, i) => _AutomotiveTopSellingProductTile(
                          product: items[start + i],
                          cartController: _cartController,
                          onToggleCart: _onToggleCart,
                          onShare: _onShareTap,
                          firstVariantId: _firstVariantId,
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
            child: AutomotiveProductSelfPickupCart(controller: _cartController),
          ),
        ],
      ),
    );
  }
}

class _AutomotiveTopSellingProductTile extends StatelessWidget {
  final GetProductData product;
  final AutomotiveProductSelfPickupController cartController;
  final void Function(GetProductData) onToggleCart;
  final Future<void> Function(GetProductData) onShare;
  final String? Function(GetProductData) firstVariantId;

  const _AutomotiveTopSellingProductTile({
    required this.product,
    required this.cartController,
    required this.onToggleCart,
    required this.onShare,
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
              child: AutomotiveProductTopSellingImage(
                product: product,
                cartOverlay: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => onShare(product),
                      icon: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 4),
                          ],
                        ),
                        child: LocalAssets(
                          imagePath: AppIconAssets.share_bold,
                          imgColor: AppColors.black,
                        ),
                      ),
                    ),
                    Obx(() {
                      final cart = cartController.selectedProductVariants;
                      // ignore: unused_local_variable
                      final _ = cart.length;
                      final id = firstVariantId(product);
                      final added = cartController.isVariantInCart(id);
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: id == null ? null : () => onToggleCart(product),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: added ? AppColors.greenShade : AppColors.blackMite,
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
                  ],
                ),
              ),
            ),
          ),
          AutomotiveProductTopSellingInfoSection(product: product),
        ],
      ),
    );
  }
}
