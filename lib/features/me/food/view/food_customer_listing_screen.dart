import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/food/controller/food_customer_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_cart_icon.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodCustomerListingScreen extends StatefulWidget {
  final GroceryNestedCategoryModel foodCategoryData;
  final String? visitBusinessId;

  FoodCustomerListingScreen({super.key, required this.foodCategoryData, this.visitBusinessId});

  @override
  State<FoodCustomerListingScreen> createState() => _FoodCustomerListingScreenState();
}

class _FoodCustomerListingScreenState extends State<FoodCustomerListingScreen> {
  final controller = Get.find<FoodCustomerController>();
  // final controller = getOrPut(() => FoodCustomerController());
  final ScrollController scrollController = ScrollController();
  String? _visitBusinessId;

  @override
  void initState() {
    super.initState();
    _visitBusinessId = widget.visitBusinessId;
    debugPrint("visit business id -- ${widget.visitBusinessId}");
    final firstLevel1 = widget.foodCategoryData.children?.firstOrNull;

    if (firstLevel1 != null) {
      controller.selectedCategoryId.value = firstLevel1.sId ?? "";
      controller.subCategoryTabs.assignAll(firstLevel1.children ?? []);
      controller.selectedSubCategoryId.value = "all";
      callFoodProductBySubCatAPi(
          categoryIdParams: {ApiKeys.parentId: controller.selectedCategoryId.value},
          visitBusinessId: _visitBusinessId
      );
    } else {
      debugPrint("--- InitState Warning: No Level 1 Categories found ---");
    }
    scrollController.addListener(_onScrollListener);
  }

