import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/common/store/view/product_store_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/ai_chat/view/ai_common_search_screen.dart';
import 'package:BlueEra/features/me/product/controller/product_selfpickup_controller.dart';
import 'package:BlueEra/features/me/product/view/product_self_pickup_cart_screen.dart';
import 'package:BlueEra/features/me/product/view/widget/product_self_pickup_cart.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ProductsStoreScreen extends StatefulWidget {
  final String? productCategoryName;
  final String? productCategory;

  const ProductsStoreScreen(
      {
        super.key,
        this.productCategoryName,
        this.productCategory,
      });

  @override
  State<ProductsStoreScreen> createState() => _ProductsStoreScreenState();
}

class _ProductsStoreScreenState extends State<ProductsStoreScreen> {
  final controller = getOrPut(() => NewStoreController());
  final ScrollController storesScrollController = ScrollController();
  final AuthController _authController = Get.find<AuthController>();
  final RxInt _selectedIndex = 0.obs;

  /// Session-scoped product cart. Registered at this entry point and
  /// deleted on exit so going back clears the cart — same lifecycle as
  /// grocery's [GroceryStoresScreen] and food's
  /// [RestaurantNearMeScreen].
  final ProductSelfPickupController productCartController =
      getOrPut<ProductSelfPickupController>(
          () => ProductSelfPickupController());

  List<CategoryData> get _categories => _authController.businessOnboardingServicesCategories;
  // List<CategoryData> get _categories => _authController.businessOnboardingProductsCategories;


  @override
  void initState() {
    super.initState();
    controller.typeOfBusiness = BusinessType.Product.name;

    if (widget.productCategory != null && _categories.isNotEmpty) {
      controller.businessCategoryId = widget.productCategory;
      final idx = _categories.indexWhere((c) => c.tagId == widget.productCategory);
      if (idx >= 0) _selectedIndex.value = idx;
    } else if (_categories.isNotEmpty) {
      controller.businessCategoryId = _categories.first.tagId;
    }

    controller.getAllStoreNearBy();
    storesScrollController.addListener(_onLoadMore);
  }

  void _onLoadMore() {
    if (storesScrollController.position.pixels >=
        storesScrollController.position.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    storesScrollController.removeListener(_onLoadMore);
    storesScrollController.dispose();
    // Leaving the products entry point → clear + unregister the session
    // cart so selections don't leak across browsing sessions.
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_rounded, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              const CustomText(
                "Place Order Unless Your\nCart Will Be Empty,\nYou Can't See Selected Items",
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
                        Get.back(); // close dialog
                        productCartController.clearCart();
                        Get.back(); // leave screen
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        "Skip",
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
                      title: "Place Order",
                      bgColor: AppColors.primaryColor,
                      onTap: () {
                        Get.back();
                        onPlaceOrder();
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

  void _onCategoryTap(CategoryData item, int index) {
    _selectedIndex.value = index;
    controller.businessCategoryId = item.tagId;
    controller.getAllStoreNearBy();
  }

  @override
  Widget build(BuildContext context) {
    final width = SizeConfig.screenWidth;

    double dynamicSize(double base) => base * (width / 390);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackWithCartWarning();
      },
      child: Scaffold(
      appBar: CommonBackAppBar(
        isCustomTitleWidget: () => Obx(() {
          final idx = _selectedIndex.value;
          final name = (idx >= 0 && idx < _categories.length)
              ? _categories[idx].name ?? 'Stores'
              : 'Stores';
          return Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }),
        onBackTap: _handleBackWithCartWarning,
        buildCustomActionWidget: () {
          final chat = ChatViewController.inventoryAiChatListSearchModule;
          return IconButton(
            onPressed: () {
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
            },
            icon: Icon(
              Icons.auto_awesome,
              color: AppColors.primaryColor,
              size: SizeConfig.size24,
            ),
          );
        },
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryList(),
                SizedBox(width: SizeConfig.size6),
                Expanded(child: _buildStoreContent(dynamicSize)),
              ],
            ),
            ProductSelfPickupCart(controller: productCartController),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return CommonGenericLeftSideCategoryList<CategoryData>(
      items: _categories,
      getLabel: (item) => item.name ?? '',
      getIcon: (item) => item.imageUrl ?? '',
      isSelected: (item) {
        final idx = _categories.indexOf(item);
        return _selectedIndex.value == idx;
      },
      onTap: _onCategoryTap,
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
            message: "No ${(_selectedIndex.value >= 0 && _selectedIndex.value < _categories.length) ? _categories[_selectedIndex.value].name ?? '' : ''} stores found",
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store count chip
          Padding(
            padding: EdgeInsets.only(
              top: SizeConfig.paddingS,
              right: SizeConfig.paddingXS,
              bottom: SizeConfig.size6,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.greyE5, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_rounded,
                      size: 14, color: AppColors.primaryColor),
                  const SizedBox(width: 6),
                  CustomText(
                    "${controller.allStore.length}${controller.isAllStoreLoadingMore.value ? '+' : ''} Stores",
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
          ),

          // Store list
          Expanded(
            child: ListView.builder(
              controller: storesScrollController,
              padding: EdgeInsets.only(
                right: SizeConfig.paddingXS,
                bottom: SizeConfig.paddingL,
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
                final String businessId = storeData.id ?? "";

                return VisibilityDetector(
                  key: Key("business_$businessId"),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction >= 0.5 && businessId.isNotEmpty) {
                      controller.trackStoreListView(businessId);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(bottom: dynamicSize(10)),
                    child: ProductStoreCard(
                      ds: dynamicSize,
                      getAllStoreResData: storeData,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

}
