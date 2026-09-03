import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_product_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/widget/automotive_product_self_pickup_cart.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/common/store/widget/store_sort_bar.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_store_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';

/// Consumer discover screen for AUTO PARTS shops.
///
/// Lists businesses off `business/search` as the same flat white rows the
/// grocery / restaurant / product listings use (see [AutomotiveStoreCard]) —
/// logo, rating, distance, address and the shop's product count.
///
/// The search is scoped on all three filters the endpoint takes:
/// `typeOfBusiness=Automotive`, `category=<auto parts tag>` — FIXED, this screen
/// is the Discover card's PARTS destination and nothing else — and
/// `subCategory`, which is what the tab strip moves between. The vertical's
/// other categories (vehicle service, showrooms, transport & logistics) are
/// different errands and have their own screens, so offering them as tabs here
/// would mix three listings into one.
///
/// It used to list individual PARTS off `inventory/public/global-products` in a
/// 2-column grid. A parts catalogue is the wrong first step here: the Discover
/// tile that opens this screen means "find me an automotive shop nearby", and
/// the shop is what the user travels to. The parts are one tap further in, on
/// the store screen each row opens.
class AutomotiveCategoryDiscoverScreen extends StatefulWidget {
  /// Sub-category (a [SubCategories.sId]) to open on. Null lands on the "All"
  /// tab — every auto-parts shop nearby.
  final String? initialSubCategoryId;

  const AutomotiveCategoryDiscoverScreen({super.key, this.initialSubCategoryId});

  @override
  State<AutomotiveCategoryDiscoverScreen> createState() =>
      _AutomotiveCategoryDiscoverScreenState();
}

