import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/self_pickup_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
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

class GroceryOrFoodStoresScreen extends StatefulWidget {

  final List<OnboardingCategoryModel> arrCategories;
  // final OnboardingCategoryModel selectedGroceryOrFoodCategory;
  final bool isGroceryStore;

  const GroceryOrFoodStoresScreen(
      { super.key,
        required this.arrCategories,
        // required this.selectedGroceryOrFoodCategory,
        required this.isGroceryStore,
        });

  @override
  State<GroceryOrFoodStoresScreen> createState() =>
      _GroceryOrFoodStoresScreenState();
}

class _GroceryOrFoodStoresScreenState extends State<GroceryOrFoodStoresScreen> {
  final controller = getOrPut(() => NewStoreController());
  final groceryController = getOrPut(() => GroceryController());
  final groceryCustomerController = getOrPut(() => GrocerySelfPickupConsumerController());
  final foodCustomerListingScreen = getOrPut(() => FoodCustomerController());
  final ScrollController storesScrollController = ScrollController();
  late List<OnboardingCategoryModel> _arrCategories;
  final List<Color> cardColors = [
    const Color(0xFFFFFEF7), // Soft Cream
    const Color(0xFFFFF9F3), // Pale Peach
    const Color(0xFFFFF5F5), // Light Rose
  ];

  @override
  initState() {
    super.initState();

    if(widget.isGroceryStore){
      controller.typeOfBusiness = BusinessType.Grocery.name;
    }else{
      controller.typeOfBusiness = BusinessType.Food.name;
    }

    _arrCategories = widget.arrCategories;
    if(controller.selectedGroceryOrFoodCategoryData.value != null){
      controller.businessCategoryId = controller.selectedGroceryOrFoodCategoryData.value?.slugId;
    }else{
      controller.businessCategoryId = 'RECENTLY_VISITED';
    }


    controller.getAllStoreNearBy();

    // Listener for Pagination
    controller.addListener(_onLoadMore);
  }

  @override
  dispose(){
    super.dispose();
    deleteIfRegistered<GroceryController>();
    deleteIfRegistered<GrocerySelfPickupConsumerController>();
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
          title: widget.isGroceryStore
              ? 'Grocery & Stationary'
              : 'Restaurant & Food',
           onBackTap: ()=> showCartWarning(),
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
    final allItem = OnboardingCategoryModel(
      name: 'Recently Visited',
      slugId: 'RECENTLY_VISITED',
      icon: AppImageAssets.all,
      accountType: AppConstants.business,
    );

    final fullList = [allItem, ..._arrCategories];

    return CommonGenericLeftSideCategoryList<OnboardingCategoryModel>(
      items: fullList,
      getLabel: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      isSelected: (item) {
        if (item.slugId == 'RECENTLY_VISITED') {
          return controller.selectedGroceryOrFoodCategoryData.value == null;
        }
        return controller.selectedGroceryOrFoodCategoryData.value?.slugId == item.slugId;
      },
      onTap: (item, index) {
        if (item.slugId == 'RECENTLY_VISITED') {
          controller.selectedGroceryOrFoodCategoryData.value = null;
        } else {
          controller.selectedGroceryOrFoodCategoryData.value = item;
        }
        controller.businessCategoryId = item.slugId;

        // Single API Call (Clean & Shared)
        controller.getAllStoreNearBy();
      },
    );
  }
  
  Widget rightContent() {
    return Obx(() {
      if (controller.isAllStoreFirstLoading.value &&
          controller.allStore.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.allStore.isEmpty) {
        return Center(
            child: EmptyStateWidget(message: "No ${controller.businessCategoryId} found"));
      }

      return ListView.builder(
          controller: storesScrollController,
          itemCount: controller.allStore.length +
              (controller.isAllStoreLoadingMore.value ? 1 : 0),
          shrinkWrap: true,
          padding: EdgeInsets.only(
              top: SizeConfig.paddingM,
              bottom: SizeConfig.paddingL,
            right: SizeConfig.paddingXS,
          ),
          itemBuilder: (context, index) {
            final Color bgColor = cardColors[index % cardColors.length];

            if (index == controller.allStore.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            var store = controller.allStore[index];

            return StoreCard(
                store: store,
                bgColor: bgColor,
                isGroceryStore: widget.isGroceryStore,
            );
          });
    });
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

