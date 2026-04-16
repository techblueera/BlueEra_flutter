import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/view/my_grocery_listing/grocery_product_card.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_self_pickup_cart.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../widgets/common_back_app_bar.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class VisitGroceryProductsScreen extends StatefulWidget {
  final String userId;
  final String visitBusinessId;
  final String argArrGroceryCatKey;
  final String argArrGroceryCatName;

  VisitGroceryProductsScreen({
    super.key,
    required this.userId,
    required this.visitBusinessId,
    required this.argArrGroceryCatKey,
    required this.argArrGroceryCatName,
  });

  @override
  State<VisitGroceryProductsScreen> createState() => _VisitGroceryProductsScreenState();
}

class _VisitGroceryProductsScreenState extends State<VisitGroceryProductsScreen> {
  final controller = getOrPut(() => GroceryController());
  final groceryCustomerController = getOrPut(() => GrocerySelfPickupConsumerController());
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
        fetchGroceryProducts();
      });
    });
  }

  void _onScrollListener(){
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
        !controller.isGroceryDataLoadingMore.value &&
        controller.groceryDataHasMore) {
      fetchGroceryProducts(isLoadMore: true);
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  void fetchGroceryProducts({bool isLoadMore = false}) {
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
              hintText: AppStrings.groceryViewSearchProductsHint.tr,
            )
                : CustomText(
              controller.selectedGroceryData.value?.name ?? AppStrings.groceryViewProductsTitle.tr,
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
              ? Center(child: Text(AppStrings.groceryViewNoCategoriesFoundPlain.tr))
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftCategoryList(),
              Expanded(
                  child: rightContent()
              ),
            ],
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: GrocerySelfPickupCart(
              controller: groceryCustomerController,
            ),
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
        fetchGroceryProducts();
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
            final List<dynamic> tabData = [AppStrings.groceryViewAll.tr, ...controller.selectedGroceryData.value?.children??[]];

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
                fetchGroceryProducts();
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
                ? MasonryGridView.count(
              itemCount: controller.groceryProductsList.length +
                  (controller.isGroceryDataLoadingMore.value ? 1 : 0),
              controller: scrollController,
              padding: EdgeInsets.only(
                  bottom: SizeConfig.size15 + kBottomNavigationBarHeight
              ),
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
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
                    flowType: GroceryCardFlowType.selfPickup,
                    bId: widget.visitBusinessId,
                );
              },
            ) : Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: EmptyStateWidget(
                    message: AppStrings.groceryViewNoXFound.trParams({'name': controller.currentTabName.tr}))
            ),
          ),
        ],
      ),
    );
  }


}



