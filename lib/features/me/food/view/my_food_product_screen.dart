import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';
import 'package:BlueEra/features/me/food/view/widget/food_dietary_and_tag_row.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_des_widget.dart';
import 'package:BlueEra/features/me/food/view/widget/food_product_image_widget.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/food/model/food_category_res_model.dart';
import '../model/food_home_res_model.dart';

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

  void _showVariantSheet(CategoryFoodProductData product) {
    Get.bottomSheet(
      _buildProductVariantWidget(
          product
      ),
      isScrollControlled: true,
    );
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
                    message:
                    'No Product found.'
                )
            ),
          )),
        ],
      ),
    );
  }

  Widget _foodProductCard(CategoryFoodProductData product) {
    return InkWell(
      onTap: ()=> _showVariantSheet(product),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ProductImageWidget(
                    imageUrl: product.images?.firstOrNull,
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

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductVariantWidget(CategoryFoodProductData product) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildProductInfo(product),
          const Divider(),
          _buildVariantList(product),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText("All Variant",
            fontSize: 18, fontWeight: FontWeight.bold),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  Widget _buildProductInfo(CategoryFoodProductData liveProduct) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductImageWidget(
          imageUrl: liveProduct.images?.firstOrNull,
          width: 60,
          height: 60,
        ),

        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                liveProduct.name,
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ProductDescriptionWidget(
                description: liveProduct.description,
              ),
              const SizedBox(height: 8),
              FoodDietaryAndTagRow(
                dietaryType: liveProduct.dietaryType,
                cookingMethods: liveProduct.cookingMethod,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildVariantList(CategoryFoodProductData liveProduct) {
    final displayVariants = liveProduct.variants ?? [];

    return Column(
      children: displayVariants.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            // Adding a subtle shadow for depth
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppColors.greyE5.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: IntrinsicHeight( // Ensures the blue line matches the content height
              child: Row(
                children: [
                  // 1. Blue Vertical Accent Line
                  Container(
                    width: 4,
                    color: AppColors.primaryColor,
                  ),

                  const SizedBox(width: 12),

                  // 2. Variant Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            "${item.variantName} - ${item.quantityLabel}",
                            fontSize: 15,
                            fontWeight: FontWeight.w600, // Semi-bold for title
                            color: AppColors.secondaryTextColor,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Selling Price Chip Look
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: CustomText(
                                  "₹${item.baseSellingPrice}",
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // MRP
                              CustomText(
                                "₹${item.mrp}",
                                fontSize: 12,
                                color: AppColors.secondaryTextColor.withValues(alpha: 0.7),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Padding(
                  //   padding: const EdgeInsets.only(right: 8.0),
                  //   child: Icon(
                  //     Icons.chevron_right,
                  //     color: AppColors.greyE5,
                  //     size: 20,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
