import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_customer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/grocery_product_card.dart';
import 'package:BlueEra/features/me/grocery/widget/common_cart_icon.dart';
import 'package:BlueEra/features/me/grocery/widget/self_pickup_common_cart_ui.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class OtherGroceryProductsScreen extends StatefulWidget {
  final String userId;
  final String argArrGroceryCatKey;
  final String argArrGroceryCatName;

  OtherGroceryProductsScreen({
    super.key,
    required this.userId,
    required this.argArrGroceryCatKey,
    required this.argArrGroceryCatName,
  });

  @override
  State<OtherGroceryProductsScreen> createState() => _OtherGroceryProductsScreenState();
}

class _OtherGroceryProductsScreenState extends State<OtherGroceryProductsScreen> {
  final controller = getOrPut(() => GroceryController());
  final groceryCustomerController = getOrPut(() => GroceryCustomerController());
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  late String _userId;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScrollListener);
    _userId = widget.userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchGroceryNestedCategoryWithInventory(
          userId: widget.userId,
          groceryCatKey: widget.argArrGroceryCatKey
      ).then((response) {
        controller.selectedGroceryData.value = controller.groceryNestedCategoryWithInventoryList.first;
        getGroceryProducts();
      });
    });
  }

  void _onScrollListener(){
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
        !controller.isGroceryDataLoadingMore.value &&
        controller.groceryDataHasMore) {
      getGroceryProducts(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  void getGroceryProducts({bool isLoadMore = false}) {
    final String categoryId = controller.selectedGroceryData.value?.sId ?? '';

    controller.fetchGroceryProducts(
      userId: _userId,
      categoryId: categoryId,
      isLoadMore: isLoadMore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShadowShow: false,
        isCustomTitleWidget: ()=> Obx(() {
          final bool isOpen = controller.isSearchOpen.value;

          return Expanded(
            child: isOpen
                ? CommonSearchBar(
              controller: searchController,
              isShowCursor: true,
              // onSearchTap: () => controller.fetchGroceryProducts(),
              onClearCallback: () {
                searchController.clear();
                // controller.fetchGroceryProducts();
              },
              hintText: "Search products...",
            )
                : CustomText(
              controller.selectedGroceryData.value?.name ?? "Products",
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
        }),
        buildCustomActionWidget: () =>  Obx(() {
          final bool isOpen = controller.isSearchOpen.value;

          // The Toggle Button is now part of the Title Widget
          return InkWell(
            onTap: () {
              controller.isSearchOpen.value = !isOpen;
              if (!controller.isSearchOpen.value) {
                searchController.clear();
                // controller.fetchGroceryProducts();
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Icon(
                isOpen ? Icons.search_off_outlined : Icons.search_outlined,
                color: AppColors.black,
                size: 24,
              ),
            ),
          );
        }),
      ),
      body: Obx(() =>
      Stack(
        children: [
          controller
              .groceryNestedCategoryWithInventoryLoading.value
              ? const Center(child: CircularProgressIndicator())
              : controller
              .groceryNestedCategoryWithInventoryList.isEmpty
              ? const Center(child: Text('No categories found'))
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftCategoryList(),
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
    )
  );
}

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<GroceryNestedCategoryModel>(
      items: controller.groceryNestedCategoryWithInventoryList,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) =>
      controller.selectedGroceryData.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = controller.groceryNestedCategoryWithInventoryList[index];
        if (controller.selectedGroceryData.value?.sId == selected.sId) {
          return;
        }
        controller.selectedGroceryData.value = selected;
        getGroceryProducts();
      },
    );
  }

  Widget rightContent() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final List<dynamic> tabData = ["All", ...controller.selectedGroceryData.value?.children??[]];

            return HorizontalTabSelector<dynamic>(
              tabs: tabData,
              selectedIndex: controller.selectedHorizontalTabIndex.value,
              labelBuilder: (item) => (item is String) ? item : (item.name ?? ""),
              horizontalPadding: 8,
              verticalPadding: 6,
              verticalMargin: 0,
              horizontalMargin: 0,
              unSelectedBackgroundColor: AppColors.white,
              unSelectedBorderColor: AppColors.greyE5,
              onTabSelected: (index, label) {
                controller.selectedHorizontalTabIndex.value = index;
                controller.fetchGroceryCategoryProducts();
              },
            );
          },),

          SizedBox(height: 8),

          Expanded(
            child: controller.isGroceryDataFirstLoading.value
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: SizedBox(
                    height: 20.0,
                    width: 20.0,
                    child: CircularProgressIndicator()
                ),
              ),
            )
                : controller.groceryProductsList.isNotEmpty
                ?  ListView.builder(
              itemCount: controller.groceryProductsList.length +
                  (controller.isGroceryDataLoadingMore.value ? 1 : 0),
              controller: scrollController,
              padding: EdgeInsets.only(
                  bottom: SizeConfig.size15 + kBottomNavigationBarHeight
              ),
              itemBuilder: (BuildContext context, int index) {
                if (index >= controller.groceryProductsList.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final groceryProducts = controller.groceryProductsList[index];

                return GroceryProductCard(
                    groceryProducts: groceryProducts,
                    isMyGroceryStore: widget.userId == userId
                );
              },
            ) : Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: EmptyStateWidget(
                    message:
                    'No ${controller.currentTabName.tr} found.')
            ),
          ),
        ],
      ),
    );
  }


}



