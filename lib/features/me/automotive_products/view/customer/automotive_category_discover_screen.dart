import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_discover_controller.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_product_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/widget/automotive_product_self_pickup_cart.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Consumer category-discover screen for automotive products.
///
/// Banner + sticky category tabs follow the HMF discover layout
/// ([HmfCategoryDiscoverScreen]); the tabs are the level-0 nested
/// categories and each tab loads its public products via the
/// `inventory/public/global-products` endpoint. Products are shown in a
/// 2-column grid of cards styled like [ManufacturerOwnProductCard].
class AutomotiveCategoryDiscoverScreen extends StatefulWidget {
  /// Optional business filter — defaults to the logged-in business.
  final String? businessId;

  const AutomotiveCategoryDiscoverScreen({super.key, this.businessId});

  @override
  State<AutomotiveCategoryDiscoverScreen> createState() =>
      _AutomotiveCategoryDiscoverScreenState();
}

class _AutomotiveCategoryDiscoverScreenState
    extends State<AutomotiveCategoryDiscoverScreen> {
  late final AutomotiveDiscoverController controller;
  Worker? _catWorker;
  Worker? _selWorker;

  // Session cart — same instance the store-details cart bar watches, so a
  // confirm-on-exit prompt here reflects items added anywhere in the flow.
  final AutomotiveProductSelfPickupController _cartController =
      getOrPut<AutomotiveProductSelfPickupController>(
          () => AutomotiveProductSelfPickupController());

  static const Color _primary = AppColors.primaryColor;

  // Same blue wash that sits behind the banner + sticky tabs on the HMF
  // category-discover screen.
  LinearGradient get _bgGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.blue5CAF.withValues(alpha: 0.1),
          AppColors.blue5CAF.withValues(alpha: 0.8),
        ],
      );

  // Same automotive banners used by AllVehicleServiceScreen so the
  // Vehicle-Parts flow stays visually consistent with the rest of the
  // automotive section.
  final List<String> _bannerImages = const [
    'https://img.freepik.com/free-photo/red-car-with-trunk-that-says-toyota-it_1340-39044.jpg?w=1380',
    'https://img.freepik.com/free-photo/black-suv-car-front-view_114579-4153.jpg?w=1380',
    'https://img.freepik.com/free-photo/big-truck-road_181624-37941.jpg?w=1380',
  ];

  @override
  void initState() {
    super.initState();
    controller =
        Get.put(AutomotiveDiscoverController(businessId: widget.businessId));
    // The sticky header is not reactive on its own — rebuild it when the
    // categories arrive or the active tab changes.
    _catWorker = ever(controller.level0Categories, (_) {
      if (mounted) setState(() {});
    });
    _selWorker = ever(controller.selectedCategoryIndex, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _catWorker?.dispose();
    _selWorker?.dispose();
    Get.delete<AutomotiveDiscoverController>();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
      controller.onScrollEnd();
    }
    return false;
  }

  // ── Confirm-exit when the cart has items (same flow as ProductsStoreScreen).
  void _handleBackWithCartWarning() {
    if (_cartController.selectedProductVariants.isEmpty) {
      Get.back();
      return;
    }
    _showCartWarningDialog(
      onPlaceOrder: () {
        Get.to(() => const AutomotiveProductSelfPickUpCartScreen());
      },
    );
  }

  void _showCartWarningDialog({required VoidCallback onPlaceOrder}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_shopping_cart_rounded,
                  color: AppColors.primaryColor, size: 56),
              const SizedBox(height: 16),
              CustomText(
                'Leave without ordering?',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              CustomText(
                AppStrings.placeOrderCartWarning.tr,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        _cartController.clearCart();
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyE5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        "skip".tr,
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onPlaceOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        AppStrings.placeOrder.tr,
                        color: AppColors.white,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final categories = controller.level0Categories;
    final selIndex = controller.selectedCategoryIndex.value;
    final selectedId = (selIndex >= 0 && selIndex < categories.length)
        ? categories[selIndex].sId
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackWithCartWarning();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppColors.appBackgroundColor,
          body: Stack(
            children: [
              NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(gradient: _bgGradient),
                child: BannerCarousel(
                  images: _bannerImages,
                  onBack: _handleBackWithCartWarning,
                  statusBarHeight: statusBarHeight,
                  backgroundColor: Colors.transparent,
                  bottomBorderSide:
                      const BorderSide(color: AppColors.white, width: 2),
                ),
              ),
            ),
            if (categories.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyCategoryHeaderDelegate(
                  topPadding: statusBarHeight,
                  singleLineLabel: true,
                  categories: categories
                      .map((c) => StickyCategory(
                            id: c.sId ?? '',
                            name: c.name ?? '',
                            imageUrl: c.image,
                          ))
                      .toList(),
                  selectedId: selectedId,
                  onCategoryTap: (item) {
                    final idx =
                        categories.indexWhere((c) => (c.sId ?? '') == item.id);
                    if (idx >= 0) controller.onCategorySelected(idx);
                  },
                  onBack: _handleBackWithCartWarning,
                  backgroundGradient: _bgGradient,
                  expandedLabelColor: AppColors.white,
                ),
              ),
          ],
            body: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: _buildBody(),
            ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: AutomotiveProductSelfPickupCart(
                      controller: _cartController),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isCategoriesLoading.value &&
          controller.level0Categories.isEmpty) {
        return _loader();
      }
      if (controller.level0Categories.isEmpty) {
        return _empty('No categories found');
      }
      if (controller.isProductsFirstLoading.value) {
        return _loader();
      }
      final products = controller.products;
      if (products.isEmpty) {
        return _empty('No products in this category');
      }
      final showFooter = controller.isProductsLoadingMore.value;
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size12,
                SizeConfig.size12, SizeConfig.size8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: SizeConfig.size12,
                crossAxisSpacing: SizeConfig.size12,
                mainAxisExtent: _AutomotiveProductGridCard.cardHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _AutomotiveProductGridCard(
                  data: products[index],
                  onTap: () => _openStore(products[index]),
                ),
                childCount: products.length,
              ),
            ),
          ),
          if (showFooter)
            SliverToBoxAdapter(child: _footerLoader())
          else
            SliverToBoxAdapter(child: SizedBox(height: SizeConfig.size20)),
        ],
      );
    });
  }

  void _openStore(GetProductData data) {
    Get.toNamed(
      RouteHelper.getAutomotiveProductsStoreDetailsScreenRoute(),
      arguments: {
        ApiKeys.argProductData: data.product,
        ApiKeys.id: data.product.businessId ?? '',
        ApiKeys.providerType: ProviderType.business,
      },
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation<Color>(_primary),
        ),
      );

  Widget _footerLoader() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
        ),
      );

  Widget _empty(String message) => Padding(
        padding: EdgeInsets.all(SizeConfig.size20),
        child: EmptyStateWidget(message: message),
      );
}

