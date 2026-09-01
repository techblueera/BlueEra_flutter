import 'package:BlueEra/features/common/promo/qureka_promo_banner.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/me/food/view/customer/food_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/me/food/view/widget/restaurant_store_card.dart';
import 'package:BlueEra/features/common/store/widget/store_sort_bar.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/view/widget/customer_food_self_pickup_cart.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';

class RestaurantNearMeScreen extends StatefulWidget {
  const RestaurantNearMeScreen({super.key, this.initialCategoryTagId});

  /// Category tab to open on — an onboarding food `tagId`, e.g.
  /// [PURE_VEG_RESTAURANT].
  ///
  /// Set by callers that already know which category the user picked (the
  /// Discover folder sheet), so tapping "Pure - Veg Restaurant" there lands on
  /// that tab instead of on "All Food" with the choice thrown away. Null keeps
  /// the plain entry behaviour.
  final String? initialCategoryTagId;

  @override
  State<RestaurantNearMeScreen> createState() => _RestaurantNearMeScreenState();
}

class _RestaurantNearMeScreenState extends State<RestaurantNearMeScreen> {
  final storeController = getOrPut(() => StoreController());
  final AuthController _authController = Get.find<AuthController>();

  /// Sentinel tag id for the leading "All Food" tab. Selecting it clears the
  /// category filter, so the store API returns restaurants across every food
  /// category instead of one. Mirrors the All tab on the grocery screen.
  static const String _allFoodTagId = 'ALL_FOOD';
  static const String _allFoodLabel = 'All Food';

  /// Tag id of the selected category — null while "All Food" is active.
  /// Selection is tracked by id rather than list index because the All tab has
  /// no backing onboarding category to index into.
  String? _selectedCategoryTagId;

  /// Active sort chip. See [StoreSort] for why this is applied over the loaded
  /// list rather than sent to the API.
  StoreSort _sort = StoreSort.nearest;

  final FoodSelfPickupController foodCartController =
      getOrPut<FoodSelfPickupController>(() => FoodSelfPickupController());

  List<CategoryData> get _categories => _authController.businessOnboardingFoodsCategories;

