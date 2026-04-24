import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/food/view/food_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/me/food/view/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_address_pill.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/view/widget/food_self_pickup_cart.dart';
import 'package:BlueEra/widgets/RatingBadge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RestaurantNearMeScreen extends StatefulWidget {
  const RestaurantNearMeScreen({super.key});

  @override
  State<RestaurantNearMeScreen> createState() => _RestaurantNearMeScreenState();
}

class _RestaurantNearMeScreenState extends State<RestaurantNearMeScreen> {
  final storeController = getOrPut(() => NewStoreController());
  final AuthController _authController = Get.find<AuthController>();
  final RxInt selectedCategoryIndex = 0.obs;

  final FoodSelfPickupController foodCartController =
      getOrPut<FoodSelfPickupController>(() => FoodSelfPickupController());

  List<CategoryData> get _categories => _authController.businessOnboardingFoodsCategories;

  static final Map<String, String> _foodCategoryIcons = {
    MULTI_CUISINE_RESTAURANTS: OnboardingBusinessAssets.multicuisineRestaurant,
    PURE_VEG_RESTAURANT: OnboardingBusinessAssets.pureVegRestaurant,
    COFFEE_BEVERAGES_SHOP: OnboardingBusinessAssets.coffeeBeveragesShop,
    ECONOMY_DHABA: OnboardingBusinessAssets.economyDhaba,
    SWEET_NAMKEEN_SHOP: OnboardingBusinessAssets.sweetNamkeenShop,
    BREAKFAST_FAST_FOOD: OnboardingBusinessAssets.breakfastFastFood,
    GARDEN_BUFFET_RESTAURANT: OnboardingBusinessAssets.gardenBuffetRestaurant,
    CLOUD_KITCHEN: OnboardingBusinessAssets.cloudKitchenMess,
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
    _fetchStores(categoryId: _categories.isNotEmpty ? _categories.first.tagId : null);
  }