/// Grid product card styled after [ManufacturerOwnProductCard]'s grid mode:
/// rounded white tile with an image slideshow on top, then the product name
/// (2 lines) and a [PriceRow]. Consumer-facing, so no admin edit affordance —
/// the whole tile opens the store details.
class _AutomotiveProductGridCard extends StatelessWidget {
  final GetProductData data;
  final VoidCallback? onTap;

  const _AutomotiveProductGridCard({required this.data, this.onTap});

  static double get _imageHeight => SizeConfig.size150 - 10;
  static const double _nameLineHeight = 1.3;
  static double get _nameBlockHeight =>
      SizeConfig.medium * _nameLineHeight * 2;

  /// Total tile height — mirrors `ManufacturerOwnProductCard.gridCardHeight`
  /// so the grid cells size consistently.
  static double get cardHeight {
    const priceRowHeight = 26.0;
    return _imageHeight +
        SizeConfig.size10 * 2 +
        _nameBlockHeight +
        SizeConfig.size5 +
        priceRowHeight;
  }

  @override
  Widget build(BuildContext context) {
    final ProductDetails? details = data.product.details;
    final variants = data.product.sellerClassification?.variants ?? const [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            SizedBox(
              height: _imageHeight,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: CustomImageSlideshow(
                  isLoading: false,
                  width: double.infinity,
                  height: _imageHeight,
                  imagePaths: details?.media ?? const [],
                  borderRadius: BorderRadius.zero,
                  onPhotoIndex: (_) {},
                ),
              ),
            ),

            // Product details
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size10,
                horizontal: SizeConfig.size8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    details?.name ?? '',
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size5),
                  if (variants.isNotEmpty)
                    PriceRow(
                      sellingPrice: '₹${variants[0].sellingPrice}',
                      mrp: '₹${variants[0].mrp}',
                      discount:
                          "${calculateDiscount('${variants[0].sellingPrice}', '${variants[0].mrp}')}% OFF",
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
