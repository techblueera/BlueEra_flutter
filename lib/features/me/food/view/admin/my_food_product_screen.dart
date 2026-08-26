import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/admin/widget/admin_food_card.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyFoodProductScreen extends StatefulWidget {
  final GroceryNestedCategoryModel foodMenu;

  MyFoodProductScreen({
    super.key,
    required this.foodMenu,
  });

  @override
  State<MyFoodProductScreen> createState() => _MyFoodProductScreenState();
}

class _MyFoodProductScreenState extends State<MyFoodProductScreen> {
  final controller = getOrPut(() => FoodServiceController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.resetControllerFields();

    final firstLevel1 = widget.foodMenu.children?.firstOrNull;

    if (firstLevel1 != null) {
      controller.selectedCategoryId.value = firstLevel1.sId ?? "";

      // 2. Sync Sub-category Tabs list
      controller.subSubFoodCat.assignAll(firstLevel1.children ?? []);

      controller.selectedSubCategoryId.value = firstLevel1.children?.first.sId ?? '';

      // 4. API Call
      callFoodProductBySubSubCatAPi();


      // --- DEBUG LOGS ---
      debugPrint("--- InitState Product Selection ---");
      debugPrint("Selected Level 1 (Sidebar): ${firstLevel1.name} (ID: ${controller.selectedCategoryId.value})");
      debugPrint("Sub-categories found: ${controller.subSubFoodCat.length}");
      debugPrint("Selected Level 2 (Tab): ${controller.selectedSubCategoryId.value}");
      // ------------------

    } else {
      debugPrint("--- InitState Warning: No Level 1 Categories found ---");
    }
    scrollController.addListener(_onScrollListener);
  }

  void _onScrollListener(){
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
        !controller.isFoodCatProductsWithInvLoadingMore.value &&
        controller.foodCatProductsWithInvHasMore) {
      callFoodProductBySubSubCatAPi(
        isLoadMore: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }


  void callFoodProductBySubSubCatAPi({bool isLoadMore = false}){
    controller.getMyFoodProductByCategoryIdApi(
        categoryId: controller.selectedSubCategoryId.value,
        isLoadMore: isLoadMore
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: Row(
        children: [
          _buildLeftSidebar(),
          _buildRightContent()
        ],
      ),
    );
  }


  // 1. LEFT SIDE WIDGET
  Widget _buildLeftSidebar() {
    return CommonGenericLeftSideCategoryList<GroceryNestedCategoryModel>(
      items: widget.foodMenu.children?? [],
      getIcon: (cat) => cat.image ?? '',
      getLabel: (cat) => cat.name ?? '',
      isSelected: (cat) => controller.selectedCategoryId.value == cat.sId,
      onTap: (cat, index) {
        // Print sub-categories in log
        debugPrint("Sub-categories for ${cat.name}: ${cat.children?.map((e) => e.name).toList()}");

        controller.selectedCategoryId.value = cat.sId ?? "";
        if (cat.children != null) {
          controller.subSubFoodCat.assignAll(
              cat.children!.map((item) => item).toList()
          );
        } else {
          controller.subSubFoodCat.clear();
        }
        controller.selectedSubCategoryId.value = cat.children?.first.sId ?? '';

        callFoodProductBySubSubCatAPi();

      },
    );
  }

  // 2. RIGHT SIDE WIDGET
  Widget _buildRightContent() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final List<GroceryNestedCategoryModel> tabData = controller.subSubFoodCat;

            int tabIndex = controller.subSubFoodCat.indexWhere((element) {
              return element.sId == controller.selectedSubCategoryId.value;
            });

            return HorizontalTabSelector<GroceryNestedCategoryModel>(
              tabs: tabData,
              selectedIndex: tabIndex,
              labelBuilder: (item) => (item.name ?? ""),
              horizontalPadding: 16,
              verticalPadding: 8,
              verticalMargin: 10,
              unSelectedBackgroundColor: AppColors.white,
              unSelectedBorderColor: AppColors.greyE5,
              onTabSelected: (index, label) {
                var selectedItem = tabData[index];
                controller.selectedSubCategoryId.value = selectedItem.sId ?? "";
                callFoodProductBySubSubCatAPi();
              },
            );
          }),

          // Product List
          Obx(() => Expanded(
            child: controller.isFoodCatProductsWithInvLoading.value
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
                  : controller.categoryMyFoodProductDataList.isNotEmpty
                     ? ListView.builder(
              padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  bottom: 30
              ),
              itemCount: controller.categoryMyFoodProductDataList.length +
                        (controller.isFoodCatProductsWithInvLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.categoryMyFoodProductDataList.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }


                final product = controller.categoryMyFoodProductDataList[index];
                return _foodProductCard(
                  product,
                );
              },
            )
                : Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: EmptyStateWidget(
                    message: AppStrings.foodNoProductFound.tr
                )
            ),
          )),
        ],
      ),
    );
  }

  Widget _foodProductCard(CategoryFoodProductData product) {
    // Horizontal shape of the shared card — the same widget the Products tab
    // and the Offer Dish grid render, in its list form.
    return AdminFoodCard(product: product, isGridShow: false);
  }

}
