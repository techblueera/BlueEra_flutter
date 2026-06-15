import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/hmf_cart_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/hmf_consumer_controller.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_store_details_discover_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/hmf_profile_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_or_cooking_method.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/common/Discover/model/consumer_tiffin_response_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HmfCategoryDiscoverScreen extends StatefulWidget {
  const HmfCategoryDiscoverScreen({super.key});

  @override
  State<HmfCategoryDiscoverScreen> createState() => _HmfCategoryDiscoverScreenState();
}

class _HmfCategoryDiscoverScreenState extends State<HmfCategoryDiscoverScreen> {
  // Theme accents for this flow (aligned with the app primary).
  static const Color _primary = AppColors.primaryColor; // 0xFF0086FF
  static const Color _primaryDeep = AppColors.blue5CAF; // 0xFF005CAF

  final controller = getOrPut(() => HmfConsumerController());

  // Shared cart for the whole home made food flow — the floating bar here
  // observes the same instance the store details screen adds to.
  final cartController = getOrPut(() => HmfCartController());

  // `name` is the stable English id (used for sticky-header matching and the
  // controller's category lookup); `labelKey` is the AppStrings key shown to
  // the user, resolved with `.tr` at render time.
  static final List<_FoodCategory> _categories = [
    _FoodCategory('Tiffin', AppStrings.tiffinCategory, AppIconAssets.morningLunchIcon),
    _FoodCategory('Bakery', AppStrings.bakeryCategory, AppIconAssets.bakeryIcon),
    _FoodCategory('Sweets', AppStrings.sweetsCategory, AppIconAssets.sweetsIcon),
    _FoodCategory('Namkeen', AppStrings.namkeenCategory, AppIconAssets.namkeenIcon),
    _FoodCategory('Pickles', AppStrings.picklesCategory, AppIconAssets.picklesIcon),
  ];

