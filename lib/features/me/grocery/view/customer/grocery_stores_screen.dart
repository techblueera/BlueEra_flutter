import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_widget.dart';
import 'package:BlueEra/widgets/measure_size.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/grocery_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/customer_grocery_self_pickup_cart.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_store_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_enum.dart';

class GroceryStoresScreen extends StatefulWidget {
  const GroceryStoresScreen({super.key});

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

  /// 1-indexed store positions AFTER which a native ad is inserted, e.g. an ad
  /// goes between card 1 & 2, between card 3 & 4, etc.
  static const List<int> _adAfterPositions = [1, 3, 7, 11, 13, 16, 20];

  /// Beyond the last entry in [_adAfterPositions], keep inserting an ad every
  /// this many cards so longer (load-more) lists still show ads. Matches the
  /// final gap in the series (20 - 16 = 4).
  static const int _adRepeatStepAfterLast = 4;

  /// Minimum height for a native ad slot. The native layout needs enough room
  /// for a >=120 media view plus the header/body/CTA, otherwise AdMob reports
  /// "MediaView is too small for video".
  static const double _kMinNativeAdHeight = 300;

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

    if (controller.selectedGroceryCategoryData.value != null) {
      controller.businessCategoryId =
          controller.selectedGroceryCategoryData.value?.tagId;
    } else if (_arrCategories.isNotEmpty) {
      controller.businessCategoryId = _arrCategories.first.tagId;
      controller.selectedGroceryCategoryData.value = _arrCategories.first;
    }

