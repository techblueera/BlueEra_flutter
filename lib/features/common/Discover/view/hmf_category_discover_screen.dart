import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/controller/hmf_cart_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/hmf_consumer_controller.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_store_details_discover_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_food_profile_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_or_cooking_method.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/common/Discover/model/consumer_tiffin_response_model.dart';
import 'package:BlueEra/widgets/app_loader.dart';
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

  final EarnProfileRepo _earnProfileRepo = EarnProfileRepo();

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

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.appBackgroundColor,
        body: Stack(
          children: [
            NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: BannerCarousel(
                    images: _bannerImages,
                    onBack: () => Navigator.pop(context),
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
                    onBack: () => Navigator.pop(context),
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
                    final cartVisible = !cartController.isEmpty &&
                        cartController.store.value != null;
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
    );
  }

  // ── Floating cart bar ──
  // Reflects the shared cart (items are added on the store details screen,
  // which ADD here routes to). Tapping opens the same cart page.
  Widget _buildCartBar() {
    return Obx(() {
      // ignore: unused_local_variable
      final _ = cartController.quantities.length; // subscribe to changes
      final kitchen = cartController.store.value;
      if (cartController.isEmpty || kitchen == null) {
        return const SizedBox.shrink();
      }
      final count = cartController.totalItems;
      return Center(
        child: FloatingCartWidget(
          itemCount: count,
          displayImages: cartController.previewImages,
          cartLabel: 'View Cart',
          itemLabel:
              '$count ${count == 1 ? 'item' : 'items'}  •  ${AppConstants.rupeeSymbol}${cartController.totalPrice.toStringAsFixed(0)}',
          onTap: () => Get.to(() => HmfCartScreen(store: kitchen)),
        ),
      );
    });
  }

  // Resolve the item's kitchen and open its store details, where the
  // existing per-kitchen cart + place-order flow lives.
  Future<void> _openStore(String? userId) async {
    if (userId == null || userId.isEmpty) {
      commonSnackBar(message: 'Store details not available');
      return;
    }
    try {
      AppLoader.show();
      final response =
          await _earnProfileRepo.fetchEarnProfileByUserId(userId: userId);
      AppLoader.hide();

      if (!response.isSuccess || response.response?.data == null) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return;
      }

      final parsed = EarnProfileResponse.fromJson(response.response!.data);
      final store = parsed.data;
      if (!parsed.success || store == null) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return;
      }

      Get.to(() => HmfStoreDetailsDiscoverScreen(store: store));
    } catch (e) {
      AppLoader.hide();
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
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
    return _foodCardShell(
      header: meal.centerName.isNotEmpty
          ? _kitchenStrip(meal.centerName, () => _openStore(meal.userId))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _foodThumb(meal.imageUrl, meal.foodType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  meal.tiffinName,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 7),
                PriceRow(
                  sellingPrice: '${AppConstants.rupeeSymbol}${meal.sellingPrice}',
                  mrp: '${AppConstants.rupeeSymbol}${meal.mrpPrice}',
                  discount:
                      '${calculateDiscount(meal.sellingPrice, meal.mrpPrice)}% Off',
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (meal.cookingMethod.isNotEmpty)
                      FoodTypeOrCookingMethod(
                        label: meal.cookingMethod,
                        icon: AppIconAssets.boiled,
                      ),
                    if (meal.startTime.isNotEmpty)
                      FoodTypeOrCookingMethod(
                        label: '${meal.startTime} - ${meal.endTime}',
                        icon: AppIconAssets.storeWatch,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _addButton(() => _openStore(meal.userId)),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return _foodCardShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _foodThumb(item.imageUrl, item.foodType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  item.foodName,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 7),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    CustomText(
                      '${AppConstants.rupeeSymbol}${item.sellingPrice}',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    if (item.mrpPrice.isNotEmpty)
                      CustomText(
                        '${AppConstants.rupeeSymbol}${item.mrpPrice}',
                        fontSize: 11.5,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor,
                      ),
                    if (item.discount.isNotEmpty)
                      DiscountBadge(discountText: item.discount),
                  ],
                ),
                if (item.cookingMethod.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  FoodTypeOrCookingMethod(
                    label: item.cookingMethod,
                    icon: AppIconAssets.boiled,
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _addButton(() => _openStore(item.userId)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared building blocks ──

  /// Elevated white card shell with optional header strip + padded body.
  Widget _foodCardShell({Widget? header, required Widget child}) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) header,
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  /// Tinted "kitchen" header strip with a storefront badge and chevron.
  Widget _kitchenStrip(String name, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(color: AppColors.greyE5.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded,
                  size: 14, color: _primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomText(
                name,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  /// Rounded 92x92 food thumbnail with veg/non-veg marker.
  Widget _foodThumb(String? imageUrl, String foodType) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 92,
            height: 92,
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
        ),
        if (foodType.isNotEmpty)
          Positioned(top: 5, left: 5, child: _vegBadge(foodType)),
      ],
    );
  }

  /// Solid gradient ADD pill — the primary CTA.
  Widget _addButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primaryDeep],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.32),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 4),
              CustomText(
                'ADD',
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 92,
      height: 92,
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

  /// FSSAI-style veg / non-veg square marker on a white chip.
  Widget _vegBadge(String foodType) {
    final bool isVeg = !foodType.toLowerCase().contains('non');
    final Color color =
        isVeg ? const Color(0xFF1E7D34) : const Color(0xFFC0341D);
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.6),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _FoodCategory {
  final String name;
  final String icon;
  const _FoodCategory(this.name, this.icon);
}