  final List<String> _tiffinFilterTabs = [
    AppStrings.breakFast.tr,
    AppStrings.morningTiffinLunch.tr,
    AppStrings.eveningTiffinDinner.tr,
  ];

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/top-view-indian-food-arrangement_23-2148723455.jpg?w=1380",
    "https://img.freepik.com/free-photo/high-angle-pakistani-meal-composition_23-2148825105.jpg?w=1380",
    "https://img.freepik.com/free-photo/delicious-indian-dosa-composition_23-2149086052.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    controller.fetchAllTiffins();
  }

  @override
  void dispose() {
    deleteIfRegistered<HmfConsumerController>();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      if (controller.selectedCategoryIndex.value == 0) {
        controller.onTiffinScrollEnd();
      } else {
        controller.onHomeFoodScrollEnd();
      }
    }
    return false;
  }

  // Guard back navigation while the cart has items — same flow as the store
  // list screen: confirm leaving (which clears the cart) or jump to the cart.
  void _handleBack() {
    if (cartController.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _showCartWarning();
  }

  void _showCartWarning() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_shopping_cart_rounded,
                  color: _primary, size: 56),
              const SizedBox(height: 16),
              CustomText(
                AppStrings.leaveWithoutOrdering.tr,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              CustomText(
                AppStrings.cartWillBeCleared.tr,
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
                        cartController.clear();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyE5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(AppStrings.leaveLabel.tr,
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.to(() => const HmfCartScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(AppStrings.viewCart.tr,
                          color: AppColors.white,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w800),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.blue5CAF.withValues(alpha: 0.1),
                          AppColors.blue5CAF.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: BannerCarousel(
                      images: _bannerImages,
                      onBack: _handleBack,
                      statusBarHeight: statusBarHeight,
                      backgroundColor: Colors.transparent,
                      bottomBorderSide: const BorderSide(
                        color: AppColors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    singleLineLabel: true,
                    categories: _categories.map((c) => StickyCategory(
                      id: c.name,
                      name: c.labelKey.tr,
                      imageUrl: c.icon,
                    )).toList(),
                    selectedId: _categories[controller.selectedCategoryIndex.value].name,
                    onCategoryTap: (item) {
                      final idx = _categories.indexWhere((c) => c.name == item.id);
                      if (idx >= 0) controller.onCategoryChanged(idx);
                      setState(() {});
                    },
                    onBack: _handleBack,
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
                child: _buildContent(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(child: _buildCartBar()),
            ),
            if (isIndividualUser())
              Positioned(
                right: 16,
                bottom: 0,
                child: SafeArea(
                  child: Obx(() {
                    final cartVisible = !cartController.isEmpty;
                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(bottom: cartVisible ? 84 : 16),
                      child: _buildPostFab(),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  // ── Floating cart bar ──
  // Reflects the shared cart (items are added on the store details screen,
  // which ADD here routes to). Tapping opens the same cart page.
  Widget _buildCartBar() {
    return Obx(() {
      // ignore: unused_local_variable
      final _ = cartController.quantities.length; // subscribe to changes
      if (cartController.isEmpty) return const SizedBox.shrink();
      final count = cartController.totalItems;
      final stores = cartController.storeCount;
      return Center(
        child: FloatingCartWidget(
          itemCount: count,
          displayImages: cartController.previewImages,
          cartLabel: stores > 1 ? AppStrings.viewCarts.tr : AppStrings.viewCart.tr,
          itemLabel: stores > 1
              ? '$stores ${AppStrings.kitchensLabel.tr}  •  $count ${count == 1 ? AppStrings.itemLabel.tr : AppStrings.itemsLabel.tr}'
              : '$count ${count == 1 ? AppStrings.itemLabel.tr : AppStrings.itemsLabel.tr}  •  ${AppConstants.rupeeSymbol}${cartController.totalPrice.toStringAsFixed(0)}',
          onTap: () => Get.to(() => const HmfCartScreen()),
        ),
      );
    });
  }

  // Open the store details. Keyed off the store owner [userId] — the backend
  // resolves the store (home-foods + tiffins) by userId.
  void _openStore(String? userId) {
    if (userId == null || userId.isEmpty) {
      commonSnackBar(message: AppStrings.storeDetailsNotAvailable.tr);
      return;
    }
    Get.to(() => HmfStoreDetailsDiscoverScreen(userId: userId));
  }

  // ── Right Content ──
  Widget _buildContent() {
    return Obx(() {
      final catIndex = controller.selectedCategoryIndex.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (catIndex == 0) _buildFilterTabs(),
          Expanded(child: _buildContentList(catIndex)),
        ],
      );
    });
  }

  // ── Post FAB ──
  void _onPostTap() {
    if (isGuestUser() || isBusinessUser()) return;
    final viewProfileController =
        getOrPut(() => ViewPersonalDetailsController());
    if (viewProfileController.earnProfileType.contains('homeMadeFood')) {
      Get.to(() => const EarnServiceDashboardView(earnType: 'homeMadeFood'));
    } else {
      Get.to(() => const HomeMadeFoodProfileScreen());
    }
  }

  /// Floating "Post Food" action — a gradient extended FAB pill.
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
                AppStrings.postFood.tr,
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

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Obx(() => HorizontalTabSelector<String>(
            tabs: _tiffinFilterTabs,
            selectedIndex: controller.selectedFilterIndex.value,
            labelBuilder: (tab) => tab,
            horizontalPadding: 16,
            verticalPadding: 7,
            horizontalMargin: 8,
            verticalMargin: 0,
            unSelectedBackgroundColor: AppColors.white,
            unSelectedBorderColor: AppColors.greyE5,
            onTabSelected: (index, _) =>
                controller.onTiffinFilterChanged(index),
          )),
    );
  }

  Widget _buildContentList(int catIndex) {
    return Obx(() {
      if (catIndex == 0) {
        if (controller.isTiffinFirstLoading.value) {
          return _loader();
        }
        if (controller.tiffinList.isEmpty) {
          return _emptyState(AppStrings.noTiffinItemsFound.tr);
        }
        return _buildTiffinList();
      } else {
        if (controller.isHomeFoodFirstLoading.value) {
          return _loader();
        }
        if (controller.homeFoodList.isEmpty) {
          return _emptyState(AppStrings.noItemsFoundHere.tr);
        }
        return _buildFoodList();
      }
    });
  }

  Widget _loader() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.6,
        valueColor: AlwaysStoppedAnimation<Color>(_primary),
      ),
    );
  }

  Widget _listFooterLoader() {
    return const Padding(
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
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size20),
      child: EmptyStateWidget(message: message),
    );
  }

  // ── Tiffin List ──
  Widget _buildTiffinList() {
    return Obx(() {
      final items = controller.tiffinList;
      final showLoader = controller.isTiffinLoadingMore.value;

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: items.length + (showLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _listFooterLoader();
          }
          return _buildTiffinCard(items[index]);
        },
      );
    });
  }

  Widget _buildTiffinCard(ConsumerTiffinItem meal) {
    final discount = calculateDiscount(meal.sellingPrice, meal.mrpPrice);
    return _storeFoodCard(
      onTap: () => _openStore(meal.userId),
      imageUrl: meal.imageUrl,
      foodType: meal.foodType,
      name: meal.tiffinName,
      sellingPrice: meal.sellingPrice,
      mrpPrice: meal.mrpPrice,
      discount: '$discount'.startsWith('0') ? '' : '$discount${AppStrings.percentOff.tr}',
      cookingMethod: meal.cookingMethod,
      startTime: meal.startTime,
      endTime: meal.endTime,
      storeName: meal.storeName,
      storeLogo: meal.storeLogo,
      address: meal.address,
      lat: meal.lat ?? meal.storeLat,
      lng: meal.lng ?? meal.storeLng,
    );
  }

  // ── Food List (Bakery, Sweets, Namkeen, Pickles) ──
  Widget _buildFoodList() {
    return Obx(() {
      final items = controller.homeFoodList;
      final showLoader = controller.isHomeFoodLoadingMore.value;

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: items.length + (showLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _listFooterLoader();
          }
          return _buildFoodCard(items[index]);
        },
      );
    });
  }

  Widget _buildFoodCard(FoodItemModel item) {
    final kitchen = item.earnProfile;
    return _storeFoodCard(
      onTap: () => _openStore(item.userId),
      imageUrl: item.imageUrl,
      foodType: item.foodType,
      name: item.foodName,
      sellingPrice: item.sellingPrice,
      mrpPrice: item.mrpPrice,
      discount: item.discount,
      cookingMethod: item.cookingMethod,
      storeName: kitchen?.serviceName ?? '',
      storeLogo: kitchen?.serviceLogo,
      address: kitchen?.address ?? '',
      lat: item.lat ?? kitchen?.latitude,
      lng: item.lng ?? kitchen?.longitude,
    );
  }

  /// Shared "tap-to-open-store" card for both tiffin and home-made-food
  /// listings. The whole card is tappable — items are chosen inside the store
  /// detail screen — so there is no in-list ADD button. Layout: details on the
  /// left, a clean food image on the right.
  Widget _storeFoodCard({
    required VoidCallback onTap,
    String? imageUrl,
    String foodType = '',
    required String name,
    String sellingPrice = '',
    String mrpPrice = '',
    String discount = '',
    String cookingMethod = '',
    String? startTime,
    String? endTime,
    String storeName = '',
    String? storeLogo,
    String address = '',
    double? lat,
    double? lng,
  }) {
    final hasTime =
        (startTime?.isNotEmpty ?? false) && (endTime?.isNotEmpty ?? false);
    final showDiscount = discount.isNotEmpty && !discount.startsWith('0');

    return _foodCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: image (left) + details (right) — white ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _foodImage(imageUrl, foodType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      name,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.mainTextColor,
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12, color: AppColors.greyAF),
                          const SizedBox(width: 2),
                          Expanded(
                            child: CustomText(
                              address,
                              fontSize: 11.5,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (cookingMethod.isNotEmpty || hasTime) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (cookingMethod.isNotEmpty)
                            FoodTypeOrCookingMethod(
                              label: cookingMethod,
                              icon: AppIconAssets.boiled,
                            ),
                          if (hasTime)
                            FoodTypeOrCookingMethod(
                              label: '$startTime - $endTime',
                              icon: AppIconAssets.storeWatch,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        CustomText(
                          '${AppConstants.rupeeSymbol}$sellingPrice',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                        ),
                        if (mrpPrice.isNotEmpty)
                          CustomText(
                            '${AppConstants.rupeeSymbol}$mrpPrice',
                            fontSize: 11.5,
                            color: AppColors.secondaryTextColor,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.secondaryTextColor,
                          ),
                        if (showDiscount) DiscountBadge(discountText: discount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
          // ── Footer band (lighter grey, full width) ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              border: Border(
                top: BorderSide(
                    color: AppColors.greyE5.withValues(alpha: 0.8)),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: _cardFooter(
              onTap: onTap,
              storeName: storeName,
              storeLogo: storeLogo,
              lat: lat,
              lng: lng,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer row: avatar + name + distance on the left, a chat icon and a
  //    "View Profile" button on the right. ──
  Widget _cardFooter({
    required VoidCallback onTap,
    required String storeName,
    String? storeLogo,
    double? lat,
    double? lng,
  }) {
    return Row(
      children: [
        _kitchenAvatar(storeLogo, size: 34),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                storeName.isNotEmpty ? storeName : AppStrings.kitchenLabel.tr,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              _distanceLine(lat, lng),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _chatButton(onTap),
        const SizedBox(width: 8),
        _viewProfileButton(onTap),
      ],
    );
  }

  /// "X km Away" when we have coordinates + the user's location, else nothing
  /// (the address is shown under the title).
  Widget _distanceLine(double? lat, double? lng) {
    final hasLoc = lat != null && lng != null && !(lat == 0.0 && lng == 0.0);
    if (!hasLoc) return const SizedBox.shrink();
    final km = calculateDistanceKm(
        LocationService.lat, LocationService.lng, lat, lng);
    return Row(
      children: [
        const Icon(Icons.location_on_rounded, size: 13, color: _primary),
        const SizedBox(width: 3),
        Flexible(
          child: CustomText(
            '${km.toStringAsFixed(1)} ${AppStrings.kmAwayLower.tr}',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Chat button — local `chat` asset on a white, 8-radius box with a light
  /// grey icon tint.
  Widget _chatButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5),
          ),
          child: LocalAssets(
            imagePath: AppIconAssets.chat,
            height: 18,
            width: 18,
            boxFix: BoxFit.contain,
            imgColor: AppColors.greyAF,
          ),
        ),
      ),
    );
  }

  Widget _viewProfileButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomText(
            AppStrings.viewProfile.tr,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  /// Square food image on the LEFT of the card, with the veg/non-veg marker
  /// overlaid on the top-left corner (matches the reference design).
  Widget _foodImage(String? imageUrl, String foodType) {
    const double size = 96;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: AppColors.greyE5.withValues(alpha: 0.5)),
                    errorWidget: (_, __, ___) => _placeholderIcon(),
                  )
                : _placeholderIcon(),
            if (foodType.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _vegMarker(_vegColor(foodType), size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Shared building blocks ──

  /// Elevated white card; the whole surface is tappable and opens the store
  /// (items are chosen inside the store detail screen, not from this list).
  Widget _foodCardShell({required Widget child, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyE5.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // Padding is applied per-section now (top is white, the footer is a
          // full-width lighter-grey band), so the shell adds none itself.
          child: child,
        ),
      ),
    );
  }

  /// Circular store logo; falls back to a tinted storefront badge when
  /// there's no logo (or it fails to load).
  Widget _kitchenAvatar(String? logoUrl, {double size = 26}) {
    Widget badge() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.storefront_rounded, size: size * 0.55, color: _primary),
        );

    if (logoUrl == null || logoUrl.isEmpty) return badge();

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(color: _primary.withValues(alpha: 0.10)),
          errorWidget: (_, __, ___) => badge(),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        ),
      ),
      child: Icon(Icons.restaurant_rounded,
          size: 32, color: Colors.orange.shade300),
    );
  }

  Color _vegColor(String foodType) =>
      foodType.toLowerCase().contains('non')
          ? const Color(0xFFC0341D)
          : const Color(0xFF1E7D34);

  /// Bare FSSAI-style square marker (border + centered dot).
  Widget _vegMarker(Color color, {double size = 14}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: size * 0.42,
          height: size * 0.42,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

}

class _FoodCategory {
  final String name;
  final String labelKey;
  final String icon;
  const _FoodCategory(this.name, this.labelKey, this.icon);
}
