import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/common/promo/qureka_promo_banner.dart';
import 'package:BlueEra/widgets/measure_size.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/grocery_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/customer_grocery_self_pickup_cart.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_store_card.dart';
import 'package:BlueEra/features/common/store/widget/store_sort_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_enum.dart';

class GroceryStoresScreen extends StatefulWidget {
  const GroceryStoresScreen({super.key, this.initialCategoryTagId});

  /// Category tab to open on — an onboarding grocery `tagId`, e.g.
  /// [MOHALLA_KIRANA].
  ///
  /// Set by callers that already know which category the user picked (the
  /// Discover folder sheet), so tapping "Kirana Store" there lands on that tab
  /// instead of on "All Grocery" with the choice discarded. Null keeps the
  /// plain entry behaviour, including the remembered category on re-entry.
  final String? initialCategoryTagId;

  @override
  State<GroceryStoresScreen> createState() => _GroceryStoresScreenState();
}

class _GroceryStoresScreenState extends State<GroceryStoresScreen>
    with SingleTickerProviderStateMixin {
  final controller = getOrPut(() => StoreController());
  final groceryController = getOrPut(() => GroceryController());
  final groceryCustomerController =
      getOrPut(() => GrocerySelfPickupConsumerController());
  final ScrollController _nestedScrollController = ScrollController();
  final AuthController _authController = Get.find<AuthController>();
  AnimationController? _shimmerController;

  /// Minimum height for a native ad slot. The native layout needs enough room
  /// for the media view plus the header/body/CTA so the Meta native template
  /// renders without clipping.
  static const double _kMinNativeAdHeight = 300;

  /// Sentinel tag id for the leading "All Grocery" tab. Selecting it clears
  /// the category filter so the store API returns stores across every grocery
  /// category instead of a single one.
  static const String _allGroceryTagId = 'ALL_GROCERY';

  /// Synthetic category backing the "All Grocery" tab — not a real onboarding
  /// category. It only exists to represent the "show all" selection state;
  /// [StoreController.businessCategoryId] is set to null when it's active.
  final CategoryData _allGroceryCategory =
      CategoryData(tagId: _allGroceryTagId, name: 'All Grocery');

  static const List<String> _categoryOrderKeywords = [
    'kirana',
    'dairy',
    'vegetable',
    'general',
    'home',
    'stationer',
  ];

  int _categoryOrderIndex(String? name) {
    final n = (name ?? '').toLowerCase();
    for (var i = 0; i < _categoryOrderKeywords.length; i++) {
      if (n.contains(_categoryOrderKeywords[i])) return i;
    }
    return _categoryOrderKeywords.length;
  }

  List<CategoryData> get _arrCategories {
    final list = List<CategoryData>.from(
        _authController.businessOnboardingGroceriesCategories);
    list.sort((a, b) {
      final ai = _categoryOrderIndex(a.name);
      final bi = _categoryOrderIndex(b.name);
      if (ai != bi) return ai.compareTo(bi);
      return (a.name ?? '').compareTo(b.name ?? '');
    });
    return list;
  }

  int _locationVersion = 0;

  /// Active sort chip. See [StoreSort] for why this is applied over the loaded
  /// list rather than sent to the API.
  StoreSort _sort = StoreSort.nearest;

  /// Measured height of a real store card (its outer box, including the
  /// `size10` bottom margin) so native ad slots can match the card height
  /// exactly. Null until the first card has been laid out.
  double? _measuredCardHeight;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/top-view-table-full-delicious-food-composition_23-2149141353.jpg?w=1380",
    "https://img.freepik.com/free-photo/fruit-salad-spilling-floor-was-vibrant-tasty-generative-ai_188544-12370.jpg?w=1380",
    "https://img.freepik.com/free-photo/high-angle-arrangement-with-veggies-paper-bag_23-2148853335.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    controller.typeOfBusiness = BusinessType.Grocery.name;
    // Grocery is a walk-in / self-pickup vertical: a 300km list is padded with
    // shops nobody is going to visit. 50km is the reach this screen searches;
    // every other store screen keeps the app-wide default. Restored in
    // [dispose] — [StoreController] is shared.
    controller.searchRadiusKm = kmRadius50;

    // A category named by the caller wins over everything: the user has just
    // tapped it, so it outranks both the default and whatever they last looked
    // at. Resolved against the API's own list so the tab and the filter are the
    // same object the header renders.
    final requested = _requestedCategory();
    if (requested != null) {
      controller.selectedGroceryCategoryData.value = requested;
      controller.businessCategoryId = requested.tagId;
    } else {
      // Default landing tab is "All Grocery" (no category filter → every
      // grocery store). Preserve an already-chosen specific category on
      // re-entry, but treat null / the All-Grocery sentinel as "show all".
      final selected = controller.selectedGroceryCategoryData.value;
      if (selected != null && selected.tagId != _allGroceryTagId) {
        controller.businessCategoryId = selected.tagId;
      } else {
        controller.selectedGroceryCategoryData.value = _allGroceryCategory;
        controller.businessCategoryId = null;
      }
    }

    // Re-entry no longer refetches: only hits the API when the cached list is
    // missing or stale for this type/category. Category taps below are also
    // cache-aware; pull-to-refresh is the explicit force-fresh path.
    controller.getAllStoreNearByIfNeeded();
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    _shimmerController?.dispose();
    _shimmerController = null;
    // Hand the shared controller back on its app-wide default radius.
    controller.searchRadiusKm = kmRadius300;
    deleteIfRegistered<GroceryController>();
    deleteIfRegistered<GrocerySelfPickupConsumerController>();
    super.dispose();
  }

  /// The caller's requested category, resolved against the API list, or null
  /// when none was asked for or the tag isn't one this account's categories
  /// carry — an unknown tag falls through to the normal landing behaviour
  /// rather than selecting a tab that isn't in the header.
  CategoryData? _requestedCategory() {
    final tagId = widget.initialCategoryTagId;
    if (tagId == null || tagId.isEmpty) return null;
    for (final category in _arrCategories) {
      if (category.tagId == tagId) return category;
    }
    return null;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
    return false;
  }

  void showCartWarning() {
    final bool isCartEmpty =
        groceryCustomerController.selectedGroceriesVariants.isEmpty;

    if (isCartEmpty) {
      Get.back();
    } else {
      showCartWarningDialog(
        onPlaceOrder: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GrocerySelfPickUpCartScreen(),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        showCartWarning();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: Stack(
            children: [
              NestedScrollView(
                controller: _nestedScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: BannerCarousel(
                      images: _bannerImages,
                      onBack: () => showCartWarning(),
                      statusBarHeight: statusBarHeight,
                      backgroundColor:
                          AppColors.blue5CAF.withValues(alpha: 0.1),
                      bottomBorderSide: const BorderSide(
                        color: AppColors.white,
                        width: 2,
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyCategoryHeaderDelegate(
                      topPadding: statusBarHeight,
                      categories: [
                        // Leading "All Grocery" tab — shows every grocery store
                        // across all categories (no category filter).
                        StickyCategory(
                          id: _allGroceryTagId,
                          name: 'All Grocery',
                        ),
                        ..._arrCategories.map((c) {
                          return StickyCategory(
                            id: c.tagId ?? '',
                            name: c.name ?? '',
                            // The API's own artwork. This used to prefer a
                            // bundled tag→asset table, so a category added or
                            // re-illustrated server-side kept the old picture
                            // — or showed none, its tag not being in the table.
                            imageUrl: c.imageUrl,
                          );
                        }),
                      ],
                      // The header's search bar was painted but inert here.
                      // It now opens the store search for THIS vertical —
                      // scoped server-side to grocery shops, so nothing from
                      // another module can turn up in the results. The
                      // selected tab is passed for the placeholder only; the
                      // search API has no sub-category filter.
                      onSearchTap: () => Get.to(() => StoreSearchScreen(
                            config: StoreSearchConfig.grocery(
                              categoryLabel: controller
                                  .selectedGroceryCategoryData.value?.name,
                            ),
                          )),
                      selectedId: controller.selectedGroceryCategoryData.value?.tagId,
                      onCategoryTap: (item) {
                        if (item.id == _allGroceryTagId) {
                          // "Show all" — clear the category filter.
                          controller.selectedGroceryCategoryData.value =
                              _allGroceryCategory;
                          controller.businessCategoryId = null;
                        } else {
                          final cat = _arrCategories
                              .firstWhere((c) => c.tagId == item.id);
                          controller.selectedGroceryCategoryData.value = cat;
                          controller.businessCategoryId = cat.tagId;
                        }
                        // Cache-aware: re-tapping a category you viewed recently
                        // serves it instantly from its own cache entry instead
                        // of re-hitting the API. Pull-to-refresh forces fresh.
                        controller.getAllStoreNearByIfNeeded();
                        setState(() {});
                      },
                      onBack: () => showCartWarning(),
                      expandedLabelColor: AppColors.white,
                      backgroundGradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.blue5CAF.withValues(alpha: 0.1),
                          AppColors.blue5CAF.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
                body: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: _storeListContent(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: CustomerGrocerySelfPickupCart(
                    controller: groceryCustomerController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Store list content ───────────────────────────────────────────────

  Widget _storeListContent() {
    return Obx(() {
      final _ = _locationVersion;

      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return _buildSkeletonLoading();
      }

      if (controller.allStore.isEmpty) {
        return Center(
            child:
                EmptyStateWidget(message: AppStrings.groceryNoStoresFound));
      }

      // Ordered copy — see [sortStores]. Built inside the Obx so it re-runs
      // when a page lands AND when the counts call answers (the products sort
      // reads `storeCounts`, which is observable).
      final stores = sortStores(controller.allStore, _sort);

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: ValueKey(controller.businessCategoryId),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Padding(
            //   padding: EdgeInsets.only(
            //     left: SizeConfig.size12,
            //     right: SizeConfig.size12,
            //     bottom: SizeConfig.size6,
            //     top: SizeConfig.size6,
            //   ),
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(
            //         horizontal: 10, vertical: 6),
            //     decoration: BoxDecoration(
            //       color: AppColors.white,
            //       borderRadius: BorderRadius.circular(20),
            //       border:
            //           Border.all(color: AppColors.greyE5, width: 0.5),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Icon(Icons.storefront_rounded,
            //             size: 14, color: AppColors.primaryColor),
            //         const SizedBox(width: 6),
            //         CustomText(
            //           "${controller.allStore.length}${controller.isAllStoreLoadingMore.value ? '+' : ''} ${AppStrings.groceryStoresLabel}",
            //           fontSize: 11,
            //           fontWeight: FontWeight.w600,
            //           color: AppColors.mainTextColor,
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            StoreSortBar(
              sort: _sort,
              onChanged: (s) => setState(() => _sort = s),
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  // Interleave native ads between the store cards using the
                  // shared cadence (single source of truth in
                  // native_ad_list_inserter.dart), never after the last card.
                  final rows = buildNativeAdRows(stores.length);
                  final showLoadMore =
                      controller.isAllStoreLoadingMore.value;
                  return RefreshIndicator(
                    onRefresh: () => controller.getAllStoreNearBy(),
                    child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: rows.length + (showLoadMore ? 1 : 0),
                    padding: EdgeInsets.only(
                      left: SizeConfig.size12,
                      right: SizeConfig.size12,
                      // Breathing room under the sort chips; each card supplies
                      // the gap below itself.
                      top: SizeConfig.size4,
                      bottom: SizeConfig.paddingL + 70,
                    ),
                    // No promo row pinned at index 0: the ad rows interleaved
                    // by [buildNativeAdRows] already carry the Qureka card at
                    // the shared cadence, so a leading one made the list open
                    // on a promo AND show another one a few cards later.
                    itemBuilder: (context, index) {
                      if (index == rows.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.blue.shade300,
                              ),
                            ),
                          ),
                        );
                      }

                      final row = rows[index];
                      if (row.isAd) {
                        // Track the card height (minus the card's own size12
                        // bottom gap, which the ad re-adds itself), but never
                        // go below _kMinNativeAdHeight — the native layout needs
                        // room for the media view so the Meta native template
                        // renders without clipping.
                        final base = (_measuredCardHeight ?? 0) - SizeConfig.size12;
                        final adHeight =
                            base < _kMinNativeAdHeight ? _kMinNativeAdHeight : base;
                        // NativeAdSlot supplies the stable key (keyed on the
                        // ordinal) so the loaded ad survives list rebuilds
                        // (load-more, etc.) instead of reloading and burning
                        // impressions.
                        return PromoAdSlot(
                          adOrdinal: row.adOrdinal,
                          keyPrefix: 'grocery_native_ad',
                          height: adHeight,
                        );
                      }

                      final store = stores[row.contentIndex];

                      // The card carries its own gap underneath, so nothing to
                      // pass here — every card is self-contained and the ad
                      // slots below inherit the same rhythm.
                      final card = GroceryStoreCard(store: store);

                      // Measure the first card so ad slots can mirror its
                      // height. Only the first card is measured to avoid a
                      // measure callback on every row.
                      if (row.contentIndex == 0) {
                        return MeasureSize(
                          onChange: (size) {
                            if (!mounted) return;
                            if (_measuredCardHeight == size.height) return;
                            setState(() => _measuredCardHeight = size.height);
                          },
                          child: card,
                        );
                      }
                      return card;
                    },
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Skeleton loading
  Widget _buildSkeletonLoading() {
    final shimmer = _shimmerController;
    if (shimmer == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, child) {
        final double opacity = 0.4 + 0.6 * shimmer.value;
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      // Mirrors the real card — ringed avatar, name, two badges, stat pill and
      // the two trailing pills — including its gap, so the swap to real content
      // reads as a load finishing rather than a relayout.
      child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: SizeConfig.size4,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
          ),
          itemCount: 5,
          itemBuilder: (_, index) {
            return Container(
              margin: EdgeInsets.only(bottom: SizeConfig.size12),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size14,
                vertical: SizeConfig.size14,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDF1F5), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _shimmerBox(64, 64, radius: 32),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name, then the rating line, then the location line —
                        // the three rows the real card carries.
                        _shimmerBox(17, 170),
                        SizedBox(height: SizeConfig.size8),
                        _shimmerBox(13, 130),
                        SizedBox(height: SizeConfig.size8),
                        _shimmerBox(13, double.infinity),
                      ],
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  _shimmerBox(46, 62, radius: 10),
                ],
              ),
            );
          },
        ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 4}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  void showCartWarningDialog({required VoidCallback onPlaceOrder}) {
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
                AppStrings.groceryCartWarningMessage,
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
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyE5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        AppStrings.skip,
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
                        AppStrings.groceryPlaceOrderBtn,
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
}

