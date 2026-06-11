import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
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

  static final List<_FoodCategory> _categories = [
    _FoodCategory('Tiffin', AppIconAssets.morningLunchIcon),
    _FoodCategory('Bakery', AppIconAssets.bakeryIcon),
    _FoodCategory('Sweets', AppIconAssets.sweetsIcon),
    _FoodCategory('Namkeen', AppIconAssets.namkeenIcon),
    _FoodCategory('Pickles', AppIconAssets.picklesIcon),
  ];

  final List<String> _tiffinFilterTabs = [
    'Break-Fast',
    'Morning Tiffin / Lunch',
    'Evening Tiffin / Dinner',
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
                'Leave without ordering?',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              CustomText(
                'Your cart will be cleared if you go back.',
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
                      child: CustomText('Leave',
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
                      child: CustomText('View Cart',
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
                      name: c.name,
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
          cartLabel: stores > 1 ? 'View Carts' : 'View Cart',
          itemLabel: stores > 1
              ? '$stores kitchens  •  $count ${count == 1 ? 'item' : 'items'}'
              : '$count ${count == 1 ? 'item' : 'items'}  •  ${AppConstants.rupeeSymbol}${cartController.totalPrice.toStringAsFixed(0)}',
          onTap: () => Get.to(() => const HmfCartScreen()),
        ),
      );
    });
  }

  // Open the store details. Keyed off the store owner [userId] — the backend
  // resolves the store (home-foods + tiffins) by userId.
  void _openStore(String? userId) {
    if (userId == null || userId.isEmpty) {
      commonSnackBar(message: 'Store details not available');
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
                'Post Food',
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
          return _emptyState('No tiffin items found yet.');
        }
        return _buildTiffinList();
      } else {
        if (controller.isHomeFoodFirstLoading.value) {
          return _loader();
        }
        if (controller.homeFoodList.isEmpty) {
          return _emptyState('No items found here yet.');
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
      discount: '$discount'.startsWith('0') ? '' : '$discount% Off',
      cookingMethod: meal.cookingMethod,
      startTime: meal.startTime,
      endTime: meal.endTime,
      storeName: meal.centerName,
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
      homeDelivery: kitchen?.homeDelivery ?? false,
      address: kitchen?.address ?? '',
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
    bool homeDelivery = false,
    String address = '',
  }) {
    final hasTime =
        (startTime?.isNotEmpty ?? false) && (endTime?.isNotEmpty ?? false);
    final showDiscount = discount.isNotEmpty && !discount.startsWith('0');

    return _foodCardShell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: details column ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (foodType.isNotEmpty) ...[
                  _vegLabel(foodType),
                  const SizedBox(height: 6),
                ],
                CustomText(
                  name,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 6),
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
                if (storeName.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  _storeLine(storeName, storeLogo, homeDelivery),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _addressRow(address),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Right: food image ──
          _foodImage(imageUrl),
        ],
      ),
    );
  }

  /// Clean rounded food image on the right of the card.
  Widget _foodImage(String? imageUrl) {
    const double size = 112;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.greyE5.withValues(alpha: 0.5)),
                errorWidget: (_, __, ___) => _placeholderIcon(),
              )
            : _placeholderIcon(),
      ),
    );
  }

  /// Inline store line (logo + name, optional delivery glyph). Non-interactive
  /// on its own — the whole card handles the tap to open the store.
  Widget _storeLine(String name, String? logoUrl, bool homeDelivery) {
    const green = Color(0xFF1E7D34);
    return Row(
      children: [
        _kitchenAvatar(logoUrl, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: CustomText(
            name,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _primaryDeep,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (homeDelivery) ...[
          const SizedBox(width: 6),
          const Icon(Icons.delivery_dining_rounded, size: 15, color: green),
        ],
      ],
    );
  }

  /// Single-line address row with a location pin, shown under the food meta
  /// when the nested kitchen profile carries an address.
  Widget _addressRow(String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_rounded,
            size: 13, color: AppColors.secondaryTextColor),
        const SizedBox(width: 3),
        Expanded(
          child: CustomText(
            address,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
          child: Padding(padding: const EdgeInsets.all(12), child: child),
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

  /// Veg / non-veg marker with its label — the first line of the food card.
  Widget _vegLabel(String foodType) {
    final color = _vegColor(foodType);
    final isVeg = !foodType.toLowerCase().contains('non');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _vegMarker(color, size: 14),
        const SizedBox(width: 5),
        CustomText(
          isVeg ? 'Veg' : 'Non-Veg',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ],
    );
  }

}

class _FoodCategory {
  final String name;
  final String icon;
  const _FoodCategory(this.name, this.icon);
}
