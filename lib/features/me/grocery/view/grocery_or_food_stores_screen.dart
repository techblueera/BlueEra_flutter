import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/store_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_enum.dart';

class GroceryOrFoodStoresScreen extends StatefulWidget {

  final List<OnboardingCategoryModel> arrCategories;
  final OnboardingCategoryModel selectedGroceryOrFoodCategory;
  final bool isGroceryStore;

  const GroceryOrFoodStoresScreen(
      { super.key,
        required this.arrCategories,
        required this.selectedGroceryOrFoodCategory,
        required this.isGroceryStore,
        });

  @override
  State<GroceryOrFoodStoresScreen> createState() =>
      _GroceryOrFoodStoresScreenState();
}

class _GroceryOrFoodStoresScreenState extends State<GroceryOrFoodStoresScreen> {
  final controller = getOrPut(() => NewStoreController());
  final groceryController = getOrPut(() => GroceryController());
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

    controller.selectedGroceryOrFoodCategoryData.value =
        widget.selectedGroceryOrFoodCategory;
    _arrCategories = widget.arrCategories;
    controller.businessCategoryId = controller.selectedGroceryOrFoodCategoryData.value?.slugId;

    controller.getAllStoreNearBy();

    // Listener for Pagination
    controller.addListener(_onLoadMore);
  }

  void _onLoadMore(){
    if (storesScrollController.position.pixels >=
        storesScrollController.position.maxScrollExtent - 200) {
      controller.getAllStoreNearBy(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.isGroceryStore
            ? 'Grocery & Stationary'
            : 'Restaurant & Food',
      ),
      body: SafeArea(
        child: Row(
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
        )
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


}

