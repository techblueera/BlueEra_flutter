import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_floating_cart.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_card.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_variant_bottom_sheet.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodProductSelectionScreen extends StatefulWidget {
  final GroceryNestedCategoryModel foodCategoryData;

  FoodProductSelectionScreen({super.key, required this.foodCategoryData});

  @override
  State<FoodProductSelectionScreen> createState() => _FoodProductSelectionScreenState();
}

class _FoodProductSelectionScreenState extends State<FoodProductSelectionScreen> {
  final controller = getOrPut(() => FoodServiceController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.resetControllerFields();

    final firstLevel1 = widget.foodCategoryData.children?.firstOrNull;

    if (firstLevel1 != null) {
      // 1. Assign Level 1 Data
      controller.selectedCategoryId.value = firstLevel1.sId ?? "";

      // 2. Sync Sub-category Tabs list
      controller.subCategoryTabs.assignAll(firstLevel1.children ?? []);

      // 3. Determine Level 2 ID (Defaulting to "All")
      controller.selectedSubCategoryId.value = "All";

      // --- DEBUG LOGS ---
      debugPrint("--- InitState Product Selection ---");
      debugPrint("Selected Level 1 (Sidebar): ${firstLevel1.name} (ID: ${controller.selectedCategoryId.value})");
      debugPrint("Sub-categories found: ${controller.subCategoryTabs.length}");
      debugPrint("Selected Level 2 (Tab): ${controller.selectedSubCategoryId.value}");
      // ------------------

      // 4. API Call
      controller.getFoodByCategoryIDController(
          categoryIdParams: {ApiKeys.parentId: controller.selectedCategoryId.value}
      );
    } else {
      debugPrint("--- InitState Warning: No Level 1 Categories found ---");
    }
    // scrollController.addListener(_onScrollListener);
  }

  // void _onScrollListener(){
  //   if (scrollController.position.pixels >=
  //       scrollController.position.maxScrollExtent - 200 &&
  //       !controller.isGroceryCategoryProductsLoadingMore.value &&
  //       controller.groceryCategoryProductsHasMore) {
  //     controller.getFoodByCategoryIDController(
  //       isLoadMore: true,
  //     );
  //   }
  // }

  @override
  void dispose() {
    // deleteIfRegistered<FoodServiceController>();
    // scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Publish CTA lives in the floating cart overlay below; no
      // docked bottomNavigationBar here.
      appBar: AppBar(
        leading: InkWell(
            onTap: () {
              Get.back();
            },
            child: const Icon(Icons.arrow_back_ios, color: Colors.black)),
        actions: [
          InkWell(
            onTap: () {
              Get.toNamed(RouteHelper.getFoodEntryAiScreenRoute(),
                  arguments: {
                    ApiKeys.argCreateMissingProductIndex: null,
                  });
            },
            child: Container(
              margin: EdgeInsets.only(right: 15),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.add,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  CustomText(
                    AppStrings.foodAddOwnFoodItems.tr,
                    color: AppColors.white,
                  )
                ],
              ),
            ),
          )
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Row(
            children: [
              _buildLeftSidebar(),
              _buildRightContent(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: FoodFloatingCart(
              controller: controller,
              isSnapSearch: false,
            ),
          ),
        ],
      ),
    );
  }


  // 1. LEFT SIDE WIDGET
  Widget _buildLeftSidebar() {
    return CommonGenericLeftSideCategoryList<GroceryNestedCategoryModel>(
      items: widget.foodCategoryData.children ?? [],
      getIcon: (cat) => cat.image ?? '',
      getLabel: (cat) => cat.name ?? '',
      isSelected: (cat) => controller.selectedCategoryId.value == cat.sId,
      onTap: (cat, index) {
        // Print sub-categories in log
        debugPrint("Sub-categories for ${cat.name}: ${cat.children?.map((e) => e.name).toList()}");

        controller.selectedCategoryId.value = cat.sId ?? "";
        controller.subCategoryTabs.assignAll(cat.children ?? []);
        controller.selectedSubCategoryId.value = "All";

        controller.getFoodByCategoryIDController(
            categoryIdParams: {ApiKeys.parentId: cat.sId ?? ""}
        );
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
            final List<dynamic> tabData = ["All", ...controller.subCategoryTabs];

            // This ensures the common widget knows which tab to highlight.
            int currentIndex = tabData.indexWhere((item) {
              final String id = (item is String) ? "All" : (item.sId ?? "");
              return id == controller.selectedSubCategoryId.value;
            });

            if (currentIndex == -1) currentIndex = 0;

            return HorizontalTabSelector<dynamic>(
              tabs: tabData,
              selectedIndex: currentIndex,
              labelBuilder: (item) => (item is String) ? item : (item.name ?? ""),
              horizontalPadding: 16,
              verticalPadding: 8,
              verticalMargin: 10,
              unSelectedBackgroundColor: AppColors.white,
              unSelectedBorderColor: AppColors.greyE5,
              onTabSelected: (index, label) {
                var selectedItem = tabData[index];
                final String itemId = (selectedItem is String) ? "All" : (selectedItem.sId ?? "");

                controller.selectedSubCategoryId.value = itemId;

                var targetIdParams = (itemId == "All")
                    ? {ApiKeys.parentId: controller.selectedCategoryId.value}
                    : {ApiKeys.category : itemId};

                controller.getFoodByCategoryIDController(
                    categoryIdParams: targetIdParams
                );
              },
            );
          }),

          // Product List
          Obx(() => Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    8,
                    8,
                    // Reserve space for the floating cart so the last
                    // item never hides behind it.
                    FoodFloatingCart.reservedSpace,
                  ),
                  itemCount: controller.categoryFoundProductDataList.length,
                  itemBuilder: (context, index) {
                    final product =
                        controller.categoryFoundProductDataList[index];
                    return FoodProductCard(
                      product: product,
                      onShowVariants: (p) => _showVariantSheet(context, p),
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }

  // 3. Bottom Sheet Implementation
  void _showVariantSheet(
      BuildContext context, CategoryFoodProductData product) {
    Get.bottomSheet(
      ProductVariantBottomSheet(
        product: product,
        controller: controller,
        isSnapSearch: false,
      ),
      isScrollControlled: true,
    );
  }
}