  /// The category's artwork, straight from the categories API.
  ///
  /// This used to prefer a bundled tag→asset table over the API's own
  /// `imageUrl`, which meant a category added or re-illustrated server-side
  /// silently kept the old picture — or showed none at all, since a new tag
  /// isn't in the table.
  String _getCategoryIcon(CategoryData item) => item.imageUrl ?? '';

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/top-view-table-full-food_23-2149209253.jpg?w=1380",
    "https://img.freepik.com/free-photo/chicken-skewers-with-slices-sweet-peppers-dill_2829-18813.jpg?w=1380",
    "https://img.freepik.com/free-photo/flat-lay-batch-cooking-composition_23-2148765597.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    // Lands on "All Food" — no category filter, so every restaurant nearby is
    // listed — UNLESS the caller named a category, in which case that tab is
    // selected and the first fetch is already filtered to it. Anything else
    // would open the screen on a list the user has to re-filter by hand after
    // having just told us what they wanted.
    _selectedCategoryTagId = widget.initialCategoryTagId;
    _fetchStores(categoryId: _selectedCategoryTagId, ifNeeded: true);
  }

  /// [ifNeeded] = true (the default, used by both screen entry and category
  /// taps) skips the network call when the cached list for this type/category
  /// is still fresh. Pass false only to force a fresh fetch (pull-to-refresh).
  void _fetchStores({String? categoryId, bool ifNeeded = true}) {
    storeController.typeOfBusiness = BusinessType.Food.name;
    storeController.businessCategoryId = categoryId;
    // Food is a walk-in / self-pickup vertical: a 300km list is padded with
    // restaurants nobody is going to visit. 50km is the reach this screen
    // searches; every other store screen keeps the app-wide default. Restored
    // in [dispose] — [StoreController] is shared.
    storeController.searchRadiusKm = kmRadius50;
    if (ifNeeded) {
      storeController.getAllStoreNearByIfNeeded();
    } else {
      storeController.getAllStoreNearBy();
    }
  }

  @override
  void dispose() {
    deleteIfRegistered<FoodSelfPickupController>();
    // Hand the shared controller back on its app-wide default radius.
    storeController.searchRadiusKm = kmRadius300;
    super.dispose();
  }

  void _handleBackWithCartWarning() {
    final isCartEmpty = foodCartController.selectedFoodVariants.isEmpty;
    if (isCartEmpty) {
      Get.back();
      return;
    }
    _showCartWarningDialog(
      onPlaceOrder: () {
        Get.back();
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
                AppStrings.foodCartWarningMessage.tr,
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
                        AppStrings.foodSkipLabel.tr,
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
                        Get.to(() => const FoodSelfPickUpCartScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        AppStrings.foodPlaceOrderLabel.tr,
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

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      storeController.getAllStoreNearBy(isLoadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
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
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: Stack(
            children: [
              NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: BannerCarousel(
                      images: _bannerImages,
                      onBack: _handleBackWithCartWarning,
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
                      // The header paints a search bar; this is what it opens —
                      // the shared store search, scoped to this vertical by its
                      // StoreSearchConfig. Tapping a result opens that profile.
                      onSearchTap: () => Get.to(
                          () => StoreSearchScreen(config: StoreSearchConfig.food())),
                      categories: [
                        // Leading "All Food" tab — every restaurant, no
                        // category filter.
                        StickyCategory(
                          id: _allFoodTagId,
                          name: _allFoodLabel,
                        ),
                        ..._categories.map((c) => StickyCategory(
                              id: c.tagId ?? '',
                              name: c.name ?? '',
                              imageUrl: _getCategoryIcon(c),
                            )),
                      ],
                      selectedId: _selectedCategoryTagId ?? _allFoodTagId,
                      onCategoryTap: (item) {
                        if (item.id == _allFoodTagId) {
                          // "Show all" — clear the category filter.
                          _selectedCategoryTagId = null;
                          _fetchStores();
                        } else {
                          final idx = _categories
                              .indexWhere((c) => c.tagId == item.id);
                          if (idx >= 0) {
                            _selectedCategoryTagId = item.id;
                            _fetchStores(categoryId: item.id);
                          }
                        }
                        setState(() {});
                      },
                      onBack: _handleBackWithCartWarning,
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
                  child: _buildRestaurantList(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: CustomerFoodSelfPickupCart(controller: foodCartController),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Restaurant List ─────────────────────────────────────────────────

  Widget _buildRestaurantList() {
    return Obx(() {
      if (storeController.isAllStoreFirstLoading.value &&
          storeController.allStore.isEmpty) {
        return _buildShimmerList();
      }

      if (storeController.allStore.isEmpty) {
        return Center(
          child: EmptyStateWidget(message: AppStrings.foodNoRestaurantsNearby.tr),
        );
      }

      // Ordered copy — see [sortStores]. Built inside the Obx so it re-runs when
      // a page lands AND when the counts call answers (the products sort reads
      // `storeCounts`, which is observable).
      final stores = sortStores(storeController.allStore, _sort);
      final rows = buildNativeAdRows(stores.length);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoreSortBar(
            sort: _sort,
            onChanged: (s) => setState(() => _sort = s),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => storeController.getAllStoreNearBy(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: SizeConfig.size12,
                  right: SizeConfig.size12,
                  // Each card supplies the gap below itself.
                  top: SizeConfig.size4,
                  bottom: SizeConfig.paddingL + 70,
                ),
                itemCount: rows.length +
                    (storeController.isAllStoreLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == rows.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final row = rows[index];
                  if (row.isAd) {
                    // Qureka promo instead of a native ad on this screen — see
                    // kQurekaReplacesNativeAds for the switch back.
                    return PromoAdSlot(
                      adOrdinal: row.adOrdinal,
                      keyPrefix: 'restaurant_near_native_ad',
                    );
                  }
                  return RestaurantStoreCard(store: stores[row.contentIndex]);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── Shimmer Loading ─────────────────────────────────────────────────────

  /// Mirrors the real row — ringed avatar, name, rating line, location line and
  /// the trailing products box — so the swap to real content reads as a load
  /// finishing rather than a relayout. It used to preview a 160px cover photo
  /// and a stacked body that the card has not had since it became
  /// [RestaurantStoreCard].
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: SizeConfig.size12,
        right: SizeConfig.size12,
        bottom: SizeConfig.paddingL,
        top: SizeConfig.size4,
      ),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return buildLoadingShimmer(
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
    );
  }
}