class _AutomotiveCategoryDiscoverScreenState
    extends State<AutomotiveCategoryDiscoverScreen> {
  final controller = getOrPut(() => StoreController());
  final AuthController _authController = Get.find<AuthController>();

  /// Active sort chip. See [StoreSort] for why this is applied over the loaded
  /// list rather than sent to the API.
  StoreSort _sort = StoreSort.nearest;

  /// The AUTOMOTIVE categories off `/category` — auto parts, vehicle service,
  /// and the rest. Only one of them concerns this screen.
  List<CategoryData> get _automotiveCategories =>
      _authController.businessOnboardingAutomotiveServicesCategories;

  /// The "auto parts" category, matched on its tag rather than a hardcoded id.
  ///
  /// Matching on `contains('PART')` because the backend has spelled it both
  /// `AUTO_PARTS` and `VEHICLE_PARTS`. Null only while `/category` is still in
  /// flight — see the worker in [initState].
  CategoryData? get _partsCategory {
    for (final c in _automotiveCategories) {
      if ((c.tagId ?? '').toUpperCase().contains('PART')) return c;
    }
    return null;
  }

  /// The tab strip's contents: the sub-categories the auto-parts category
  /// already carries. `/category` returns them nested on each category, so
  /// there is no second call to make here.
  List<SubCategories> get _subCategories =>
      _partsCategory?.subCategories ?? const <SubCategories>[];

  /// Sentinel id for the leading "All" tab, which clears the `subCategory`
  /// filter. Mirrors the All tab on the product / grocery screens.
  static const String _allTabId = 'ALL_AUTO_PARTS';
  static const String _allTabLabel = 'All';

  /// `SubCategories.sId` of the selected tab — null while "All" is active.
  /// Tracked by id rather than list index because the All tab has no backing
  /// sub-category to index into.
  String? _selectedSubCategoryId;

  /// Fires once if `/category` lands after this screen was built, so a cold
  /// open still gets its tabs and its category filter.
  Worker? _categoryWorker;

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

  // Parts, not vehicles: an engine bay, an oil change and a workshop parts
  // wall. This screen sells components, so whole-car photography sold the
  // wrong thing even when it loaded.
  //
  // The previous three URLs were freepik hotlinks shared with the vehicle
  // sales screen; their ids resolved to a monkey, dried fruit and a flower,
  // watermarked. Each URL below was downloaded and viewed before committing —
  // do the same for any replacement, since the slug in a stock URL is
  // decorative and proves nothing about what is served.
  final List<String> _bannerImages = const [
    'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=1380&q=80',
    'https://images.unsplash.com/photo-1487754180451-c456f719a1fc?w=1380&q=80',
    'https://images.unsplash.com/photo-1530046339160-ce3e530c7d2f?w=1380&q=80',
  ];

  @override
  void initState() {
    super.initState();
    // AUTOMOTIVE, not Product. It drives two things: which vertical
    // `business/search` lists, and which inventory service answers the product
    // counts on each row — automotive-service, not product-service, which would
    // return a clean, wrong `0` for these shops.
    controller.typeOfBusiness = BusinessType.Automotive.name;
    _selectedSubCategoryId = widget.initialSubCategoryId;
    _applyFilters();
    // Cache-aware: re-entry serves the last list instantly instead of
    // re-hitting the API. Pull-to-refresh is the explicit force-fresh path.
    controller.getAllStoreNearByIfNeeded();

    // `/category` is loaded at startup, but a cold open can beat it. Without
    // this the screen would search the whole Automotive vertical — no
    // `category` param, so service garages and showrooms in the list — and show
    // no tabs, with nothing ever arriving to correct either.
    if (_partsCategory == null) {
      _categoryWorker = ever<List<CategoryData>>(
        _authController.businessOnboardingAutomotiveServicesCategories,
        (_) {
          if (!mounted || _partsCategory == null) return;
          _categoryWorker?.dispose();
          _categoryWorker = null;
          setState(_applyFilters);
          controller.getAllStoreNearByIfNeeded();
        },
      );
    }
  }

  @override
  void dispose() {
    _categoryWorker?.dispose();
    super.dispose();
  }

  /// Push this screen's scope onto the shared store controller.
  ///
  /// All three filters go into [StoreController]'s cache identity, so each tab
  /// keeps its own cache entry instead of overwriting its neighbour's — which
  /// is what makes switching back to a tab instant.
  void _applyFilters() {
    controller.businessCategoryId = _partsCategory?.tagId;
    controller.businessSubCategoryId = _selectedSubCategoryId;
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
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
                AppStrings.automotiveLeaveWithoutOrdering,
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
    // "All" leads, then one tab per SUB-category of auto parts — tyres,
    // batteries, lubricants and so on, which is the axis a parts shopper
    // actually browses. The category above them never changes; see the class
    // doc for why the vertical's other categories aren't offered here.
    //
    // "All" is a real tab rather than a placeholder for a list that hasn't
    // loaded: it maps to the search WITHOUT a `subCategory` param, so it is the
    // one tab that is always valid — the strip renders and is usable before
    // (and even without) the sub-categories landing.
    //
    // No `imageUrl`: `/category` carries artwork per category, not per
    // sub-category, so these are text tabs.
    final tabs = <StickyCategory>[
      const StickyCategory(id: _allTabId, name: _allTabLabel),
      for (final sub in _subCategories)
        StickyCategory(id: sub.sId ?? '', name: sub.name ?? ''),
    ];
    final selectedId = _selectedSubCategoryId ?? _allTabId;

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
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyCategoryHeaderDelegate(
                topPadding: statusBarHeight,
                // The header paints a search bar; this is what it opens —
                // the shared store search, scoped to this vertical by its
                // StoreSearchConfig. Tapping a result opens that profile.
                onSearchTap: () => Get.to(
                    () => StoreSearchScreen(config: StoreSearchConfig.automotive())),
                // Let multi-word category names wrap to two lines before
                // ellipsising, instead of clamping to a single line.
                singleLineLabel: false,
                categories: tabs,
                selectedId: selectedId,
                onCategoryTap: (item) {
                  // The All tab is the absence of a filter, not a value.
                  final subId = item.id == _allTabId ? null : item.id;
                  if (subId == _selectedSubCategoryId) return;
                  setState(() => _selectedSubCategoryId = subId);
                  _applyFilters();
                  // Cache-aware, like the other listings — a tab viewed
                  // recently comes back from its own cache entry.
                  controller.getAllStoreNearByIfNeeded();
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

  // ── Store list ──────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Obx(() {
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return _buildSkeletonLoading();
      }
      if (controller.allStore.isEmpty) {
        return _empty(AppStrings.automotiveNoProductsInCategory.tr);
      }

      // Ordered copy — see [sortStores]. Built inside the Obx so it re-runs when
      // a page lands AND when the counts call answers (the products sort reads
      // `storeCounts`, which is observable).
      final stores = sortStores(controller.allStore, _sort);
      // Native ads interleaved between the store cards at the shared cadence
      // (single source of truth in native_ad_list_inserter.dart), never after
      // the last card.
      final rows = buildNativeAdRows(stores.length);
      final showFooter = controller.isAllStoreLoadingMore.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoreSortBar(
            sort: _sort,
            onChanged: (s) => setState(() => _sort = s),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.getAllStoreNearBy(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: SizeConfig.size12,
                  right: SizeConfig.size12,
                  // Each card supplies the gap below itself.
                  top: SizeConfig.size4,
                  bottom: SizeConfig.paddingL + 70,
                ),
                itemCount: rows.length + (showFooter ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= rows.length) return _footerLoader();
                  final row = rows[index];
                  if (row.isAd) {
                    return NativeAdSlot(
                      adOrdinal: row.adOrdinal,
                      keyPrefix: 'automotive_store_native_ad',
                    );
                  }
                  return AutomotiveStoreCard(store: stores[row.contentIndex]);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Mirrors the real row — ringed avatar, name, rating line, location line and
  /// the trailing products box — so the swap to real content reads as a load
  /// finishing rather than a relayout.
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: SizeConfig.size4,
        left: SizeConfig.size12,
        right: SizeConfig.size12,
      ),
      itemCount: 5,
      itemBuilder: (_, __) => buildLoadingShimmer(
        child: Container(
          margin: EdgeInsets.only(bottom: SizeConfig.size10),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size14,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              shimmerContainer(width: 64, height: 64, radius: 32),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shimmerContainer(height: 17, width: 170, radius: 4),
                    SizedBox(height: SizeConfig.size8),
                    shimmerContainer(height: 13, width: 130, radius: 4),
                    SizedBox(height: SizeConfig.size8),
                    shimmerContainer(height: 13, radius: 4),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              shimmerContainer(width: 62, height: 46, radius: 10),
            ],
          ),
        ),
      ),
    );
  }

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