  void _onScrollListener(){
    var targetIdParams = (controller.selectedSubCategoryId.value == "all")
        ? {ApiKeys.parentId: controller.selectedCategoryId.value}
        : {ApiKeys.category : controller.selectedSubCategoryId.value};

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
        !controller.isFoodCatProductsWithInvLoadingMore.value &&
        controller.foodCatProductsWithInvHasMore) {
      callFoodProductBySubCatAPi(
        categoryIdParams: targetIdParams,
        visitBusinessId: _visitBusinessId,
        isLoadMore: true,
      );
    }
  }

  void callFoodProductBySubCatAPi({
    required Map<String, String> categoryIdParams,
    String? visitBusinessId,
    bool isLoadMore = false}){
    controller.getCustomerFoodProductByCategoryIdApi(
        categoryIdParams: categoryIdParams,
        visitBusinessId: visitBusinessId,
        isLoadMore: isLoadMore
    );
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomAddToCart(),
      appBar: CommonBackAppBar(
          buildCustomActionWidget: () => FoodCartIconButton(),
      ),
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
      items: widget.foodCategoryData.children ?? [],
      getIcon: (cat) => cat.image ?? '',
      getLabel: (cat) => cat.name ?? '',
      isSelected: (cat) => controller.selectedCategoryId.value == cat.sId,
      onTap: (cat, index) {
        // Print sub-categories in log
        debugPrint("Sub-categories for ${cat.name}: ${cat.children?.map((e) => e.name).toList()}");

        controller.selectedCategoryId.value = cat.sId ?? "";
        controller.subCategoryTabs.assignAll(cat.children ?? []);
        controller.selectedSubCategoryId.value = "all";

        callFoodProductBySubCatAPi(
            categoryIdParams: {ApiKeys.parentId: controller.selectedCategoryId.value},
            visitBusinessId: _visitBusinessId
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
              final String id = (item is String) ? "all" : (item.sId ?? "");
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
                final String itemId = (selectedItem is String) ? "all" : (selectedItem.sId ?? "");

                controller.selectedSubCategoryId.value = itemId;

                var targetIdParams = (itemId == "all")
                    ? {ApiKeys.parentId: controller.selectedCategoryId.value}
                    : {ApiKeys.categoryId: itemId};

                    callFoodProductBySubCatAPi(
                        categoryIdParams: targetIdParams,
                        visitBusinessId: _visitBusinessId
                  );
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
                : controller.categoryCustomerFoodProductDataList.isNotEmpty
                ? ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.categoryCustomerFoodProductDataList.length,
              itemBuilder: (context, index) {
                final product = controller.categoryCustomerFoodProductDataList[index];
                return _buildFoodProductCard(
                  product: product,
                  onShowVariants: (p) => _showVariantSheet(context, p),
                );
              },
            )
                : Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: EmptyStateWidget(
                    message:
                    'No Product found.'
                )
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFoodProductCard({
    required CategoryFoodProductData product,
    required Function(CategoryFoodProductData) onShowVariants,
  }) {
    return InkWell(
      onTap: ()=> onShowVariants(product),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ProductImageWidget(
                    imageUrl: product.images?.firstOrNull,
                    height: 60,
                    width: 60,
                  ),
                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          product.name,
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        ProductDescriptionWidget(
                          description: product.description,
                        ),
                        const SizedBox(height: 8),
                        FoodDietaryAndTagRow(
                          dietaryType: product.dietaryType,
                          cookingMethods: product.cookingMethod,
                        ),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 5),

              // Variants
              CustomText(
                "${product.variants?.length ?? 0} Variants",
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),

              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAddToCart() {
    return Obx(() {
      final bool hasSelection = controller.selectedVariantsMap.isNotEmpty;

      if (!hasSelection) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: PositiveCustomBtn(
            onTap: () => Get.toNamed(RouteHelper.getFoodReviewSelectionScreenRoute()),
            // 3. Use the dynamic count in the title to make the UI interactive
            title: "Review Selection (${controller.totalVariantsCount})",
          ),
        ),
      );
    });
  }


  void _showVariantSheet(
      BuildContext context,
      CategoryFoodProductData product
      ) {
    Get.bottomSheet(
      buildProductVariantBottomSheet(
        product: product,
      ),
      isScrollControlled: true,
    );
  }

  Widget buildProductVariantBottomSheet({
    required CategoryFoodProductData product,
  }) {
    final RxList<FoodVariants> tempSelectedVariants = <FoodVariants>[].obs;

    // Initialize from the new Map structure
    final saved = controller.selectedVariantsMap[product.id]?.selectedVariants ?? [];
    tempSelectedVariants.assignAll(saved);

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Obx(() {
          final String pId = product.id ?? "";
          final liveProduct = controller.categoryCustomerFoodProductDataList
              .firstWhereOrNull((p) => p.id == pId) ?? product;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... Header & Product Info remains same ...
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText("All Variant", fontSize: 18, fontWeight: FontWeight.bold),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImageWidget(imageUrl: liveProduct.images?.firstOrNull, height: 60, width: 60),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(liveProduct.name, fontWeight: FontWeight.w600, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ProductDescriptionWidget(description: liveProduct.description),
                        const SizedBox(height: 8),
                        FoodDietaryAndTagRow(dietaryType: product.dietaryType, cookingMethods: product.cookingMethod),
                      ],
                    ),
                  )
                ],
              ),
              const Divider(),

              // Variant List
              Column(
                children: (liveProduct.variants ?? []).map((item) {
                  return Obx(() {
                    bool isSelected = tempSelectedVariants.any((v) => v.id == item.id);
                    return _buildVariantItemRow(
                      item: item,
                      isSelected: isSelected,
                      productId: pId,
                      onToggle: () {
                        int index = tempSelectedVariants.indexWhere((v) => v.id == item.id);
                        if (index != -1) {
                          tempSelectedVariants.removeAt(index);
                        } else {
                          tempSelectedVariants.add(item);
                        }
                      },
                    );
                  });
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 5. Save Button - UPDATED LOGIC
              PositiveCustomBtn(
                onTap: () {
                  if (tempSelectedVariants.isEmpty) {
                    controller.selectedVariantsMap.remove(pId);
                  } else {
                    // SAVE BOTH PRODUCT AND VARIANTS
                    controller.selectedVariantsMap[pId] = SelectedFoodItem(
                      product: product,
                      selectedVariants: List.from(tempSelectedVariants),
                    );
                  }
                  controller.selectedVariantsMap.refresh();
                  Get.back();
                },
                title: "Add To Cart",
              ),
              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }

// Private helper for the Variant Row to keep the main method cleaner
  Widget _buildVariantItemRow({
    required FoodVariants item,
    required bool isSelected,
    required String productId,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              side: BorderSide(
                color: isSelected ? AppColors.primaryColor : AppColors.greyE5,
                width: 1.5,
              ),
              activeColor: AppColors.primaryColor,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText("${item.variantName} - ${item.quantityLabel}", fontSize: 16, color: AppColors.secondaryTextColor),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CustomText("Selling-₹${item.baseSellingPrice}", fontSize: 14, color: AppColors.secondaryTextColor),
                      const SizedBox(width: 8),
                      Container(height: 15, width: 1.5, color: Colors.grey.shade300),
                      const SizedBox(width: 8),
                      CustomText("₹${item.mrp}", fontSize: 14, color: AppColors.secondaryTextColor, decoration: TextDecoration.lineThrough),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
