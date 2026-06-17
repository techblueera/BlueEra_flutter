import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/food/controller/food_selfpickup_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/customer_food_self_pickup_cart.dart';
import 'package:BlueEra/features/me/food/view/widget/food_self_pickup_variants_sheet.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
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
  /// Session cart + category-listing state — both live on the self-pickup
  /// controller so this screen only depends on one controller.
  final FoodSelfPickupController controller =
      getOrPut<FoodSelfPickupController>(() => FoodSelfPickupController());

  final ScrollController scrollController = ScrollController();
  String? _visitBusinessId;

  ViewBusinessDetailsController? get _viewBusinessDetailsController =>
      Get.isRegistered<ViewBusinessDetailsController>()
          ? Get.find<ViewBusinessDetailsController>()
          : null;

  @override
  void initState() {
    super.initState();
    _visitBusinessId = widget.visitBusinessId;
    debugPrint("visit business id -- ${widget.visitBusinessId}");
    controller.resetCategoryListingState();
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
      appBar: CommonBackAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              _buildLeftSidebar(),
              _buildRightContent(),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: CustomerFoodSelfPickupCart(controller: controller),
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
                ? Builder(builder: (context) {
              final rows = buildNativeAdRows(
                  controller.categoryCustomerFoodProductDataList.length);
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  if (row.isAd) {
                    return NativeAdSlot(
                      adOrdinal: row.adOrdinal,
                      keyPrefix: 'food_listing_native_ad',
                    );
                  }
                  final product = controller
                      .categoryCustomerFoodProductDataList[row.contentIndex];
                  return _buildFoodProductCard(
                    product: product,
                    onShowVariants: (p) => _showVariantSheet(context, p),
                  );
                },
              );
            })
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
                "${product.variants?.length ?? 0} ${AppStrings.foodVariantsLabel.tr}",
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

  void _showVariantSheet(
      BuildContext context, CategoryFoodProductData product) {
    final bDetails =
        _viewBusinessDetailsController?.visitedBusinessProfileDetails?.data;
    showFoodSelfPickupVariantsSheet(
      context,
      args: FoodSelfPickupSheetArgs.fromCategoryProduct(
        product,
        visitBusinessId: _visitBusinessId ?? bDetails?.id,
        visitBusinessName: bDetails?.businessName,
        visitBusinessLogo: bDetails?.logo,
        visitBusinessAddress: bDetails?.address,
      ),
    );
  }
}