    // Re-entry no longer refetches: only hits the API when the cached list is
    // missing or stale for this type/category. Category taps below still force
    // a fresh fetch via getAllStoreNearBy().
    controller.getAllStoreNearByIfNeeded();
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    _shimmerController?.dispose();
    _shimmerController = null;
    deleteIfRegistered<GroceryController>();
    deleteIfRegistered<GrocerySelfPickupConsumerController>();
    super.dispose();
  }

  String? _localCategoryIcon(String? tagId) {
    switch (tagId) {
      case MOHALLA_KIRANA:
        return AppImageAssets.kiranaStore;
      case GENERAL_STORE:
        return AppImageAssets.generalStore;
      case VEGETABLE_FRUIT:
        return AppImageAssets.vegFruitStore;
      case DAIRY_BAKERY:
        return AppImageAssets.dairyBakeryStore;
      case HOME_ESSENTIALS:
        return AppImageAssets.homeEssentialsStore;
      case STATIONARY_SHOP:
        return AppImageAssets.stationaryStore;
      default:
        return null;
    }
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
                      categories: _arrCategories.map((c) {
                        debugPrint('GroceryCategory tagId=${c.tagId} name=${c.name}');
                        return StickyCategory(
                          id: c.tagId ?? '',
                          name: c.name ?? '',
                          imageUrl: _localCategoryIcon(c.tagId),
                        );
                      }).toList(),
                      selectedId: controller.selectedGroceryCategoryData.value?.tagId,
                      onCategoryTap: (item) {
                        final cat = _arrCategories.firstWhere((c) => c.tagId == item.id);
                        controller.selectedGroceryCategoryData.value = cat;
                        controller.businessCategoryId = cat.tagId;
                        controller.getAllStoreNearBy();
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

  /// Build the flat list of rows for the store list: store cards with native
  /// ads inserted after the 1-indexed positions in [_adAfterPositions], then
  /// every [_adRepeatStepAfterLast] cards beyond the last position. Never adds
  /// an ad after the very last card.
  List<_GroceryRow> _buildRows(int storeCount) {
    final lastPos = _adAfterPositions.last;
    final adAfter = _adAfterPositions.toSet();

    final rows = <_GroceryRow>[];
    var adOrdinal = 0;
    for (var i = 0; i < storeCount; i++) {
      rows.add(_GroceryRow.store(i));
      final pos = i + 1; // 1-indexed card position
      final isLast = i == storeCount - 1;
      final showAd = adAfter.contains(pos) ||
          (pos > lastPos && (pos - lastPos) % _adRepeatStepAfterLast == 0);
      if (!isLast && showAd) {
        rows.add(_GroceryRow.ad(adOrdinal++));
      }
    }
    return rows;
  }

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

            SizedBox(height: SizeConfig.paddingXSL),

            Expanded(
              child: Builder(
                builder: (context) {
                  // Interleave native ads between the store cards: a native ad
                  // appears after every `_kStoresPerNativeAd` cards (never after
                  // the very last card).
                  final rows = _buildRows(controller.allStore.length);
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
                      bottom: SizeConfig.paddingL + 70,
                    ),
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
                        // Track the card height (minus the card's own size10
                        // bottom margin, which the ad re-adds itself), but never
                        // go below _kMinNativeAdHeight — the native layout needs
                        // room for a >=120 media view (else AdMob warns the
                        // media is too small for video).
                        final base = (_measuredCardHeight ?? 0) - SizeConfig.size10;
                        final adHeight =
                            base < _kMinNativeAdHeight ? _kMinNativeAdHeight : base;
                        // Stable key keyed on the ad's ordinal so the loaded
                        // ad survives list rebuilds (load-more, etc.) instead
                        // of reloading and burning impressions.
                        return NativeAdWidget(
                          key: ValueKey('grocery_native_ad_${row.adOrdinal}'),
                          height: adHeight,
                        );
                      }

                      final store = controller.allStore[row.storeIndex];

                      // Card visuals are driven entirely by
                      // `_GroceryCardPalette` inside `GroceryStoreCard` —
                      // bg, border, tile bg, tile border, divider all
                      // come from a single palette. Pass the row index so
                      // cards alternate (teal → violet → teal …) instead
                      // of being picked by a hash of `store.id`.
                      final card = GroceryStoreCard(
                        store: store,
                        index: row.storeIndex,
                      );

                      // Measure the first card so ad slots can mirror its
                      // height. Only the first card is measured to avoid a
                      // measure callback on every row.
                      if (row.storeIndex == 0) {
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
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: SizeConfig.paddingS,
          left: SizeConfig.size12,
          right: SizeConfig.size12,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, index) {
          // Mirror the two card backgrounds the real cards use (now
          // driven by `_GroceryCardPalette.cardBg` inside the card
          // widget) so the skeleton previews match the eventual look.
          final Color bgColor = index.isEven
              ? const Color(0xFFEDFDFF)
              : const Color(0xFFFCF5FF);
          return Container(
            margin: EdgeInsets.only(bottom: SizeConfig.size10),
            padding: EdgeInsets.all(SizeConfig.size10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: bgColor,
              border: Border.all(color: AppColors.greyE5, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(SizeConfig.size40, SizeConfig.size40,
                        radius: SizeConfig.size20),
                    SizedBox(width: SizeConfig.size8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(14, 120),
                          SizedBox(height: SizeConfig.size6),
                          Row(
                            children: [
                              _shimmerBox(20, 50, radius: 10),
                              const SizedBox(width: 6),
                              _shimmerBox(20, 60, radius: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.paddingXSL),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.greyE5, width: 0.5),
                    color: AppColors.white,
                  ),
                  child: Row(
                    children: [
                      _shimmerBox(32, 32, radius: 6),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _shimmerBox(12, 90),
                            SizedBox(height: SizeConfig.size4),
                            _shimmerBox(10, double.infinity),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.greyE5, width: 0.5),
                          color: AppColors.white,
                        ),
                        child: Row(
                          children: [
                            _shimmerBox(30, 30, radius: 6),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _shimmerBox(12, 24),
                                const SizedBox(height: 4),
                                _shimmerBox(10, 48),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.greyE5, width: 0.5),
                          color: AppColors.white,
                        ),
                        child: Row(
                          children: [
                            _shimmerBox(30, 30, radius: 6),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _shimmerBox(12, 24),
                                const SizedBox(height: 4),
                                _shimmerBox(10, 44),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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

/// A single row in the store list — either a store card (carrying its index
/// into `controller.allStore`) or a native ad slot (carrying its ordinal so the
/// widget can be given a stable key).
class _GroceryRow {
  const _GroceryRow.store(this.storeIndex)
      : isAd = false,
        adOrdinal = -1;

  const _GroceryRow.ad(this.adOrdinal)
      : isAd = true,
        storeIndex = -1;

  final bool isAd;
  final int storeIndex;
  final int adOrdinal;
}
