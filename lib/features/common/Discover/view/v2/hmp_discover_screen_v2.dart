import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/hmp_products_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/v2/hmp_store_details_discover_screen_v2.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/hmp_profile_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// **v2** home-made-product discover.
///
/// Banner + sticky level-0 category tabs (header mirrors
/// [AutomotiveCategoryDiscoverScreen]); each tab loads its products via
/// `ProductRepo.fetchProductsRepo` (`ownerType = User`, `categoryId`). Products
/// render in a 2-column grid.
class HmpDiscoverScreenV2 extends StatefulWidget {
  const HmpDiscoverScreenV2({super.key});

  @override
  State<HmpDiscoverScreenV2> createState() => _HmpDiscoverScreenV2State();
}

class _HmpDiscoverScreenV2State extends State<HmpDiscoverScreenV2> {
  static const Color _primary = AppColors.primaryColor;
  static const Color _primaryDeep = AppColors.blue5CAF;

  late final HmpProductsDiscoverController controller;
  Worker? _catWorker;
  Worker? _selWorker;

  LinearGradient get _bgGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.blue5CAF.withValues(alpha: 0.1),
          AppColors.blue5CAF.withValues(alpha: 0.8),
        ],
      );

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/arrangement-handmade-soap-bars_23-2148990916.jpg?w=1380",
    "https://img.freepik.com/free-photo/composition-aromatic-handmade-candles_23-2148906327.jpg?w=1380",
    "https://img.freepik.com/free-photo/handmade-pottery-arrangement-still-life_23-2149385017.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.put(HmpProductsDiscoverController());
    // The sticky header is not reactive on its own — rebuild it when the
    // categories arrive or the active tab changes.
    _catWorker = ever(controller.categories, (_) {
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
    Get.delete<HmpProductsDiscoverController>();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
      controller.onScrollEnd();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final categories = controller.categories;
    final selIndex = controller.selectedCategoryIndex.value;
    final selectedId = (selIndex >= 0 && selIndex < categories.length)
        ? categories[selIndex].slugId
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                  onBack: () => Navigator.of(context).pop(),
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
                            id: c.slugId,
                            name: c.name,
                            imageUrl: c.icon,
                          ))
                      .toList(),
                  selectedId: selectedId,
                  onCategoryTap: (item) {
                    final idx = categories
                        .indexWhere((c) => c.slugId == item.id);
                    if (idx >= 0) controller.onCategorySelected(idx);
                  },
                  onBack: () => Navigator.of(context).pop(),
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
            if (isIndividualUser())
              Positioned(
                right: 16,
                bottom: 0,
                child: SafeArea(child: _buildPostFab()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isCategoriesLoading.value &&
          controller.categories.isEmpty) {
        return _loader();
      }
      if (controller.categories.isEmpty) {
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
                mainAxisExtent: _HmpProductGridCard.cardHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _HmpProductGridCard(
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

  // Tapping a product opens its seller's home-made-product store (v2). The v2
  // details screen fetches the earn-profile by userId itself; we pass the
  // name/logo we already have so the header shows instantly.
  void _openStore(GetProductData data) {
    // The category-grouped `all-business-products` response carries no
    // `user_id`; for ownerType=User the seller's userId comes back as the
    // inventory `businessId`. Prefer user_id, fall back to businessId.
    final rawUserId = (data.product.user_id ?? '').trim();
    final userId =
        rawUserId.isNotEmpty ? rawUserId : (data.product.businessId ?? '').trim();
    if (userId.isEmpty) return;
    Get.to(() => HmpStoreDetailsDiscoverScreenV2(
          userId: userId,
          serviceName: data.product.business_name,
          serviceLogo: data.product.business_logo,
        ));
  }

  /// Floating "Post Product" action — a gradient extended FAB pill, so the add
  /// affordance no longer crowds the banner/category header.
  Widget _buildPostFab() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onPostTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primaryDeep],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_business_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              CustomText(
                'Add Own Product',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPostTap() {
    if (isGuestUser() || isBusinessUser()) return;
    final viewProfileController =
        Get.isRegistered<ViewPersonalDetailsController>()
            ? Get.find<ViewPersonalDetailsController>()
            : getOrPut(() => ViewPersonalDetailsController(), permanent: true);
    if (viewProfileController.earnProfileType.contains('homeMadeProduct')) {
      Get.to(() => const EarnServiceDashboardView(earnType: 'homeMadeProduct'));
    } else {
      Get.to(() => const HomeProfileScreen());
    }
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

/// Grid product card — rounded white tile with an image slideshow on top, then
/// the product name (2 lines) and a [PriceRow]. Mirrors the automotive
/// consumer grid card; the whole tile opens the seller's store.
class _HmpProductGridCard extends StatelessWidget {
  final GetProductData data;
  final VoidCallback? onTap;

  const _HmpProductGridCard({required this.data, this.onTap});

  static double get _imageHeight => SizeConfig.size150 - 10;
  static const double _nameLineHeight = 1.3;
  static double get _nameBlockHeight =>
      SizeConfig.medium * _nameLineHeight * 2;
  static const double _buttonHeight = 32.0;
  static const double _buttonSpacing = 8.0;

  static double get cardHeight {
    const priceRowHeight = 26.0;
    return _imageHeight +
        SizeConfig.size10 * 2 +
        _nameBlockHeight +
        SizeConfig.size5 +
        priceRowHeight +
        _buttonSpacing +
        _buttonHeight;
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
                  const SizedBox(height: _buttonSpacing),
                  // Explicit CTA so the tap affordance is obvious. The whole
                  // card is also tappable (same [onTap]); this button just
                  // makes the action clear.
                  Container(
                    height: _buttonHeight,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CustomText(
                          'View Store',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: Colors.white),
                      ],
                    ),
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
