import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/me/food/view/customer/food_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_chat_icon.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/view/widget/customer_food_self_pickup_cart.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';

class _RestaurantCardPalette {
  final Color cardBg;
  final Color cardBorder;
  final Color tileBg;
  final Color tileBorder;
  final Color dividerLine;

  const _RestaurantCardPalette({
    required this.cardBg,
    required this.cardBorder,
    required this.tileBg,
    required this.tileBorder,
    required this.dividerLine,
  });
}

const _restaurantPalettes = <_RestaurantCardPalette>[
  _RestaurantCardPalette(
    cardBg: Color(0xFFEDFDFF),
    cardBorder: Color(0xFFC0DDE1),
    // CSS #13DBF414 (RGBA) → Flutter ARGB 0x1413DBF4 — translucent
    // teal wash so the card's footer tints with the card's identity.
    tileBg: Color(0x1413DBF4),
    tileBorder: Color(0xFFD0EEF2),
    dividerLine: Color(0xFFBBE3E8),
  ),
  _RestaurantCardPalette(
    cardBg: Color(0xFFFCF5FF),
    cardBorder: Color(0xFFECD3F6),
    // CSS #BE26FF14 (RGBA) → Flutter ARGB 0x14BE26FF — same low-alpha
    // tint, violet to match the second card's outer shell.
    tileBg: Color(0x14BE26FF),
    tileBorder: Color(0xFFF7E3FF),
    dividerLine: Color(0xFFE3D4E9),
  ),
];

class RestaurantNearMeScreen extends StatefulWidget {
  const RestaurantNearMeScreen({super.key});

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

  final FoodSelfPickupController foodCartController =
      getOrPut<FoodSelfPickupController>(() => FoodSelfPickupController());

  List<CategoryData> get _categories => _authController.businessOnboardingFoodsCategories;

  static final Map<String, String> _foodCategoryIcons = {
    MULTI_CUISINE_RESTAURANT: OnboardingBusinessAssets.multicuisineRestaurant,
    PURE_VEG_RESTAURANT: OnboardingBusinessAssets.pureVegRestaurant,
    COFFEE_BEVERAGES_SHOP: OnboardingBusinessAssets.coffeeBeveragesShop,
    ECONOMY_DHABA: OnboardingBusinessAssets.economyDhaba,
    SWEET_NAMKEEN_SHOP: OnboardingBusinessAssets.sweetNamkeenShop,
    BREAKFAST_FAST_FOOD: OnboardingBusinessAssets.breakfastFastFood,
    GARDEN_BUFFET_RESTAURANT: OnboardingBusinessAssets.gardenBuffetRestaurant,
    CLOUD_KITCHEN_MESS: OnboardingBusinessAssets.cloudKitchenMess,
    NON_VEG_RESTAURANT: OnboardingBusinessAssets.nonVegRestaurant,
    ICE_CREAM_CORNER: OnboardingBusinessAssets.iceCreamCorner,
  };

