import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/self_pickup_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/self_pickup_common_cart_ui.dart';
import 'package:BlueEra/features/me/grocery/widget/store_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_enum.dart';

class GroceryStoresScreen extends StatefulWidget {

  const GroceryStoresScreen({super.key});

  @override
  State<GroceryStoresScreen> createState() =>
      _GroceryStoresScreenState();
}

class _GroceryStoresScreenState extends State<GroceryStoresScreen>
    with SingleTickerProviderStateMixin {
  final controller = getOrPut(() => NewStoreController());
  final groceryController = getOrPut(() => GroceryController());
  final groceryCustomerController = getOrPut(() => GrocerySelfPickupConsumerController());
  final foodCustomerListingScreen = getOrPut(() => FoodCustomerController());
  final ScrollController storesScrollController = ScrollController();
  final AuthController _authController = Get.find<AuthController>();
  AnimationController? _shimmerController;

  List<CategoryData> get _arrCategories => _authController.businessOnboardingGroceriesCategories;
  final List<Color> cardColors = [
    const Color(0xFFFFFEF7), // Soft Cream
    const Color(0xFFFFF9F3), // Pale Peach
    const Color(0xFFFFF5F5), // Light Rose
  ];

  @override
  initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    controller.typeOfBusiness = BusinessType.Grocery.name;

    if(controller.selectedGroceryOrFoodCategoryData.value != null){
      controller.businessCategoryId = controller.selectedGroceryOrFoodCategoryData.value?.tagId;
    }
    else if (_arrCategories.isNotEmpty) {
      controller.businessCategoryId = _arrCategories.first.tagId;
    }


    controller.getAllStoreNearBy();

    // Listener for Pagination on ScrollController
    storesScrollController.addListener(_onLoadMore);
  }

  @override
  dispose(){
    storesScrollController.removeListener(_onLoadMore);
    storesScrollController.dispose();
    _shimmerController?.dispose();
    _shimmerController = null;
    deleteIfRegistered<GroceryController>();
    deleteIfRegistered<GrocerySelfPickupConsumerController>();
    super.dispose();
  }

  void _onLoadMore(){
    if (storesScrollController.position.pixels >=
        storesScrollController.position.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
  }

  void showCartWarning(){
    // Logic: If cart is NOT empty, show warning
    final bool isCartEmpty = groceryCustomerController.selectedGroceriesVariants.isEmpty;

    if (isCartEmpty) {
      Get.back(); // Allow exit
    } else {
      showCartWarningDialog(
        onPlaceOrder: () {
          // Your logic to navigate to Checkout
          print("Navigate to Checkout from Dialog");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SelfPickUpCartScreen(),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        showCartWarning();
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          isCustomTitleWidget: () => Obx(() => Text(
            controller.selectedGroceryOrFoodCategoryData.value == null
                ? 'Grocery & Stationary'
                : controller.selectedGroceryOrFoodCategoryData.value?.name ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
          onBackTap: () => showCartWarning(),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftCategoryList(),
                  SizedBox(
                    width: SizeConfig.size6,
                  ),
                  Expanded(
                      child: rightContent()
                  ),
                ],
              ),

              SelfPickupCommonCartUi(
                selectedVariants: groceryCustomerController.selectedGroceriesVariants,
              ),
            ],
          )
        ),
      ),
    );
  }

  Widget leftCategoryList() {
    // final allItem = OnboardingCategoryModel(
    //   name: 'Recently Visited',
    //   slugId: 'RECENTLY_VISITED',
    //   icon: AppImageAssets.all,
    //   accountType: AppConstants.business,
    // );
    //
    // final fullList = [allItem, ..._arrCategories];
    return CommonGenericLeftSideCategoryList<CategoryData>(
      items: _arrCategories,
      getLabel: (item) => item.name ?? '',
      getIcon: (item) => item.imageUrl ?? '',
      isSelected: (item) {
        // if (item.slugId == 'RECENTLY_VISITED') {
        //   return controller.selectedGroceryOrFoodCategoryData.value == null;
        // }
        return controller.selectedGroceryOrFoodCategoryData.value?.tagId == item.tagId;
      },
      onTap: (item, index) {
        // if (item.slugId == 'RECENTLY_VISITED') {
        //   controller.selectedGroceryOrFoodCategoryData.value = null;
        // } else {
        //   controller.selectedGroceryOrFoodCategoryData.value = item;
        // }
        controller.selectedGroceryOrFoodCategoryData.value = item;
        controller.businessCategoryId = item.tagId;

        // Single API Call (Clean & Shared)
        controller.getAllStoreNearBy();
      },
    );
  }
  
  Widget rightContent() {
    return Obx(() {
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return _buildSkeletonLoading();
      }

      if (controller.allStore.isEmpty) {
        return Center(
            child: EmptyStateWidget(
                message: "No ${controller.selectedGroceryOrFoodCategoryData.value?.name ?? 'stores'} found"));
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: ValueKey(controller.businessCategoryId),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header chip
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
                itemCount: controller.allStore.length +
                    (controller.isAllStoreLoadingMore.value ? 1 : 0),
                padding: EdgeInsets.only(
                  bottom: SizeConfig.paddingL + 70,
                  right: SizeConfig.paddingXS,
                ),
                itemBuilder: (context, index) {
                  final Color bgColor = cardColors[index % cardColors.length];

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

                  return StoreCard(
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

  /// Skeleton with shimmer pulse animation mirroring [StoreCard] layout
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
          right: SizeConfig.paddingXS,
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
                // Header: avatar + name + badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(SizeConfig.size40, SizeConfig.size40, radius: SizeConfig.size20),
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

                // Address card
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.greyE5, width: 0.5),
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

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.greyE5, width: 0.5),
                          color: AppColors.white,
                        ),
                        child: Row(
                          children: [
                            _shimmerBox(30, 30, radius: 6),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                          border: Border.all(color: AppColors.greyE5, width: 0.5),
                          color: AppColors.white,
                        ),
                        child: Row(
                          children: [
                            _shimmerBox(30, 30, radius: 6),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              const Icon(
                Icons.error_rounded,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 24),

              // Message Text
              const CustomText(
                "Place Order Unless Your\nCard Will Be Empty,\nYou Can't See Selected Items",
                textAlign: TextAlign.center,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Skip Button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back(); // Close Dialog
                        Get.back(); // Exit Screen (The "Skip" action)
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                          "Skip",
                          color: AppColors.secondaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Place Order Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Close Dialog
                        onPlaceOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const CustomText(
                          "Place Order",
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

