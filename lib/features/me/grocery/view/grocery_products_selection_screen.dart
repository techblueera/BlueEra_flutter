import 'dart:developer';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
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

class GroceryProductsSelectionScreen extends StatefulWidget {
  final List<GroceryNestedCategoryModel> arrGroceries;

   GroceryProductsSelectionScreen({
     super.key,
     required this.arrGroceries,
   });

  @override
  State<GroceryProductsSelectionScreen> createState() => _GroceryProductsSelectionScreenState();
}

class _GroceryProductsSelectionScreenState extends State<GroceryProductsSelectionScreen> {
  final controller = getOrPut(() => GroceryController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedGroceryData.value = widget.arrGroceries.first;
      // controller.selectedGroceryData.value = widget.selectedGroceryData;
      controller.fetchBoth();
    });
  }

  void _onScrollListener(){
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200 &&
          !controller.isGroceryCategoryProductsLoadingMore.value &&
             controller.groceryCategoryProductsHasMore) {
      controller.fetchGroceryCategoryProducts(
        isLoadMore: true,
       );
      }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Obx(()=> Scaffold(
      appBar: CommonBackAppBar(
        title: controller.selectedGroceryData.value?.name,
        isShadowShow: false,
        buildCustomActionWidget:()=>
        Obx(()=> controller.selectedGroceries.isEmpty
            ?  Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Icon(Icons.search),
        )
            :  InkWell(
              onTap: ()=> Get.toNamed(RouteHelper.getAddGroceryScreenRoute()),
              child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Stack(
              clipBehavior: Clip.none,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.cartIcon,
                ),
                Positioned(
                  top: -5,
                  right: -5,
                    child: Container(
                      height: SizeConfig.size16,
                      width: SizeConfig.size16,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle
                      ),
                      alignment: Alignment.center,
                      child: CustomText(
                         '${controller.selectedGroceries.length}',
                          color: AppColors.white,
                      ),
                    )
                )
              ]
              ),
            ),
          ),
        )
      ),
      bottomNavigationBar:
      Obx((){
        if(controller.selectedGroceries.isEmpty)
            return SizedBox();
        else
          return Material(
          elevation: 8.0,
          child: Container(
            color: AppColors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size15,
                  vertical: SizeConfig.size15),
              child: SafeArea(
                child: CustomBtn(
                  onTap: () {
                     Get.toNamed(RouteHelper.getAddGroceryScreenRoute());
                  },
                  isValidate: true,
                  radius: SizeConfig.size8,
                  title: AppStrings.next,
                  // isLoading: authController.isAddBusinessUserLoading.value
                ),
              ),
            ),
          ),
        );
      }),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftCategoryList(),
          Expanded(
              child: rightContent()
          ),
        ],
       ),
      ));
  }

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<GroceryNestedCategoryModel>(
      items: widget.arrGroceries,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) =>
      controller.selectedGroceryData.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = widget.arrGroceries[index];
        log('new selection ${controller.selectedGroceryData.value}');

        if (controller.selectedGroceryData.value?.sId == selected.sId) {
          return;
        }

        controller.selectedGroceryData.value = selected;
        controller.selectedHorizontalTabIndex.value = 0;

        /// api call
        controller.fetchBoth();
      },
    );
  }

  Widget rightContent() {
    return Obx(()=> Padding(
      padding: const EdgeInsets.all(8),
      child: controller.isInitialLoading.value
          ? Center(
                child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Max Limit Error
          if (controller.isMaxLimitHit)
            Container(
              width: SizeConfig.screenWidth,
              decoration: BoxDecoration(
                color: AppColors.redBE,
                borderRadius: BorderRadius.circular(10.0)
              ),
              margin: EdgeInsets.only(bottom: SizeConfig.size10),
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size4,
                horizontal: SizeConfig.size10
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.warningOutlineIcon,
                      width: SizeConfig.size20,
                      height: SizeConfig.size20
                    ),
                    SizedBox(width: SizeConfig.size8),
                    CustomText(
                      'You can’t select more than ${controller.maxLimit} products at a time.',
                      color: AppColors.redLite,
                      fontSize: SizeConfig.extraSmall,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
            ),

          // TABS

          // Obx(() {
          //
          //   final List<dynamic> marqueeData = ["All", ...controller.selectedGroceryData.value?.children??[]];
          //
          //   return SizedBox(
          //     height: 28.0,
          //     width: double.infinity,
          //     // 2. Use the new Generic Widget
          //     child: AutoScrollMarquee<dynamic>(
          //       items: marqueeData,
          //       speed: 0.5,
          //       gap: 200.0,
          //       itemBuilder: (context, item, i) {
          //         // 🟢 'item' is passed directly. No need to look it up!
          //
          //         // 3. Logic for display name
          //         String displayName;
          //         if (item is String) {
          //           displayName = item; // "All"
          //         } else {
          //           displayName = item.name ?? ""; // Your Category Model
          //         }
          //
          //         // 4. Selection Logic
          //         // We use 'i' (the actualIndex from the widget) to check selection
          //         bool selected = controller.selectedHorizontalTabIndex.value == i;
          //
          //         return InkWell(
          //           onTap: () {
          //             controller.selectedHorizontalTabIndex.value = i;
          //             controller.fetchGroceryCategoryProducts();
          //           },
          //           child: Container(
          //             margin: const EdgeInsets.symmetric(horizontal: 6),
          //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          //             decoration: BoxDecoration(
          //               color: selected ? AppColors.primaryColor : AppColors.white,
          //               borderRadius: BorderRadius.circular(6),
          //               border: selected
          //                   ? null
          //                   : Border.all(color: AppColors.greyLite, width: 0.5),
          //             ),
          //             child: Center(
          //               child: CustomText(
          //                 displayName,
          //                 color: selected ? AppColors.white : AppColors.secondaryTextColor,
          //                 fontWeight: FontWeight.w400,
          //                 fontSize: 12,
          //               ),
          //             ),
          //           ),
          //         );
          //       },
          //     ),
          //   );
          // }),

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
          }),

          SizedBox(height: 8),

          // GRID
          Expanded(
            child: controller.isGroceryCategoryProductsLoading.value
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
                : controller.arrGroceryCategoryProducts.isNotEmpty
                ? MasonryGridView.count(
              controller: scrollController,
              itemCount: controller.arrGroceryCategoryProducts.length +
                  (controller.isGroceryCategoryProductsLoadingMore.value ? 1 : 0),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              padding: EdgeInsets.only(bottom: SizeConfig.size30),
              itemBuilder: (_, i) {
                if (i == controller.arrGroceryCategoryProducts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                return groceryCard(controller.arrGroceryCategoryProducts[i]);
              },
            )
                : Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: EmptyStateWidget(
                    message:
                    'No ${controller.currentTabName.tr} found.')
            ),
          )

        ],
      ),
    ));
  }

  Widget groceryCard(GroceryProductData groceryProductData) {
    // final bool isSelected = controller.selectedGroceries.contains(groceryProductData);
    final price = controller.getPriceDetails(groceryProductData.variants?[0].pricing);
    // print("Selling Range: ${price.sellingRange}");
    // print("MRP Range: ${price.mrpRange}");
    // print("Discount Range: ${price.discountRange}");

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              padding: EdgeInsets.only(top: 4.0),
              height: SizeConfig.size140,
              width: double.infinity,
              child: (groceryProductData.images?.isNotEmpty ?? false)
                  ? CachedNetworkImage(
                imageUrl: groceryProductData.images!.first.url??'',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  boxFix: BoxFit.cover,
                ),
              )
                  : LocalAssets(
                imagePath: AppIconAssets.place_holder_image,
                boxFix: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 9.0,
                vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${groceryProductData.name}",
                  fontSize: SizeConfig.small,
                  maxLines: 1,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    if (groceryProductData.variants?[0].isVegetarian != null) ...[
                      FoodTypeIndicator(isVegetarian: groceryProductData.variants?[0].isVegetarian!??false),
                      SizedBox(width: SizeConfig.size6),
                    ],
                    Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(width: 0.5, color: AppColors.greyE5)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: CustomText(
                        '${groceryProductData.variants?[0].quantity}',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                PriceRow(
                  sellingPrice: "${price.sellingRange}",
                  mrp: "${price.mrpRange}",
                  discount: "${price.discountRange}",
                ),
                // Column(
                //   children: [
                //     Row(
                //       mainAxisAlignment: MainAxisAlignment.start,
                //       children: [
                //         CustomText(
                //           "${AppStrings.price.tr}: ",
                //           fontSize: 10,
                //           color: AppColors.secondaryTextColor,
                //           fontWeight: FontWeight.w600,
                //         ),
                //         SizedBox(width: SizeConfig.size3),
                //         FittedBox(
                //           fit: BoxFit.scaleDown,
                //           child: CustomText(
                //             "${price.sellingRange}",
                //             fontSize: 10,
                //             color: AppColors.primaryColor,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //       ],
                //     ),
                //     SizedBox(height: 4),
                //     Row(
                //         mainAxisAlignment: MainAxisAlignment.start,
                //         children: [
                //           CustomText(
                //             "${AppStrings.mrp.tr}: ",
                //             fontSize: 10,
                //             color: AppColors.secondaryTextColor,
                //             fontWeight: FontWeight.w600,
                //           ),
                //           SizedBox(width: SizeConfig.size3),
                //           FittedBox(
                //             fit: BoxFit.scaleDown,
                //             child: CustomText(
                //               "${price.mrpRange}",
                //               fontSize: 10,
                //               color: AppColors.grayText,
                //             ),
                //           ),
                //         ],
                //       ),
                //
                //     SizedBox(height: 4),
                //     Row(
                //       mainAxisAlignment: MainAxisAlignment.start,
                //       children: [
                //         CustomText(
                //           "${AppStrings.discount.tr}: ",
                //           fontSize: 10,
                //           color: AppColors.secondaryTextColor,
                //           fontWeight: FontWeight.w600,
                //         ),
                //         SizedBox(width: SizeConfig.size3),
                //         FittedBox(
                //           fit: BoxFit.scaleDown,
                //           child: CustomText(
                //             "${price.discountRange}",
                //             fontSize: 10,
                //             color: AppColors.green00,
                //             fontWeight: FontWeight.w600,
                //           ),
                //         ),
                //       ],
                //     ),
                //     SizedBox(height: SizeConfig.size8),
                //     CustomBtn(
                //       height: SizeConfig.size36,
                //       onTap: () => controller.toggleSelection(groceryProductData),
                //       title: isSelected ? 'Added' : 'Add',
                //       textColor: isSelected ? AppColors.white : AppColors.primaryColor,
                //       bgColor: isSelected ? AppColors.primaryColor : AppColors.white,
                //       radius: 6.0,
                //       borderColor: AppColors.primaryColor,
                //     )
                //   ],
                // ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size4),
        ],
      ),
    );
  }

}