  String _getCategoryIcon(CategoryData item) {
    return _foodCategoryIcons[item.tagId] ?? item.imageUrl ?? '';
  }

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/top-view-table-full-food_23-2149209253.jpg?w=1380",
    "https://img.freepik.com/free-photo/chicken-skewers-with-slices-sweet-peppers-dill_2829-18813.jpg?w=1380",
    "https://img.freepik.com/free-photo/flat-lay-batch-cooking-composition_23-2148765597.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    // Lands on "All Food": no category filter, so every restaurant nearby is
    // listed. (It used to land on the first onboarding category.)
    _fetchStores(ifNeeded: true);
  }

  /// [ifNeeded] = true (the default, used by both screen entry and category
  /// taps) skips the network call when the cached list for this type/category
  /// is still fresh. Pass false only to force a fresh fetch (pull-to-refresh).
  void _fetchStores({String? categoryId, bool ifNeeded = true}) {
    storeController.typeOfBusiness = AppConstants.food;
    storeController.businessCategoryId = categoryId;
    if (ifNeeded) {
      storeController.getAllStoreNearByIfNeeded();
    } else {
      storeController.getAllStoreNearBy();
    }
  }

  @override
  void dispose() {
    deleteIfRegistered<FoodSelfPickupController>();
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
                        ..._categories.map((c) {
                          debugPrint(
                              'FoodCategory tagId=${c.tagId} name=${c.name}');
                          return StickyCategory(
                            id: c.tagId ?? '',
                            name: c.name ?? '',
                            imageUrl: _getCategoryIcon(c),
                          );
                        }),
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

      final rows = buildNativeAdRows(storeController.allStore.length);
      return RefreshIndicator(
        onRefresh: () => storeController.getAllStoreNearBy(),
        child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size12,
          bottom: SizeConfig.paddingL + 70,
        ),
        itemCount:
            rows.length + (storeController.isAllStoreLoadingMore.value ? 1 : 0),
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
            return NativeAdSlot(
              adOrdinal: row.adOrdinal,
              keyPrefix: 'restaurant_near_native_ad',
            );
          }
          return _buildRestaurantCard(
              storeController.allStore[row.contentIndex], row.contentIndex);
        },
      ),
      );
    });
  }

  // ── Shimmer Loading ─────────────────────────────────────────────────────

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: SizeConfig.size12,
        right: SizeConfig.size12,
        bottom: SizeConfig.paddingL,
        top: SizeConfig.size8,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return buildLoadingShimmer(
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shimmerContainer(height: 160, radius: 0),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      shimmerContainer(width: 36, height: 36, radius: 18),
                      const SizedBox(width: 10),
                      Expanded(child: shimmerContainer(height: 14, radius: 4)),
                      const SizedBox(width: 40),
                      shimmerContainer(width: 44, height: 22, radius: 5),
                    ],
                  ),
                  const SizedBox(height: 12),
                  shimmerContainer(width: 140, height: 10, radius: 4),
                  const SizedBox(height: 12),
                  shimmerContainer(height: 32, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  bool _isVeg(String subCategoryName) {
    final name = subCategoryName.toLowerCase();
    return !name.contains('non') &&
        !name.contains('meat') &&
        !name.contains('chicken') &&
        !name.contains('fish');
  }

  Widget _buildVegNonVegIcon(bool isVeg, {double size = 16}) {
    final color = isVeg ? Colors.green : Colors.red;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDottedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }

  /// Card palette is now index-based so cards alternate (palette 0 →
  /// palette 1 → palette 0 …) instead of being picked by a hash of
  /// `store.id`, which produced unpredictable runs of the same palette.
  _RestaurantCardPalette _paletteFor(int index) {
    return _restaurantPalettes[index.abs() % _restaurantPalettes.length];
  }

  String _formatCount(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K';
    }
    return '$n';
  }

  // ── Restaurant Card ─────────────────────────────────────────────────────

  Widget _buildRestaurantCard(GetAllStoreResModel store, int index) {
    final livePhotos = (store.livePhotos ?? const <String>[])
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final logo = store.logo ?? '';
    final hasLogo = logo.isNotEmpty;
    final heroImage =
        livePhotos.isNotEmpty ? livePhotos.first : (hasLogo ? logo : '');
    final extraPhotos = livePhotos.length > 1 ? livePhotos.length - 1 : 0;
    final palette = _paletteFor(index);

    return InkWell(
      onTap: () => _navigateToDetail(store),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: palette.cardBg,
          border: Border.all(color: palette.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(store),
                  SizedBox(height: SizeConfig.size10),
                  _buildDottedLine(palette.dividerLine),
                  SizedBox(height: SizeConfig.size10),
                  _buildBodyRow(
                    store: store,
                    heroImage: heroImage,
                    livePhotos: livePhotos,
                    extraPhotos: extraPhotos,
                    palette: palette,
                  ),
                ],
              ),
            ),
            _buildLastVisitFooter(store, palette),
          ],
        ),
      ),
    );
  }

  // ── Header: avatar + name + rating/veg-or-nonveg badges + chat icon ──
  Widget _buildHeader(GetAllStoreResModel store) {
    final ratingValue = (store.avgRating ?? 0) > 0
        ? store.avgRating.toString()
        : AppStrings.no.tr;
    final subCategoryName = store.subCategoryOfBusiness?.name ??
        AppStrings.foodVegRestaurantLabel.tr;
    final isVeg = _isVeg(subCategoryName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedAvatarWidget(
          imageUrl: store.logo ?? '',
          size: SizeConfig.size50,
          borderColor: Colors.white,
          borderRadius: SizeConfig.size25,
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                store.businessName ?? AppStrings.restaurant.tr,
                fontSize: SizeConfig.large18,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w800,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildRatingBadge(ratingValue),
                  _buildVegBadge(isVeg, subCategoryName),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        // DiscoverChatIcon(
        //   userId: store.userId ?? '',
        //   name: store.businessName,
        //   profile: store.logo,
        //   businessId: store.id,
        //   trackingSource: ChatClickSource.searchResult,
        // ),
      ],
    );
  }

  Widget _buildVegBadge(bool isVeg, String text) {
    final fg = isVeg ? Colors.green.shade700 : Colors.red.shade700;
    final bg = (isVeg ? Colors.green : Colors.red).withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVegNonVegIcon(isVeg, size: 10),
          const SizedBox(width: 6),
          Flexible(
            child: CustomText(
              text,
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body: 2 stat cards + address card on the left, hero image right ──
  Widget _buildBodyRow({
    required GetAllStoreResModel store,
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
    required _RestaurantCardPalette palette,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatBox(
                        icon: AppIconAssets.staggeredIcon,
                        count: _formatCount(store.totalCategoryCount ??
                            (store.categories?.length ?? 0)),
                        label: AppStrings.foodCategoryLabel.tr,
                        iconColor: const Color(0xFF9964F4),
                        borderColor: palette.tileBorder,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      _buildStatBox(
                        icon: AppIconAssets.productCartIcon,
                        count: _formatCount(store.totalProductCount ?? 0),
                        label: AppStrings.foodProductLabel.tr,
                        iconColor: const Color(0xFF6179CD),
                        borderColor: palette.tileBorder,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Expanded(child: _buildAddressCard(store, palette)),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              flex: 3,
              child: _buildHeroImage(
                store: store,
                heroImage: heroImage,
                livePhotos: livePhotos,
                extraPhotos: extraPhotos,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
      GetAllStoreResModel store, _RestaurantCardPalette palette) {
    final lat = store.businessLocation?.lat?.toDouble() ?? 0.0;
    final lng = store.businessLocation?.lon?.toDouble() ?? 0.0;
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      lat,
      lng,
    );

    return GestureDetector(
      onTap: () => _showMapBottomSheet(store),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: palette.tileBorder, width: 1),
          color: AppColors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconContainer(AppIconAssets.location_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    '${km.toStringAsFixed(2)} Km Away',
                    fontSize: 12.0,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    store.address ?? AppStrings.na,
                    fontSize: 10.0,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapBottomSheet(GetAllStoreResModel store) {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.businessName ?? AppStrings.restaurant.tr,
      destinationAddress: store.address ?? '',
      destinationLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
      destinationLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
      livePhotos: store.livePhotos,
      visitCallback: ()=> _navigateToDetail(store)
    );
  }

  Widget _buildIconContainer(String iconPath) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 2.0,
          ),
        ],
      ),
      child: LocalAssets(
        imagePath: iconPath,
        imgColor: AppColors.secondaryTextColor,
        height: 24,
        width: 20,
      ),
    );
  }

  Widget _buildStatBox({
    required String icon,
    required String count,
    required String label,
    required Color iconColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: borderColor, width: 1),
          color: AppColors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: icon,
              imgColor: iconColor,
              height: 12,
              width: 12,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              count,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(width: SizeConfig.size6),
            Flexible(
              child: CustomText(
                label,
                fontSize: SizeConfig.extraSmall,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage({
    required GetAllStoreResModel store,
    required String heroImage,
    required List<String> livePhotos,
    required int extraPhotos,
  }) {
    final natureOfBusiness = store.categoryOfBusiness?.name ??
        store.natureOfBusiness ??
        'OTHER';
    final fullList = livePhotos.isNotEmpty
        ? livePhotos
        : (heroImage.isNotEmpty ? [heroImage] : <String>[]);

    return GestureDetector(
      onTap: fullList.isEmpty
          ? null
          : () => _showPhotoDialog(
                images: fullList,
                initialIndex: 0,
                title: natureOfBusiness,
              ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroImage.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: heroImage,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  memCacheHeight: 600,
                  placeholder: (_, __) => LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                  errorWidget: (_, __, ___) => LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                )
              else
                LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  boxFix: BoxFit.cover,
                ),
              if (extraPhotos > 0)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CustomText(
                      '+$extraPhotos',
                      fontSize: SizeConfig.small,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer: top-bordered banner with views + orders + quirky message ──
  Widget _buildLastVisitFooter(
      GetAllStoreResModel store, _RestaurantCardPalette palette) {
    final views = int.tryParse(store.views ?? '') ?? 0;
    final viewLabel = views == 1 ? 'view' : 'views';
    final countText = _formatCount(views);
    final clicks = store.chatClickCount ?? 0;
    final clickLabel = clicks == 1 ? 'order' : 'orders';
    final clickCountText = _formatCount(clicks);
    final quirky = (store.quirkyMessage ?? '').trim();
    return InkWell(
      onTap: () => _navigateToDetail(store),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12.0),
        bottomRight: Radius.circular(12.0),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size10, horizontal: SizeConfig.size12),
        decoration: BoxDecoration(
          color: palette.tileBg,
          border: Border(
            top: BorderSide(color: palette.cardBorder, width: 1),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.eye_view,
              height: SizeConfig.size12,
              width: SizeConfig.size12,
              imgColor: AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size8),
            Flexible(
              child: RichText(
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: countText,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' Total $viewLabel on this store, '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size4),
                        child: LocalAssets(
                          imagePath: AppIconAssets.cartIcon,
                          height: SizeConfig.size12,
                          width: SizeConfig.size12,
                          imgColor: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: clickCountText,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' $clickLabel'),
                    if (quirky.isNotEmpty) TextSpan(text: ', $quirky'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(String rating) {
    const goldFg = Color(0xFFB8860B);
    const goldBg = Color(0xFFFFF3D1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, goldBg],
        ),
        border: Border.all(
          color: goldFg.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: goldFg.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(
            rating,
            fontSize: 11,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog({
    required List<String> images,
    required int initialIndex,
    required String title,
  }) {
    if (images.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => _RestaurantPhotoDialog(
        images: images,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }

  /// Routed through [openVisitProfile] so the type→screen mapping stays in one
  /// place. The food store screen hydrates from the business id alone, so
  /// there's nothing to hand over beyond it.
  void _navigateToDetail(GetAllStoreResModel store) {
    if (store.id == null) return;
    openVisitProfile(
      accountType: AppConstants.business,
      typeOfBusiness: BusinessType.Food.name,
      businessId: store.id,
      userId: store.userId,
    );
  }

  // ignore: unused_element
  Widget _infoSection({
    required IconData icon,
    required String title,
    required int count,
    required List<String> pills,
    required String emptyLabel,
    required VoidCallback onTap,
  }) {
    final accent = AppColors.primaryColor;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            margin: EdgeInsets.only(
                top: 4, bottom: 4, right: SizeConfig.size10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent,
                  accent.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.08),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child:
                          Icon(icon, size: SizeConfig.size14, color: accent),
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      title,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '·',
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '$count',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                if (pills.isEmpty)
                  _sectionEmpty(emptyLabel)
                else
                  Wrap(
                    spacing: SizeConfig.size6,
                    runSpacing: SizeConfig.size6,
                    children: [
                      ...pills.take(4).map((l) => _gradientChip(l, onTap)),
                      if (pills.length > 4)
                        _overflowChip(pills.length - 4, onTap),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientChip(String label, VoidCallback onTap) {
    final accent = AppColors.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10, vertical: SizeConfig.size4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              accent.withValues(alpha: 0.09),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: CustomText(
          label,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
      ),
    );
  }

  Widget _overflowChip(int extra, VoidCallback onTap) {
    final accent = AppColors.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10, vertical: SizeConfig.size4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.32),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              '+$extra more',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_forward_rounded, size: 11, color: accent),
          ],
        ),
      ),
    );
  }

  Widget _sectionEmpty(String label) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        color: AppColors.greyE5.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyE5, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 12, color: AppColors.grey9B),
          SizedBox(width: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 11,
            color: AppColors.grey9B,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

/// Premium photo lightbox shown as a bordered, rounded dialog (not
/// full-page). Inside: a faint primary halo radial backdrop, a clean
/// header with a title pill + counter + circular close, an
/// `InteractiveViewer` PageView with double-tap-to-zoom, and an
/// animated dot indicator below — the active dot stretches into a
/// pill in the primary color.
class _RestaurantPhotoDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const _RestaurantPhotoDialog({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_RestaurantPhotoDialog> createState() => _RestaurantPhotoDialogState();
}

class _RestaurantPhotoDialogState extends State<_RestaurantPhotoDialog>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  late final AnimationController _entry;
  late int _index;
  final Map<int, TransformationController> _transformers = {};
  TapDownDetails? _lastDoubleTap;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  TransformationController _transformerFor(int i) =>
      _transformers.putIfAbsent(i, TransformationController.new);

  @override
  void dispose() {
    _controller.dispose();
    _entry.dispose();
    for (final t in _transformers.values) {
      t.dispose();
    }
    super.dispose();
  }

  void _toggleZoom(int i) {
    final t = _transformerFor(i);
    final details = _lastDoubleTap;
    if (t.value != Matrix4.identity()) {
      t.value = Matrix4.identity();
    } else if (details != null) {
      const scale = 2.5;
      final pos = details.localPosition;
      t.value = Matrix4.identity()
        ..translate(-pos.dx * (scale - 1), -pos.dy * (scale - 1))
        ..scale(scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AnimatedBuilder(
        animation: _entry,
        builder: (_, __) => Opacity(
          opacity: _entry.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: size.width,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.96),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.32),
                                  width: 0.5,
                                ),
                              ),
                              child: CustomText(
                                widget.title,
                                fontSize: SizeConfig.small,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 0.5,
                            ),
                          ),
                          child: CustomText(
                            '${_index + 1} / ${widget.images.length}',
                            fontSize: SizeConfig.small,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.5,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.images.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) {
                        return GestureDetector(
                          onDoubleTapDown: (d) => _lastDoubleTap = d,
                          onDoubleTap: () => _toggleZoom(i),
                          child: Hero(
                            tag: 'photo_${widget.images[i]}_$i',
                            child: InteractiveViewer(
                              transformationController:
                                  _transformerFor(i),
                              minScale: 1,
                              maxScale: 5,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.images[i],
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => Container(
                                        color: Colors.white
                                            .withValues(alpha: 0.04),
                                        child: Center(
                                          child: SizedBox(
                                            width: 26,
                                            height: 26,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(Colors.white
                                                          .withValues(
                                                              alpha:
                                                                  0.55)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          LocalAssets(
                                        imagePath: AppIconAssets
                                            .place_holder_image,
                                        boxFix: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.images.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primaryColor
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: 0.55),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
