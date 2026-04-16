import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_self_pickup_cart.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_store_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_enum.dart';

class GroceryStoresScreen extends StatefulWidget {
  const GroceryStoresScreen({super.key});

  @override
  State<GroceryStoresScreen> createState() => _GroceryStoresScreenState();
}

class _GroceryStoresScreenState extends State<GroceryStoresScreen>
    with SingleTickerProviderStateMixin {
  final controller = getOrPut(() => NewStoreController());
  final groceryController = getOrPut(() => GroceryController());
  final groceryCustomerController =
      getOrPut(() => GrocerySelfPickupConsumerController());
  final ScrollController _nestedScrollController = ScrollController();
  final AuthController _authController = Get.find<AuthController>();
  AnimationController? _shimmerController;

  List<CategoryData> get _arrCategories =>
      _authController.businessOnboardingGroceriesCategories;

  final List<Color> cardColors = [
    const Color(0xFFFFFEF7),
    const Color(0xFFFFF9F3),
    const Color(0xFFFFF5F5),
  ];

  int _locationVersion = 0;

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

    controller.getAllStoreNearBy();
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
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyCategoryHeaderDelegate(
                      topPadding: statusBarHeight,
                      categories: _arrCategories.map((c) => StickyCategory(
                        id: c.tagId ?? '',
                        name: c.name ?? '',
                        imageUrl: c.imageUrl,
                      )).toList(),
                      selectedId: controller.selectedGroceryCategoryData.value?.tagId,
                      onCategoryTap: (item) {
                        final cat = _arrCategories.firstWhere((c) => c.tagId == item.id);
                        controller.selectedGroceryCategoryData.value = cat;
                        controller.businessCategoryId = cat.tagId;
                        controller.getAllStoreNearBy();
                        setState(() {});
                      },
                      onBack: () => showCartWarning(),
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
                  child: GrocerySelfPickupCart(
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

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: ValueKey(controller.businessCategoryId),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: SizeConfig.size12,
                right: SizeConfig.size12,
                bottom: SizeConfig.size6,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.greyE5, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded,
                        size: 14, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    CustomText(
                      "${controller.allStore.length}${controller.isAllStoreLoadingMore.value ? '+' : ''} ${AppStrings.groceryStoresLabel}",
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.allStore.length +
                    (controller.isAllStoreLoadingMore.value ? 1 : 0),
                padding: EdgeInsets.only(
                  left: SizeConfig.size12,
                  right: SizeConfig.size12,
                  bottom: SizeConfig.paddingL + 70,
                ),
                itemBuilder: (context, index) {
                  final Color bgColor =
                      cardColors[index % cardColors.length];

                  if (index == controller.allStore.length) {
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

                  var store = controller.allStore[index];

                  return GroceryStoreCard(
                    store: store,
                    bgColor: bgColor,
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
          final Color bgColor = cardColors[index % cardColors.length];
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_rounded,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 24),
              CustomText(
                AppStrings.groceryCartWarningMessage,
                textAlign: TextAlign.center,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        AppStrings.skip,
                        color: AppColors.secondaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onPlaceOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        AppStrings.groceryPlaceOrderBtn,
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