  void _fetchStores({String? categoryId}) {
    storeController.typeOfBusiness = AppConstants.food;
    storeController.businessCategoryId = categoryId;
    storeController.getAllStoreNearBy();
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_rounded, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              CustomText(
                AppStrings.foodCartWarningMessage.tr,
                textAlign: TextAlign.center,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
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
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        AppStrings.foodSkipLabel.tr,
                        color: AppColors.secondaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomBtn(
                      title: AppStrings.foodPlaceOrderLabel.tr,
                      bgColor: AppColors.primaryColor,
                      onTap: () {
                        Get.back();
                        Get.to(()=> const FoodSelfPickUpCartScreen());
                      },
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
                      categories: _categories.map((c) => StickyCategory(
                        id: c.tagId ?? '',
                        name: c.name ?? '',
                        imageUrl: _getCategoryIcon(c),
                      )).toList(),
                      selectedId: _categories.isNotEmpty &&
                              selectedCategoryIndex.value < _categories.length
                          ? _categories[selectedCategoryIndex.value].tagId
                          : null,
                      onCategoryTap: (item) {
                        final idx = _categories.indexWhere((c) => c.tagId == item.id);
                        if (idx >= 0) {
                          selectedCategoryIndex.value = idx;
                          _fetchStores(categoryId: item.id);
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
                  child: FoodSelfPickupCart(controller: foodCartController),
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

      return ListView.builder(
        padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size12,
          bottom: SizeConfig.paddingL + 70,
        ),
        itemCount: storeController.allStore.length +
            (storeController.isAllStoreLoadingMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == storeController.allStore.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return _buildRestaurantCard(storeController.allStore[index]);
        },
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

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashSpace = 3.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.greyE5),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Restaurant Card ─────────────────────────────────────────────────────

  Widget _buildRestaurantCard(GetAllStoreResModel store) {
    final categoryName = store.categoryOfBusiness?.name ?? '';
    final subCategoryName =
        store.subCategoryOfBusiness?.name ?? AppStrings.foodVegRestaurantLabel.tr;
    final livePhotos = (store.livePhotos ?? [])
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final hasLivePhoto = livePhotos.isNotEmpty;
    final hasLogo = store.logo?.isNotEmpty ?? false;
    final totalOrders = store.views ?? '10k+';
    final isVeg = _isVeg(subCategoryName);
    final rating = (store.avgRating ?? 0) > 0 ? '${store.avgRating}' : '4.5';

    return GestureDetector(
      onTap: () => _navigateToDetail(store),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Image ──
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: hasLivePhoto
                      ? NetWorkOcToAssets(
                          imgUrl: livePhotos.first,
                          boxFit: BoxFit.cover,
                        )
                      : hasLogo
                          ? NetWorkOcToAssets(
                              imgUrl: store.logo!,
                              boxFit: BoxFit.cover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.fillColor,
                                    AppColors.greyE5,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(Icons.restaurant_menu,
                                    size: 48,
                                    color: AppColors.secondaryTextColor
                                        .withValues(alpha: 0.5)),
                              ),
                            ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        CustomText(
                          '$totalOrders ${AppStrings.foodOrdersLabel.tr}',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _buildVegNonVegIcon(isVeg, size: 14),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),
                if (livePhotos.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          CustomText(
                            '${livePhotos.length}',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info Section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.fillColor,
                          border:
                              Border.all(color: AppColors.greyE5, width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasLogo
                            ? NetWorkOcToAssets(
                                imgUrl: store.logo!,
                                boxFit: BoxFit.cover,
                              )
                            : Icon(Icons.store_rounded,
                                size: 18,
                                color: AppColors.secondaryTextColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              store.businessName ?? AppStrings.restaurant.tr,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                CustomText(
                                  subCategoryName,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondaryTextColor,
                                ),
                                if (categoryName.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor
                                            .withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: CustomText(
                                      categoryName,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.secondaryTextColor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      RatingBadge(rating: rating)
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDottedLine(),
                  const SizedBox(height: 10),
                  DiscoverAddressPill(
                    destLat: store.businessLocation?.lat?.toDouble() ?? 0.0,
                    destLng: store.businessLocation?.lon?.toDouble() ?? 0.0,
                    address: getLocalityAddress(store.address),
                    onTap: () => RouteMapBottomSheet.show(
                      context: context,
                      destinationName:
                          store.businessName ?? AppStrings.restaurant.tr,
                      destinationAddress: store.address ?? '',
                      destinationLat:
                          store.businessLocation?.lat?.toDouble() ?? 0.0,
                      destinationLng:
                          store.businessLocation?.lon?.toDouble() ?? 0.0,
                      livePhotos: store.livePhotos,
                      storeBusinessID: store.id ?? '',
                      storeUserID: store.userId ?? '',
                    ),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _infoSection(
                    icon: Icons.category_outlined,
                    title: AppStrings.foodCategoryLabel.tr,
                    count: store.totalCategoryCount ??
                        (store.categories?.length ?? 0),
                    pills: (store.categories ?? [])
                        .map((c) => c.name ?? '')
                        .where((s) => s.trim().isNotEmpty)
                        .toList(),
                    emptyLabel: 'No categories listed',
                    onTap: () => _navigateToDetail(store),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  _infoSection(
                    icon: Icons.shopping_bag_outlined,
                    title: AppStrings.foodProductLabel.tr,
                    count: store.totalProductCount ?? 0,
                    pills: const [],
                    emptyLabel:
                        '${store.totalProductCount ?? 0} products in store',
                    onTap: () => _navigateToDetail(store),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(GetAllStoreResModel store) {
    if (store.id == null) return;
    Get.to(() => VisitFoodStoreDetailsScreen(visitBusinessId: store.id!));
  }

  /// Section block — left accent rail, icon-in-disc header with inline
  /// count, and a wrap of soft-gradient pills below. Mirrors the hospital
  /// list / grocery store card layout for a consistent discover-card feel.
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
