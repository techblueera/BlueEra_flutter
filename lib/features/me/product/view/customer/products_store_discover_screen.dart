import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/me/product/view/customer/product_store_card.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/view/customer/product_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/product_self_pickup_cart.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ProductsStoreDiscoverScreen extends StatefulWidget {
  final String? productCategoryName;
  final String? productCategory;

  const ProductsStoreDiscoverScreen({
    super.key,
    this.productCategoryName,
    this.productCategory,
  });

  @override
  State<ProductsStoreDiscoverScreen> createState() => _ProductsStoreDiscoverScreenState();
}

class _ProductsStoreDiscoverScreenState extends State<ProductsStoreDiscoverScreen> {
  final controller = getOrPut(() => StoreController());
  final AuthController _authController = Get.find<AuthController>();

  /// Sentinel tag id for the leading "All Products" tab. Selecting it clears
  /// the category filter, so the store API returns stores across every product
  /// category instead of one. Mirrors the All tab on the grocery screen.
  static const String _allProductsTagId = 'ALL_PRODUCTS';
  static const String _allProductsLabel = 'All Products';

  /// Tag id of the selected category — null while "All Products" is active.
  /// Selection is tracked by id rather than list index because the All tab has
  /// no backing onboarding category to index into.
  String? _selectedCategoryTagId;

  final ProductSelfPickupController productCartController =
      getOrPut<ProductSelfPickupController>(
          () => ProductSelfPickupController());

  List<CategoryData> get _categories => _authController.businessOnboardingProductsCategories;

  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/shopping-cart-full-with-products_1232-920.jpg?w=1380",
    "https://img.freepik.com/free-photo/black-friday-elements-assortment_23-2149074076.jpg?w=1380",
    "https://img.freepik.com/free-photo/retail-store-with-colorful-products-shelves_23-2150726517.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    controller.typeOfBusiness = BusinessType.Product.name;

    if (widget.productCategory != null) {
      // Opened from a category tile — land on that category.
      controller.businessCategoryId = widget.productCategory;
      _selectedCategoryTagId = widget.productCategory;
    } else {
      // Lands on "All Products": no category filter, so every store nearby is
      // listed. (It used to land on the first onboarding category.)
      controller.businessCategoryId = null;
    }

    // Skip the call on re-entry when the cached list is still fresh; category
    // taps below are also cache-aware (pull-to-refresh forces fresh).
    controller.getAllStoreNearByIfNeeded();
  }

  @override
  void dispose() {
    deleteIfRegistered<ProductSelfPickupController>();
    super.dispose();
  }

  void _handleBackWithCartWarning() {
    final isCartEmpty = productCartController.selectedProductVariants.isEmpty;
    if (isCartEmpty) {
      Get.back();
      return;
    }
    _showCartWarningDialog(
      onPlaceOrder: () {
        Get.to(() => const ProductSelfPickUpCartScreen());
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
                        productCartController.clearCart();
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

  /// [tagId] null selects the "All Products" tab, which clears the filter.
  void _onCategoryTap(String? tagId) {
    _selectedCategoryTagId = tagId;
    controller.businessCategoryId = tagId;
    // Cache-aware: a recently-viewed category loads instantly from its own
    // cache entry; pull-to-refresh forces a fresh fetch.
    controller.getAllStoreNearByIfNeeded();
  }

  /// Label for the active tab. The "All Products" tab has no backing category,
  /// so the empty-state copy falls back to its label.
  String get _selectedCategoryLabel {
    final id = _selectedCategoryTagId;
    if (id == null) return _allProductsLabel;
    final idx = _categories.indexWhere((c) => c.tagId == id);
    return idx >= 0 ? (_categories[idx].name ?? '') : '';
  }

  void _openInventoryAiSearch() {
    final chat = ChatViewController.inventoryAiChatListSearchModule;
    Get.to(() => AiCommonSearchScreen(
          chatType: AppConstants.askInventory_Chat_Type,
          profileImage: chat?.sender?.profileImage,
          name: chat?.sender?.name,
          contactNo: chat?.sender?.contactNo,
          conversationId: '',
          userId: '',
          businessId: '',
          type: chat?.sender?.accountType,
          isInitialMessage: false,
        ));
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final width = SizeConfig.screenWidth;
    double dynamicSize(double base) => base * (width / 390);

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
                      backgroundColor: AppColors.blue5CAF.withValues(alpha: 0.1),
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
                        // Leading "All Products" tab — every store, no
                        // category filter.
                        StickyCategory(
                          id: _allProductsTagId,
                          name: _allProductsLabel,
                        ),
                        ..._categories.map((c) {
                          return StickyCategory(
                            id: c.tagId ?? '',
                            name: c.name ?? '',
                            imageUrl: getProductCategoryIcon(c.tagId),
                            // imageUrl: c.imageUrl,
                          );
                        }),
                      ],
                      selectedId:
                          _selectedCategoryTagId ?? _allProductsTagId,
                      onCategoryTap: (item) {
                        if (item.id == _allProductsTagId) {
                          // "Show all" — clear the category filter.
                          _onCategoryTap(null);
                        } else {
                          final idx = _categories
                              .indexWhere((c) => c.tagId == item.id);
                          if (idx >= 0) _onCategoryTap(_categories[idx].tagId);
                        }
                        setState(() {});
                      },
                      onBack: _handleBackWithCartWarning,
                      onSearchTap: _openInventoryAiSearch,
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
                  child: _buildStoreContent(dynamicSize),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: ProductSelfPickupCart(controller: productCartController),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreContent(double Function(double) dynamicSize) {
    return Obx(() {
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.allStore.isEmpty) {
        return Center(
          child: EmptyStateWidget(
            message: AppStrings.noStoresFoundForCategory
                .trParams({'category': _selectedCategoryLabel}),
          ),
        );
      }

      return Column(
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
          //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: AppColors.white,
          //       borderRadius: BorderRadius.circular(20),
          //       border: Border.all(color: AppColors.greyE5, width: 0.5),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(Icons.storefront_rounded,
          //             size: 14, color: AppColors.primaryColor),
          //         const SizedBox(width: 6),
          //         CustomText(
          //           "${controller.allStore.length}${controller.isAllStoreLoadingMore.value ? '+' : ''} Stores",
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
            child: RefreshIndicator(
              onRefresh: () => controller.getAllStoreNearBy(),
              child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: SizeConfig.size12,
                right: SizeConfig.size12,
                bottom: SizeConfig.paddingL + 70,
              ),
              itemCount: controller.allStore.length +
                  (controller.isAllStoreLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.allStore.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final storeData = controller.allStore[index];

                return Padding(
                  padding: EdgeInsets.only(bottom: dynamicSize(10)),
                  child: ProductStoreCard(
                    ds: dynamicSize,
                    index: index,
                    getAllStoreResData: storeData,
                  ),
                );
              },
            ),
            ),
          ),
        ],
      );
    });
  }
}
